moved {
  from = azurerm_role_assignment.deployment_user_kv_admin[0]
  to   = module.avm_res_keyvault_vault[0].azurerm_role_assignment.this["deployment_user_kv_admin"]
}
