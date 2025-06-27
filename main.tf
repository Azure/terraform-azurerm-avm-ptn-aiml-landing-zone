resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
  tags     = var.tags
}

# used to randomize resource names that are globally unique
resource "random_string" "name_suffix" {
  length  = 4
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

module "avm-utl-regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.2"

  recommended_filter = false
}

