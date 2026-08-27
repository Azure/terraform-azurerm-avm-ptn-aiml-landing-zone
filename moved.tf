moved {
  from = azurerm_resource_group.this
  to   = azapi_resource.this
}

moved {
  from = azurerm_network_security_rule.this
  to   = azapi_resource.network_security_rule
}

moved {
  from = azurerm_virtual_hub_connection.this
  to   = azapi_resource.virtual_hub_connection
}

moved {
  from = azurerm_role_assignment.deployment_user_kv_admin
  to   = azapi_resource.deployment_user_kv_admin
}
