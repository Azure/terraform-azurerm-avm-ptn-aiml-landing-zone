# resource "azurerm_resource_group" "this" {
#   location = var.location
#   name     = var.resource_group_name
#   tags     = var.tags
# }

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "standalone"
    ManagedBy   = "Terraform"
    SecurityControl = "Ignore"
  }
}

# used to randomize resource names that are globally unique
resource "random_string" "name_suffix" {
  length  = 4
  special = false
  upper   = false
}

# data "azurerm_client_config" "current" {}

module "avm_utl_regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.2"
}


