resource "azapi_resource" "application_platform_container_app_identity" {
  for_each = var.application_platform.container_apps

  location               = azurerm_resource_group.this.location
  name                   = "${local.application_platform_container_app_names[each.key]}-identity"
  parent_id              = azurerm_resource_group.this.id
  type                   = var.resource_types.managedidentity_user_assigned_identities
  body                   = {}
  create_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.managedidentity_user_assigned_identities) > 0 ? var.ignore_body_changes.managedidentity_user_assigned_identities : null
  read_headers           = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs  = []
  response_export_values = ["properties.clientId", "properties.principalId"]
  retry                  = var.retry
  tags                   = merge(local.tags, var.application_platform.deployment_tags)
  update_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "application_platform_acr_pull" {
  for_each = {
    for key, app in var.application_platform.container_apps : key => app
    if app.use_private_registry && var.genai_container_registry_definition.deploy
  }

  name      = uuidv5("url", "${module.containerregistry[0].resource_id}|AcrPull|${azapi_resource.application_platform_container_app_identity[each.key].output.properties.principalId}")
  parent_id = module.containerregistry[0].resource_id
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = {
      principalId      = azapi_resource.application_platform_container_app_identity[each.key].output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "${local.application_platform_subscription_scope}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d"
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  read_headers           = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs  = ["properties.principalId", "properties.roleDefinitionId"]
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = var.genai_container_registry_definition.deploy
      error_message = "Private-registry container apps require genai_container_registry_definition.deploy to be true."
    }
  }
}

resource "azapi_resource" "application_platform_app_config_data_reader" {
  for_each = var.application_platform.app_runtime_configuration_mode == "appConfig" && var.genai_app_configuration_definition.deploy ? var.application_platform.container_apps : {}

  name      = uuidv5("url", "${module.app_configuration[0].resource_id}|AppConfigurationDataReader|${azapi_resource.application_platform_container_app_identity[each.key].output.properties.principalId}")
  parent_id = module.app_configuration[0].resource_id
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = {
      principalId      = azapi_resource.application_platform_container_app_identity[each.key].output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "${local.application_platform_subscription_scope}/providers/Microsoft.Authorization/roleDefinitions/516239f1-63e1-4d78-a4de-a74fb236a071"
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  read_headers           = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs  = ["properties.principalId", "properties.roleDefinitionId"]
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = var.genai_app_configuration_definition.deploy
      error_message = "appConfig runtime mode requires genai_app_configuration_definition.deploy to be true."
    }
  }
}

resource "azapi_resource" "application_platform_app_config_data_owner" {
  count = var.application_platform.populate_app_configuration && var.genai_app_configuration_definition.deploy ? 1 : 0

  name      = uuidv5("url", "${module.app_configuration[0].resource_id}|AppConfigurationDataOwner|${data.azurerm_client_config.current.object_id}")
  parent_id = module.app_configuration[0].resource_id
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = {
      principalId      = data.azurerm_client_config.current.object_id
      roleDefinitionId = "${local.application_platform_subscription_scope}/providers/Microsoft.Authorization/roleDefinitions/5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b"
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  read_headers           = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs  = ["properties.principalId", "properties.roleDefinitionId"]
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "application_platform_key_vault_secrets_user" {
  for_each = {
    for key, app in var.application_platform.container_apps : key => app
    if app.grant_key_vault_secrets_user && var.genai_key_vault_definition.deploy
  }

  name      = uuidv5("url", "${module.avm_res_keyvault_vault[0].resource_id}|KeyVaultSecretsUser|${azapi_resource.application_platform_container_app_identity[each.key].output.properties.principalId}")
  parent_id = module.avm_res_keyvault_vault[0].resource_id
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = {
      principalId      = azapi_resource.application_platform_container_app_identity[each.key].output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "${local.application_platform_subscription_scope}/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6"
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  read_headers           = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs  = ["properties.principalId", "properties.roleDefinitionId"]
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = var.genai_key_vault_definition.deploy
      error_message = "Key Vault access for container apps requires genai_key_vault_definition.deploy to be true."
    }
  }
}

resource "azapi_resource" "application_platform_container_app" {
  for_each = var.container_app_environment_definition.deploy ? var.application_platform.container_apps : {}

  location  = azurerm_resource_group.this.location
  name      = local.application_platform_container_app_names[each.key]
  parent_id = azurerm_resource_group.this.id
  type      = var.resource_types.app_container_apps
  body = {
    properties = {
      managedEnvironmentId = module.container_apps_managed_environment[0].resource_id
      configuration = {
        activeRevisionsMode = "Single"
        dapr = each.value.dapr == null ? null : {
          enabled     = each.value.dapr.enabled
          appId       = coalesce(each.value.dapr.app_id, each.key)
          appPort     = each.value.dapr.app_port
          appProtocol = each.value.dapr.app_protocol
        }
        ingress = {
          external   = each.value.external_ingress_enabled
          targetPort = each.value.target_port
          transport  = each.value.transport
        }
        registries = each.value.use_private_registry ? [{
          identity = azapi_resource.application_platform_container_app_identity[each.key].id
          server   = local.application_platform_container_registry_endpoint
        }] : null
      }
      template = {
        containers = [{
          name  = each.key
          image = each.value.image
          env = concat(
            [{
              name  = "AZURE_CLIENT_ID"
              value = azapi_resource.application_platform_container_app_identity[each.key].output.properties.clientId
            }],
            [
              for name, value in merge(
                var.application_platform.app_runtime_configuration_mode == "containerEnv" ? local.application_platform_runtime_settings :
                var.application_platform.app_runtime_configuration_mode == "appConfig" ? { APP_CONFIG_ENDPOINT = local.application_platform_app_config_endpoint != null ? local.application_platform_app_config_endpoint : "" } : {},
                each.value.env
                ) : {
                name  = name
                value = value
              }
            ]
          )
          resources = {
            cpu    = each.value.cpu
            memory = each.value.memory
          }
        }]
        scale = {
          minReplicas = each.value.min_replicas
          maxReplicas = each.value.max_replicas
        }
      }
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.app_container_apps) > 0 ? var.ignore_body_changes.app_container_apps : null
  read_headers           = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs  = []
  response_export_values = ["properties.configuration.ingress.fqdn", "properties.provisioningState"]
  retry                  = var.retry
  tags                   = merge(local.tags, var.application_platform.deployment_tags)
  update_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  identity {
    type         = "UserAssigned"
    identity_ids = [azapi_resource.application_platform_container_app_identity[each.key].id]
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = var.container_app_environment_definition.deploy
      error_message = "application_platform.container_apps requires container_app_environment_definition.deploy to be true."
    }
  }
  depends_on = [
    azapi_resource.application_platform_acr_pull,
    azapi_resource.application_platform_app_config_data_reader,
    azapi_resource.application_platform_key_vault_secrets_user,
  ]
}

resource "azapi_resource" "application_platform_app_configuration_key_value" {
  for_each = var.application_platform.populate_app_configuration && var.genai_app_configuration_definition.deploy ? local.application_platform_app_config_settings : {}

  name      = format("%s$%s", each.key, each.value.label)
  parent_id = module.app_configuration[0].resource_id
  type      = var.resource_types.appconfiguration_configuration_stores_key_values
  body = {
    properties = {
      value       = each.value.value
      contentType = each.value.content_type
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.appconfiguration_configuration_stores_key_values) > 0 ? var.ignore_body_changes.appconfiguration_configuration_stores_key_values : null
  read_headers           = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs  = []
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [azapi_resource.application_platform_app_config_data_owner]
}

resource "azapi_resource" "application_platform_acr_task_agent_pool" {
  count = var.application_platform.acr_task_agent_pool.enabled && var.genai_container_registry_definition.deploy && var.genai_container_registry_definition.sku == "Premium" ? 1 : 0

  location  = azurerm_resource_group.this.location
  name      = var.application_platform.acr_task_agent_pool.name
  parent_id = module.containerregistry[0].resource_id
  type      = var.resource_types.containerregistry_registries_agent_pools
  body = {
    properties = {
      count                          = var.application_platform.acr_task_agent_pool.count
      tier                           = var.application_platform.acr_task_agent_pool.tier
      virtualNetworkSubnetResourceId = local.subnet_ids["DevOpsBuildSubnet"]
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.containerregistry_registries_agent_pools) > 0 ? var.ignore_body_changes.containerregistry_registries_agent_pools : null
  read_headers           = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  replace_triggers_refs  = []
  response_export_values = ["properties.provisioningState"]
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = var.genai_container_registry_definition.deploy && var.genai_container_registry_definition.sku == "Premium"
      error_message = "The private ACR Task agent pool requires a deployed Premium Container Registry."
    }
  }
  depends_on = [module.firewall_network_rule_collection_group]
}
