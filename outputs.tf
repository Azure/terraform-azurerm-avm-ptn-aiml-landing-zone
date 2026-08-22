output "apim" {
  description = "Details of the deployed APIM instance."
  value       = try(module.apim[0], null)
}

output "data_ai_services" {
  description = "Non-secret resource and runtime-discovery values for the Data & AI services parity contract."
  value = {
    key_vault_resource_id       = try(module.avm_res_keyvault_vault[0].resource_id, null)
    cosmos_db_resource_id       = try(module.cosmosdb[0].resource_id, null)
    cosmos_sql_databases        = var.genai_cosmosdb_definition.deploy ? { for key, database in var.genai_cosmosdb_definition.sql_databases : key => { name = database.name, containers = { for container_key, container in database.containers : container_key => { name = container.name, partition_key_paths = container.partition_key_paths } } } } : {}
    storage_account_resource_id = try(module.storage_account[0].resource_id, null)
    storage_containers          = var.genai_storage_account_definition.deploy ? { for key, container in var.genai_storage_account_definition.containers : key => container.name } : {}
    application_insights_id     = local.app_insights_resource_id
    log_analytics_workspace_id  = local.log_analytics_workspace_id
    search_service_resource_id  = try(module.search_service[0].resource_id, null)
    bing_grounding_resource_id  = try(azapi_resource.bing_grounding[0].id, null)
    speech_service_resource_id  = try(module.speech_service[0].resource_id, null)
    speech_service_name         = try(module.speech_service[0].name, null)
    speech_service_location     = var.ks_speech_service_definition.deploy ? local.ks_speech_service_location : null
    speech_service_endpoint     = try(module.speech_service[0].endpoint, null)
    speech_service_principal_id = try(module.speech_service[0].system_assigned_mi_principal_id, null)
  }
}

#TODO: determine what a good set of outpus should be and update.
output "resource_id" {
  description = "Future resource ID output for the LZA."
  value       = "tbd"
}
