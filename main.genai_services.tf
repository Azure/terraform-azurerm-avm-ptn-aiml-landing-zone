/*
module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "=0.10.0"

  location            = azurerm_resource_group.this_rg.location
  name                = "${module.naming.key_vault.name_unique}-win-pip"
  resource_group_name = azurerm_resource_group.this_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true

  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
  tags = local.tags

  diagnostic_settings = {
    to_law = {
      name                  = "sendToLogAnalytics"
      workspace_resource_id = module.log_analytics_workspace.resource_id
    }
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
}
*/
