# Terraform cannot mock AzAPI's ephemeral resource schemas yet:
# https://github.com/hashicorp/terraform/issues/38608
# Override both reachable AzAPI resources instead; no Azure operations are run.
provider "azapi" {
  skip_provider_registration = true
  subscription_id            = "00000000-0000-0000-0000-000000000000"
  tenant_id                  = "00000000-0000-0000-0000-000000000003"
  use_cli                    = true
}

override_resource {
  target = azapi_resource.this
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit"
  }
}

override_resource {
  target = azapi_resource.network_security_rule
}

mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

# Mock the module's configured-identity exception (AzAPI issue #981).
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

override_module {
  target = module.nsgs
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/networkSecurityGroups/nsg-unit"
  }
}

override_module {
  target = module.ai_lz_vnet[0]
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit"
    subnets = {
      AppGatewaySubnet = {
        address_prefixes = ["192.168.5.0/24"]
        resource_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/AppGatewaySubnet"
      }
    }
  }
}

variables {
  enable_telemetry           = false
  flag_platform_landing_zone = true
  location                   = "eastus"
  resource_group_name        = "rg-unit"
  vnet_definition            = {}
  apim_definition = {
    deploy          = false
    publisher_email = "unit-test@example.com"
    publisher_name  = "Unit Test"
  }
  app_gateway_definition = {
    deploy                = false
    backend_address_pools = {}
    backend_http_settings = {}
    frontend_ports        = {}
    http_listeners        = {}
    request_routing_rules = {}
  }
}

run "normalizes_nsg_arrays_without_changing_rules" {
  command = apply

  plan_options {
    target = [azapi_resource.network_security_rule]
  }

  variables {
    nsgs_definition = {
      security_rules = {
        null_arrays = {
          name                         = "NullArrays"
          access                       = "Allow"
          direction                    = "Inbound"
          priority                     = 200
          protocol                     = "Tcp"
          source_address_prefix        = "VirtualNetwork"
          source_address_prefixes      = null
          source_port_range            = "*"
          source_port_ranges           = null
          destination_address_prefix   = "*"
          destination_address_prefixes = null
          destination_port_range       = "443"
          destination_port_ranges      = null
        }
        empty_arrays = {
          name                         = "EmptyArrays"
          access                       = "Allow"
          direction                    = "Inbound"
          priority                     = 210
          protocol                     = "Tcp"
          source_address_prefix        = "VirtualNetwork"
          source_address_prefixes      = []
          source_port_range            = "*"
          source_port_ranges           = []
          destination_address_prefix   = "*"
          destination_address_prefixes = []
          destination_port_range       = "443"
          destination_port_ranges      = []
        }
        populated_arrays = {
          name                         = "PopulatedArrays"
          access                       = "Deny"
          direction                    = "Outbound"
          priority                     = 220
          protocol                     = "Tcp"
          source_address_prefixes      = ["10.0.0.0/24", "10.0.1.0/24"]
          source_port_ranges           = ["1000-2000", "3000-4000"]
          destination_address_prefixes = ["192.168.0.0/24", "192.168.1.0/24"]
          destination_port_ranges      = ["80", "443"]
        }
      }
    }
  }

  assert {
    condition = alltrue([
      for rule in azapi_resource.network_security_rule :
      rule.body.properties.sourceAddressPrefixes != null &&
      rule.body.properties.destinationAddressPrefixes != null &&
      rule.body.properties.sourcePortRanges != null &&
      rule.body.properties.destinationPortRanges != null
    ])
    error_message = "Missing and null NSG address/port collections must be arrays, matching Azure's empty-array responses."
  }

  assert {
    condition = alltrue([
      for key in ["apim_rule01", "null_arrays", "empty_arrays"] :
      try(length(azapi_resource.network_security_rule[key].body.properties.sourceAddressPrefixes), -1) == 0 &&
      try(length(azapi_resource.network_security_rule[key].body.properties.destinationAddressPrefixes), -1) == 0 &&
      try(length(azapi_resource.network_security_rule[key].body.properties.sourcePortRanges), -1) == 0 &&
      try(length(azapi_resource.network_security_rule[key].body.properties.destinationPortRanges), -1) == 0
    ])
    error_message = "Default scalar rules, explicit nulls, and explicit empty sets must serialize unused collections as []."
  }

  assert {
    condition = (
      azapi_resource.network_security_rule["null_arrays"].body.properties.sourceAddressPrefix == "VirtualNetwork" &&
      azapi_resource.network_security_rule["null_arrays"].body.properties.sourcePortRange == "*" &&
      azapi_resource.network_security_rule["null_arrays"].body.properties.destinationAddressPrefix == "*" &&
      azapi_resource.network_security_rule["null_arrays"].body.properties.destinationPortRange == "443"
    )
    error_message = "Normalizing unused collections must preserve the singular address and port fields."
  }

  assert {
    condition = (
      toset(azapi_resource.network_security_rule["populated_arrays"].body.properties.sourceAddressPrefixes) == toset(["10.0.0.0/24", "10.0.1.0/24"]) &&
      toset(azapi_resource.network_security_rule["populated_arrays"].body.properties.destinationAddressPrefixes) == toset(["192.168.0.0/24", "192.168.1.0/24"]) &&
      toset(azapi_resource.network_security_rule["populated_arrays"].body.properties.sourcePortRanges) == toset(["1000-2000", "3000-4000"]) &&
      toset(azapi_resource.network_security_rule["populated_arrays"].body.properties.destinationPortRanges) == toset(["80", "443"]) &&
      azapi_resource.network_security_rule["populated_arrays"].body.properties.access == "Deny" &&
      azapi_resource.network_security_rule["populated_arrays"].body.properties.priority == 220
    )
    error_message = "Populated collection values and rule semantics must remain unchanged."
  }
}
