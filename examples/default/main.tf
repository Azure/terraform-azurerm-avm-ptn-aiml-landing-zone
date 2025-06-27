terraform {
  required_version = "~> 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}


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
  resource_group_name = "ai-lz-rg-test"
  vnet_definition = {
    name                  = "ai-lz-vnet"
    address_space         = "10.100.0.0/23"
    dns_servers           = ["10.0.2.4"] #test private dns resolver
    peer_vnet_resource_id = ""
  }
  bastion_definition = {
    zones = [] #Zonal configurations are preview and not supported in westus3
  }
  dns_zones_network_links = { #temporary link to the test hub for testing purposes
    hub = {
      vnetlinkname = "ai-lz-hub"
      vnetid       = "resourceId"
    }
  }
  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = false
  genai_container_registry_definition = {
    private_dns_zone_resource_id = ""
  }
  genai_cosmosdb_definition = {
    private_dns_zone_resource_id = ""
  }
  genai_key_vault_definition = {
    private_dns_zone_resource_id = ""
  }
  genai_storage_account_definition = {

  }
  ks_ai_search_definition = {
    private_dns_zone_resource_id = ""
  }
}

