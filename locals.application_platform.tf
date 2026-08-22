locals {
  application_platform_deployment_mode = coalesce(
    var.application_platform.deployment_mode,
    var.flag_platform_landing_zone ? "ailz-integrated" : "standalone"
  )
  application_platform_environment_name    = coalesce(var.application_platform.environment_name, var.resource_group_name)
  application_platform_resource_token      = coalesce(var.application_platform.resource_token, random_string.name_suffix.result)
  application_platform_subscription_scope  = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  application_platform_use_zone_redundancy = var.application_platform.use_zone_redundancy

  application_platform_app_config_endpoint         = try(module.app_configuration[0].endpoint, null)
  application_platform_container_registry_endpoint = try(module.containerregistry[0].resource.login_server, null)

  application_platform_foundry_iq = {
    ENABLE_AGENTIC_RETRIEVAL                    = tostring(var.application_platform.foundry_iq.enable_agentic_retrieval)
    RETRIEVAL_BACKEND                           = var.application_platform.foundry_iq.retrieval_backend
    FOUNDRY_IQ_PATTERN                          = var.application_platform.foundry_iq.pattern == "managed" ? "azureBlob" : var.application_platform.foundry_iq.pattern
    FOUNDRY_IQ_API_VERSION                      = var.application_platform.foundry_iq.api_version
    FOUNDRY_IQ_KNOWLEDGE_RETRIEVAL_BILLING_PLAN = var.application_platform.foundry_iq.knowledge_retrieval_billing_plan
    KNOWLEDGE_BASE_NAME                         = coalesce(var.application_platform.foundry_iq.knowledge_base_name, "${local.application_platform_environment_name}-knowledge-base")
    KNOWLEDGE_BASE_CONNECTION_NAME              = coalesce(var.application_platform.foundry_iq.knowledge_base_connection_name, "${local.application_platform_environment_name}-knowledge-base-connection")
    KNOWLEDGE_BASE_CONNECTION_ID                = var.application_platform.foundry_iq.knowledge_base_connection_id
    KNOWLEDGE_BASE_ENDPOINT                     = var.application_platform.foundry_iq.knowledge_base_endpoint
    FOUNDRY_IQ_KNOWLEDGE_SOURCE_NAME            = coalesce(var.application_platform.foundry_iq.knowledge_source_name, "${local.application_platform_environment_name}-blob-ks")
    FOUNDRY_IQ_KNOWLEDGE_SOURCE_KIND = (
      var.application_platform.foundry_iq.retrieval_backend != "foundry_iq" ? "" :
      var.application_platform.foundry_iq.knowledge_source_kind != "" ? var.application_platform.foundry_iq.knowledge_source_kind :
      var.application_platform.foundry_iq.pattern == "searchIndex" ? "searchIndex" : "azureBlob"
    )
    FOUNDRY_IQ_STORAGE_CONTAINER_NAME       = var.application_platform.foundry_iq.storage_container_name
    FOUNDRY_IQ_STORAGE_FOLDER_PATH          = var.application_platform.foundry_iq.storage_folder_path
    FOUNDRY_IQ_IS_ADLS_GEN2                 = tostring(var.application_platform.foundry_iq.is_adls_gen2)
    FOUNDRY_IQ_CONTENT_EXTRACTION_MODE      = var.application_platform.foundry_iq.content_extraction_mode
    FOUNDRY_IQ_AI_SERVICES_ENDPOINT         = var.application_platform.foundry_iq.ai_services_endpoint
    FOUNDRY_IQ_INGESTION_PERMISSION_OPTIONS = jsonencode(var.application_platform.foundry_iq.ingestion_permission_options)
    FOUNDRY_IQ_SEARCH_INDEX_NAME            = var.application_platform.foundry_iq.search_index_name
    FOUNDRY_IQ_SEMANTIC_CONFIGURATION_NAME  = var.application_platform.foundry_iq.semantic_configuration_name
    FOUNDRY_IQ_SOURCE_DATA_FIELDS           = jsonencode(var.application_platform.foundry_iq.source_data_fields)
    FOUNDRY_IQ_SEARCH_FIELDS                = jsonencode(var.application_platform.foundry_iq.search_fields)
    FOUNDRY_IQ_BASE_FILTER                  = var.application_platform.foundry_iq.base_filter
    FOUNDRY_IQ_FILTER_ADD_ON_ENABLED        = tostring(var.application_platform.foundry_iq.filter_add_on_enabled)
    FOUNDRY_IQ_SECURITY_FIELD_NAME          = var.application_platform.foundry_iq.security_field_name
    FOUNDRY_IQ_MAX_OUTPUT_DOCUMENTS         = var.application_platform.foundry_iq.max_output_documents
  }

  application_platform_runtime_settings = merge({
    APP_CONFIG_ENDPOINT               = local.application_platform_app_config_endpoint != null ? local.application_platform_app_config_endpoint : ""
    APP_CONFIG_NAME                   = try(module.app_configuration[0].name, "")
    APP_RUNTIME_CONFIGURATION_MODE    = var.application_platform.app_runtime_configuration_mode
    AZURE_CONTAINER_REGISTRY_ENDPOINT = local.application_platform_container_registry_endpoint != null ? local.application_platform_container_registry_endpoint : ""
    AZURE_RESOURCE_GROUP              = azurerm_resource_group.this.name
    AZURE_TENANT_ID                   = data.azurerm_client_config.current.tenant_id
    COSMOS_LOCATION                   = coalesce(var.application_platform.cosmos_location, var.location)
    CONTAINER_ENV_NAME                = try(module.container_apps_managed_environment[0].name, "")
    CONTAINER_ENV_RESOURCE_ID         = try(module.container_apps_managed_environment[0].resource_id, "")
    CONTAINER_REGISTRY_NAME           = try(module.containerregistry[0].name, "")
    DEPLOY_APP_CONFIG                 = tostring(var.genai_app_configuration_definition.deploy)
    DEPLOY_CONTAINER_APPS             = tostring(length(var.application_platform.container_apps) > 0)
    DEPLOY_CONTAINER_ENV              = tostring(var.container_app_environment_definition.deploy)
    DEPLOY_CONTAINER_REGISTRY         = tostring(var.genai_container_registry_definition.deploy)
    DEPLOYMENT_MODE                   = local.application_platform_deployment_mode
    ENVIRONMENT_NAME                  = local.application_platform_environment_name
    LOCATION                          = azurerm_resource_group.this.location
    NETWORK_ISOLATION                 = "true"
    RELEASE                           = var.application_platform.release
    RESOURCE_TOKEN                    = local.application_platform_resource_token
    SUBSCRIPTION_ID                   = data.azurerm_client_config.current.subscription_id
  }, local.application_platform_foundry_iq)

  application_platform_additional_settings = {
    for key, setting in var.application_platform.additional_app_configuration_settings :
    key => {
      value        = setting.value
      label        = coalesce(setting.label, var.application_platform.app_config_label)
      content_type = setting.content_type
    }
  }

  application_platform_app_config_settings = merge(
    {
      for key, value in local.application_platform_runtime_settings :
      key => {
        value        = value
        label        = var.application_platform.app_config_label
        content_type = "text/plain"
      }
    },
    local.application_platform_additional_settings
  )

  application_platform_container_app_names = {
    for key, app in var.application_platform.container_apps :
    key => coalesce(app.name, "${key}-${local.application_platform_resource_token}")
  }
}
