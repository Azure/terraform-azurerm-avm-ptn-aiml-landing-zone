module "foundry_ptn" {
  source  = "Azure/avm-ptn-aiml-ai-foundry/azurerm"
  version = "0.3.0"

  #configure the base resource
  base_name                  = coalesce(var.name_prefix, "foundry")
  location                   = azurerm_resource_group.this.location
  resource_group_resource_id = azurerm_resource_group.this.id
  #pass through the resource definitions
  ai_foundry                          = var.ai_foundry_definition.ai_foundry
  ai_model_deployments                = var.ai_foundry_definition.ai_model_deployments
  ai_projects                         = var.ai_foundry_definition.ai_projects
  ai_search_definition                = var.ai_foundry_definition.ai_search_definition
  cosmosdb_definition                 = var.ai_foundry_definition.cosmosdb_definition
  create_dependent_resources          = var.ai_foundry_definition.ai_foundry.create_dependent_resources
  create_private_endpoints            = true
  enable_telemetry                    = var.enable_telemetry
  key_vault_definition                = var.ai_foundry_definition.key_vault_definition
  law_definition                      = var.ai_foundry_definition.law_definition
  private_endpoint_subnet_resource_id = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
  storage_account_definition          = var.ai_foundry_definition.storage_account_definition
  tags                                = var.ai_foundry_definition.tags
}

