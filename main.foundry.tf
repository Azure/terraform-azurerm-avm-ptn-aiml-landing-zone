module "foundry_ptn" {
  source  = "Azure/avm-ptn-aiml-ai-foundry/azurerm"
  version = "0.2.0"
  count   = var.flag_standalone.deploy_build_resources ? 0 : 1

  base_name                                 = coalesce(var.name_prefix, "foundry")
  location                                  = azurerm_resource_group.this.location
  agent_subnet_id                           = module.ai_lz_vnet.subnets["AIFoundrySubnet"].resource_id
  ai_foundry_project_description            = var.ai_foundry_definition.ai_foundry_project_description
  ai_model_deployments                      = var.ai_foundry_definition.ai_model_deployments
  ai_search_resource_id                     = try(var.ai_foundry_definition.ai_foundry_resources.ai_search.existing_resource_id, null)
  cosmos_db_resource_id                     = try(var.ai_foundry_definition.ai_foundry_resources.cosmos_db.existing_resource_id, null)
  create_ai_agent_service                   = var.ai_foundry_definition.create_ai_agent_service
  create_dependent_resources                = try(var.ai_foundry_definition.ai_foundry_resources.create_dependent_resources, true)
  create_private_endpoints                  = true
  create_resource_group                     = false
  enable_telemetry                          = var.enable_telemetry
  lock                                      = var.ai_foundry_definition.lock
  private_dns_zone_resource_id_ai_foundry   = var.flag_platform_landing_zone ? module.private_dns_zones.ai_foundry_zone.resource_id : local.private_dns_zones_existing.ai_foundry_zone.resource_id
  private_dns_zone_resource_id_cosmosdb     = var.flag_platform_landing_zone ? module.private_dns_zones.cosmos_sql_zone.resource_id : local.private_dns_zones_existing.cosmos_sql_zone.resource_id
  private_dns_zone_resource_id_keyvault     = var.flag_platform_landing_zone ? module.private_dns_zones.key_vault_zone.resource_id : local.private_dns_zones_existing.key_vault_zone.resource_id
  private_dns_zone_resource_id_search       = var.flag_platform_landing_zone ? module.private_dns_zones.ai_search_zone.resource_id : local.private_dns_zones_existing.ai_search_zone.resource_id
  private_dns_zone_resource_id_storage_blob = var.flag_platform_landing_zone ? module.private_dns_zones.storage_blob_zone.resource_id : local.private_dns_zones_existing.storage_blob_zone.resource_id
  private_endpoint_subnet_id                = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
  resource_group_id                         = azurerm_resource_group.this.id
  resource_names = {
    ai_foundry      = local.ai_foundry_name
    ai_search       = try(var.ai_foundry_definition.ai_foundry_resources.ai_search.name, null)
    cosmos_db       = try(var.ai_foundry_definition.ai_foundry_resources.cosmos_db.name, null)
    key_vault       = try(var.ai_foundry_definition.ai_foundry_resources.key_vault.name, null)
    storage_account = try(var.ai_foundry_definition.ai_foundry_resources.storage_account.name, null)
  }
  role_assignments            = var.ai_foundry_definition.role_assignments
  storage_account_resource_id = try(var.ai_foundry_definition.ai_foundry_resources.storage_account.existing_resource_id, null)
  tags                        = var.ai_foundry_definition.tags
}

