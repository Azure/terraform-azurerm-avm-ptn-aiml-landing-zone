resource "azapi_resource" "hosted_agent_registry_pull" {
  count = local.foundry_hosted_agent_enabled ? 1 : 0

  name      = uuidv5("url", "${lower(local.hosted_agent_container_registry_resource_id)}${lower(local.hosted_agent_project_principal_id)}${lower(local.hosted_agent_registry_pull_role_definition_id)}")
  parent_id = local.hosted_agent_container_registry_resource_id
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = {
      description      = "Allow the Microsoft Foundry project managed identity to pull hosted-agent images."
      principalId      = local.hosted_agent_project_principal_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = local.hosted_agent_registry_pull_role_definition_id
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = ["id", "name", "properties.principalId", "properties.principalType", "properties.roleDefinitionId", "properties.scope"]
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [module.containerregistry, module.foundry_ptn]
}

resource "azapi_resource" "hosted_agent_project_manager" {
  count = local.foundry_hosted_agent_enabled ? 1 : 0

  name      = uuidv5("url", "${lower(local.hosted_agent_project_resource_id)}${lower(data.azurerm_client_config.current.object_id)}${lower(local.azure_ai_project_manager_role_definition_id)}")
  parent_id = local.hosted_agent_project_resource_id
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = {
      description      = "Allow the deployment principal to manage downstream Microsoft Foundry hosted-agent resources."
      principalId      = data.azurerm_client_config.current.object_id
      roleDefinitionId = local.azure_ai_project_manager_role_definition_id
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = ["id", "name", "properties.principalId", "properties.principalType", "properties.roleDefinitionId", "properties.scope"]
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [module.foundry_ptn]
}
