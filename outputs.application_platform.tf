output "application_platform" {
  description = "Application Platform deployment and runtime handoff values. These outputs are evidence of configured intent only and do not claim scenario parity."

  precondition {
    condition     = length(var.application_platform.container_apps) == 0 || var.container_app_environment_definition.deploy
    error_message = "application_platform.container_apps requires container_app_environment_definition.deploy to be true."
  }
  precondition {
    condition     = !anytrue([for app in values(var.application_platform.container_apps) : app.use_private_registry]) || var.genai_container_registry_definition.deploy
    error_message = "Private-registry container apps require genai_container_registry_definition.deploy to be true."
  }
  precondition {
    condition     = var.application_platform.app_runtime_configuration_mode != "appConfig" || length(var.application_platform.container_apps) == 0 || var.genai_app_configuration_definition.deploy
    error_message = "appConfig runtime mode requires genai_app_configuration_definition.deploy to be true when container apps are configured."
  }
  precondition {
    condition     = !anytrue([for app in values(var.application_platform.container_apps) : app.grant_key_vault_secrets_user]) || var.genai_key_vault_definition.deploy
    error_message = "Key Vault access for container apps requires genai_key_vault_definition.deploy to be true."
  }
  precondition {
    condition     = !var.application_platform.populate_app_configuration || var.genai_app_configuration_definition.deploy
    error_message = "application_platform.populate_app_configuration requires genai_app_configuration_definition.deploy to be true."
  }
  precondition {
    condition     = !var.application_platform.acr_task_agent_pool.enabled || (var.genai_container_registry_definition.deploy && var.genai_container_registry_definition.sku == "Premium")
    error_message = "The private ACR Task agent pool requires a deployed Premium Container Registry."
  }
  value = {
    APP_CONFIG_ENDPOINT                  = local.application_platform_app_config_endpoint
    APP_RUNTIME_CONFIGURATION_MODE       = var.application_platform.app_runtime_configuration_mode
    ACR_TASK_AGENT_POOL                  = try(azapi_resource.application_platform_acr_task_agent_pool[0].name, null)
    AZURE_CONTAINER_REGISTRY_ENDPOINT    = local.application_platform_container_registry_endpoint
    AZURE_CONTAINER_REGISTRY_RESOURCE_ID = try(module.containerregistry[0].resource_id, null)
    AZURE_RESOURCE_GROUP                 = azurerm_resource_group.this.name
    COSMOS_LOCATION                      = local.application_platform_runtime_settings.COSMOS_LOCATION
    CONTAINER_APP_INTERNAL_FQDN          = { for key, app in azapi_resource.application_platform_container_app : key => try(app.output.properties.configuration.ingress.fqdn, null) }
    DEPLOY_APP_CONFIG                    = var.genai_app_configuration_definition.deploy
    DEPLOY_CONTAINER_APPS                = length(var.application_platform.container_apps) > 0
    DEPLOY_CONTAINER_ENV                 = var.container_app_environment_definition.deploy
    DEPLOY_CONTAINER_REGISTRY            = var.genai_container_registry_definition.deploy
    DEPLOY_SOFTWARE                      = var.application_platform.deploy_software
    DEPLOYMENT_MODE                      = local.application_platform_deployment_mode
    ENVIRONMENT_NAME                     = local.application_platform_environment_name
    FOUNDRY_IQ_KNOWLEDGE_SOURCE_KIND     = local.application_platform_foundry_iq.FOUNDRY_IQ_KNOWLEDGE_SOURCE_KIND
    FOUNDRY_IQ_KNOWLEDGE_SOURCE_NAME     = local.application_platform_foundry_iq.FOUNDRY_IQ_KNOWLEDGE_SOURCE_NAME
    FOUNDRY_IQ_PATTERN                   = local.application_platform_foundry_iq.FOUNDRY_IQ_PATTERN
    KNOWLEDGE_BASE_CONNECTION_ID         = local.application_platform_foundry_iq.KNOWLEDGE_BASE_CONNECTION_ID
    KNOWLEDGE_BASE_ENDPOINT              = local.application_platform_foundry_iq.KNOWLEDGE_BASE_ENDPOINT
    KNOWLEDGE_BASE_NAME                  = local.application_platform_foundry_iq.KNOWLEDGE_BASE_NAME
    LOCATION                             = azurerm_resource_group.this.location
    RELEASE                              = var.application_platform.release
    RESOURCE_TOKEN                       = local.application_platform_resource_token
    RETRIEVAL_BACKEND                    = local.application_platform_foundry_iq.RETRIEVAL_BACKEND
    SUBSCRIPTION_ID                      = data.azurerm_client_config.current.subscription_id
    TENANT_ID                            = data.azurerm_client_config.current.tenant_id
  }
}

output "application_platform_container_apps" {
  description = "Container App workload resource IDs, managed identity IDs, principal IDs, and FQDNs."
  value = {
    for key, app in azapi_resource.application_platform_container_app : key => {
      resource_id                   = app.id
      name                          = app.name
      fqdn                          = try(app.output.properties.configuration.ingress.fqdn, null)
      managed_identity_resource_id  = azapi_resource.application_platform_container_app_identity[key].id
      managed_identity_principal_id = azapi_resource.application_platform_container_app_identity[key].output.properties.principalId
    }
  }
}

output "application_platform_runtime_configuration" {
  description = "Non-secret runtime configuration for post-provision population or accelerator consumption."
  value       = local.application_platform_runtime_settings
}
