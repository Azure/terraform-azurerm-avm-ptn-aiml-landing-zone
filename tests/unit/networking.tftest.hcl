mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}
mock_provider "tls" {}

override_module {
  target = module.foundry_ptn
  outputs = {
    ai_foundry_name = "foundry-unit-test"
  }
}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000003"
    }
  }
}

variables {
  apim_definition = {
    publisher_email = "unit-test@example.com"
    publisher_name  = "Unit Test"
  }
  app_gateway_definition = {
    backend_address_pools = {
      unit = {
        name = "unit"
      }
    }
    backend_http_settings = {
      unit = {
        name     = "unit"
        port     = 80
        protocol = "Http"
      }
    }
    frontend_ports = {
      unit = {
        name = "unit"
        port = 80
      }
    }
    http_listeners = {
      unit = {
        name               = "unit"
        frontend_port_name = "unit"
      }
    }
    request_routing_rules = {
      unit = {
        backend_address_pool_name  = "unit"
        backend_http_settings_name = "unit"
        http_listener_name         = "unit"
        name                       = "unit"
        priority                   = 100
        rule_type                  = "Basic"
      }
    }
  }
  container_app_environment_definition = {
    deploy = false
  }
  enable_telemetry    = false
  location            = "eastus"
  resource_group_name = "rg-unit-test"
  vnet_definition     = {}
}

run "granular_existing_zone_is_unified_and_linked_in_standalone" {
  command = plan

  variables {
    flag_platform_landing_zone = false
    private_dns_zones = {
      azure_policy_pe_zone_linking_enabled = false
      existing_zone_resource_ids = {
        key_vault_zone = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      }
    }
  }

  assert {
    condition     = local.private_dns_zone_resource_ids.key_vault_zone == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    error_message = "The unified zone map must preserve a granular existing Private DNS zone ID."
  }

  assert {
    condition     = !contains(keys(local.private_dns_zones), "key_vault_zone")
    error_message = "A granular existing Private DNS zone must not also be created."
  }

  assert {
    condition     = contains(keys(local.private_dns_zones_existing_vnet_links), "key_vault_zone-alz_vnet_link")
    error_message = "Standalone mode must link a granular existing Private DNS zone to the managed or BYO virtual network."
  }
}

run "platform_zone_links_remain_platform_owned" {
  command = plan

  variables {
    flag_platform_landing_zone = true
    private_dns_zones = {
      existing_zones_resource_group_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns"
    }
  }

  assert {
    condition     = length(local.private_dns_zones_existing_vnet_links) == 0
    error_message = "Platform landing-zone mode must not create duplicate Private DNS virtual network links."
  }

  assert {
    condition     = local.private_dns_zone_resource_ids.ai_search_zone == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.search.windows.net"
    error_message = "Platform landing-zone mode must derive canonical zone IDs from the supplied resource group."
  }
}

run "existing_nat_gateway_is_reused" {
  command = plan

  variables {
    flag_platform_landing_zone = false
    nat_gateway_definition = {
      deploy      = true
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/natGateways/nat-existing"
      subnet_keys = ["JumpboxSubnet"]
    }
  }

  assert {
    condition     = output.nat_gateway_resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/natGateways/nat-existing"
    error_message = "An existing NAT Gateway ID must take precedence over managed NAT Gateway creation."
  }

  assert {
    condition     = length(module.nat_gateway) == 0
    error_message = "The focused NAT Gateway submodule must not run when an existing NAT Gateway is supplied."
  }
}

run "managed_nat_gateway_association_shape_is_plan_known" {
  command = plan

  variables {
    flag_platform_landing_zone = false
    nat_gateway_definition = {
      deploy      = true
      subnet_keys = ["JumpboxSubnet"]
    }
  }

  assert {
    condition     = length(module.nat_gateway) == 1
    error_message = "Managed NAT Gateway configuration must create the focused AzAPI submodule."
  }

  assert {
    condition     = contains(keys(local.deployed_subnets.JumpboxSubnet), "nat_gateway")
    error_message = "Managed NAT Gateway association must remain plan-known even when the managed resource ID is not known until apply."
  }

  assert {
    condition     = length(var.nat_gateway_definition.zones) == 0
    error_message = "Managed Standard NAT Gateway configuration must default to no explicit availability zone."
  }
}

run "rejects_multiple_standard_nat_gateway_zones" {
  command = plan

  variables {
    flag_platform_landing_zone = false
    nat_gateway_definition = {
      deploy = true
      zones  = ["1", "2"]
    }
  }

  expect_failures = [var.nat_gateway_definition]
}

run "rejects_unknown_private_dns_zone_key" {
  command = plan

  variables {
    flag_platform_landing_zone = false
    private_dns_zones = {
      existing_zone_resource_ids = {
        unsupported_zone = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.example.azure.net"
      }
    }
  }

  expect_failures = [var.private_dns_zones]
}

run "rejects_platform_mode_without_existing_zones" {
  command = plan

  variables {
    flag_platform_landing_zone = true
  }

  expect_failures = [var.private_dns_zones]
}

run "rejects_invalid_nat_gateway_id" {
  command = plan

  variables {
    flag_platform_landing_zone = false
    nat_gateway_definition = {
      resource_id = "/not/a/nat/gateway"
    }
  }

  expect_failures = [var.nat_gateway_definition]
}
