module "foundry_ptn" {
  source  = "Azure/avm-ptn-aiml-ai-foundry/azurerm"
  version = "0.5.0"

  #configure the base resource
  base_name                  = coalesce(var.name_prefix, "foundry")
  location                   = azurerm_resource_group.this.location
  resource_group_resource_id = azurerm_resource_group.this.id
  #pass through the resource definitions
  ai_foundry                          = local.foundry_ai_foundry
  ai_model_deployments                = var.ai_foundry_definition.ai_model_deployments
  ai_projects                         = var.ai_foundry_definition.ai_projects
  ai_search_definition                = local.foundry_ai_search_definition
  cosmosdb_definition                 = local.foundry_cosmosdb_definition
  create_byor                         = var.ai_foundry_definition.create_byor
  create_private_endpoints            = true
  enable_telemetry                    = var.enable_telemetry
  key_vault_definition                = local.foundry_key_vault_definition
  law_definition                      = var.ai_foundry_definition.law_definition
  private_endpoint_subnet_resource_id = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
  storage_account_definition          = local.foundry_storage_account_definition
}

