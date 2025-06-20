
module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "=0.10.0"

  location                        = azurerm_resource_group.this.location
  name                            = local.genai_key_vault_name
  resource_group_name             = azurerm_resource_group.this.name
  tenant_id                       = var.genai_key_vault_definition.tenant_id != null ? var.genai_key_vault_definition.tenant_id : data.azurerm_client_config.current.tenant_id
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  public_network_access_enabled   = false

  network_acls = { #TODO check to see if we need to support custom network ACLs
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  role_assignments = local.genai_key_vault_role_assignments
  tags             = var.genai_key_vault_definition.tags

  diagnostic_settings = {
    to_law = {
      name                  = "sendToLogAnalytics"
      workspace_resource_id = module.log_analytics_workspace.resource_id
    }
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }

  wait_for_rbac_before_key_operations = {
    create = "60s"
  }

  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = [module.private_dns_zones.key_vault_zone.resource_id]
      subnet_resource_id            = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
    }
  }
}

