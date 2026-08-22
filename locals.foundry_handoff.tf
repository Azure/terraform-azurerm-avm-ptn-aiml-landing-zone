locals {
  foundry_account_endpoint         = "https://${module.foundry_ptn.ai_foundry_name}.cognitiveservices.azure.com/"
  foundry_openai_endpoint          = "https://${module.foundry_ptn.ai_foundry_name}.openai.azure.com/"
  foundry_hosted_agent_enabled     = var.hosted_agent_definition.prepare || var.hosted_agent_definition.deploy
  foundry_hosted_agent_project_key = var.hosted_agent_definition.project_key != null ? var.hosted_agent_definition.project_key : try(keys(var.ai_foundry_definition.ai_projects)[0], null)
  foundry_project_endpoints = {
    for key, name in module.foundry_ptn.ai_foundry_project_name :
    key => "https://${module.foundry_ptn.ai_foundry_name}.services.ai.azure.com/api/projects/${name}"
  }
  foundry_project_dependencies = {
    for key, project in var.ai_foundry_definition.ai_projects : key => {
      ai_search_resource_id = try(project.ai_search_connection.existing_resource_id, null) != null ? project.ai_search_connection.existing_resource_id : try(module.foundry_ptn.ai_search_id[project.ai_search_connection.new_resource_map_key], null)
      cosmos_db_resource_id = try(project.cosmos_db_connection.existing_resource_id, null) != null ? project.cosmos_db_connection.existing_resource_id : try(module.foundry_ptn.cosmos_db_id[project.cosmos_db_connection.new_resource_map_key], null)
      key_vault_resource_id = try(project.key_vault_connection.existing_resource_id, null) != null ? project.key_vault_connection.existing_resource_id : try(module.foundry_ptn.key_vault_id[project.key_vault_connection.new_resource_map_key], null)
      storage_resource_id   = try(project.storage_account_connection.existing_resource_id, null) != null ? project.storage_account_connection.existing_resource_id : try(module.foundry_ptn.storage_account_id[project.storage_account_connection.new_resource_map_key], null)
    }
  }
  hosted_agent_container_registry_resource_id = !local.foundry_hosted_agent_enabled ? null : (
    var.genai_container_registry_definition.deploy ?
    try(module.containerregistry[0].resource_id, null) :
    var.hosted_agent_definition.container_registry.existing_resource_id
  )
  hosted_agent_container_registry_endpoint = !local.foundry_hosted_agent_enabled ? null : (
    var.genai_container_registry_definition.deploy ?
    try(module.containerregistry[0].resource.login_server, null) :
    var.hosted_agent_definition.container_registry.existing_endpoint
  )
  hosted_agent_image_reference = var.hosted_agent_definition.deploy && local.hosted_agent_container_registry_endpoint != null ? "${local.hosted_agent_container_registry_endpoint}/${var.hosted_agent_definition.agent.image}@${var.hosted_agent_definition.agent.version}" : null
}
