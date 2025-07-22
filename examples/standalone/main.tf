## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

module "test" {
  source = "../../"

  location            = "westus3"
  resource_group_name = "ai-lz-rg-standalone"
  vnet_definition = {
    name          = "ai-lz-vnet-standalone"
    address_space = "10.100.0.0/23"
  }
  app_gateway_definition = {
    backend_address_pools = {
      example_pool = {
        name = "example-backend-pool"
      }
    }

    backend_http_settings = {
      example_http_settings = {
        name     = "example-http-settings"
        port     = 80
        protocol = "Http"
      }
    }

    frontend_ports = {
      example_frontend_port = {
        name = "example-frontend-port"
        port = 80
      }
    }

    http_listeners = {
      example_listener = {
        name               = "example-listener"
        frontend_port_name = "example-frontend-port"
      }
    }

    request_routing_rules = {
      example_rule = {
        name                       = "example-rule"
        rule_type                  = "Basic"
        http_listener_name         = "example-listener"
        backend_address_pool_name  = "example-backend-pool"
        backend_http_settings_name = "example-http-settings"
        priority                   = 100
      }
    }
  }
  bastion_definition = {
    zones = [] #Zonal configurations are preview and not supported in westus3
  }
  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = true
  flag_standalone = {
    deploy_build_resources = true
  }
  genai_container_registry_definition = {
  }
  genai_cosmosdb_definition = {
  }
  genai_key_vault_definition = {
  }
  genai_storage_account_definition = {
  }
  ks_ai_search_definition = {
  }
}

