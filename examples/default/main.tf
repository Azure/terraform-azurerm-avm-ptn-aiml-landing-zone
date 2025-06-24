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

  location            = "westus2"
  resource_group_name = "ai-lz-rg"
  vnet_definition = {
    name          = "ai-lz-vnet-test"
    address_space = "10.100.0.0/23"
  }
  bastion_definition = {
    zones = [] #Zonal configurations are preview and not supported in westus3
  }
  #law_definition = {
  #  resource_id = "/subscriptions/19fbc0d1-6eee-4268-a84a-3f06e7a69fca/resourceGroups/sample_ai_resources/providers/Microsoft.OperationalInsights/workspaces/test-ai-law"
  #}
  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = true
}

