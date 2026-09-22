moved {
  from = azurerm_resource_group.this
  to   = azapi_resource.this
}

moved {
  from = azurerm_bastion_host.bastion
  to   = azapi_resource.bastion
}
