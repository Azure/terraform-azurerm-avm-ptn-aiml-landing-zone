module "foundry_ptn" {
  source  = "Azure/avm-ptn-aiml-ai-foundry/azurerm"
  version = "0.8.0"

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
  private_endpoint_subnet_resource_id = local.subnet_ids["PrivateEndpointSubnet"]
  storage_account_definition          = local.foundry_storage_account_definition
  tags                                = var.ai_foundry_definition.tags != null ? var.ai_foundry_definition.tags : var.tags

  depends_on = [azapi_resource_action.purge_ai_foundry]
}

resource "azapi_resource_action" "purge_ai_foundry" {
  count = var.ai_foundry_definition.purge_on_destroy ? 1 : 0

  method      = "DELETE"
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.CognitiveServices/locations/${azurerm_resource_group.this.location}/resourceGroups/${azurerm_resource_group.this.name}/deletedAccounts/${local.ai_foundry_name}"
  type        = "Microsoft.Resources/resourceGroups/deletedAccounts@2021-04-30"
  when        = "destroy"

  depends_on = [time_sleep.purge_ai_foundry_cooldown]
}

resource "time_sleep" "purge_ai_foundry_cooldown" {
  count = var.ai_foundry_definition.purge_on_destroy ? 1 : 0

  destroy_duration = "900s" # 10m

  depends_on = [module.ai_lz_vnet, module.byo_subnets]
}
