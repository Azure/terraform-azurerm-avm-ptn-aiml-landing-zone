resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
  tags     = var.tags
}
