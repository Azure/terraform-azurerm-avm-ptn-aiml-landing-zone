locals {
  ks_ai_search_diagnostic_settings = var.ks_ai_search_definition.enable_diagnostic_settings ? (length(var.ks_ai_search_definition.diagnostic_settings) > 0 ? var.ks_ai_search_definition.diagnostic_settings : local.ks_ai_search_diagnostic_settings_inner) : {}
  ks_ai_search_diagnostic_settings_inner = (local.deploy_diagnostics_settings ? {
    sendToLogAnalytics = {
      name                                     = "sendToLogAnalytics-ks-ai-search-${random_string.name_suffix.result}"
      workspace_resource_id                    = local.log_analytics_workspace_id
      log_analytics_destination_type           = "Dedicated"
      log_groups                               = ["allLogs"]
      metric_categories                        = ["AllMetrics"]
      log_categories                           = []
      storage_account_resource_id              = null
      event_hub_authorization_rule_resource_id = null
      event_hub_name                           = null
      marketplace_partner_resource_id          = null
    }
  } : {})
  ks_ai_search_name             = try(var.ks_ai_search_definition.name, null) != null ? var.ks_ai_search_definition.name : (var.name_prefix != null ? "${var.name_prefix}-ks-ai-search" : "ai-alz-ks-ai-search-${random_string.name_suffix.result}")
  ks_ai_search_role_assignments = try(var.ks_ai_search_definition.role_assignments, {})
  ks_bing_grounding_name        = try(var.ks_bing_grounding_definition.name, null) != null ? var.ks_bing_grounding_definition.name : (var.name_prefix != null ? "${var.name_prefix}-ks-bing-grounding" : "ai-alz-ks-bing-grounding-${random_string.name_suffix.result}")
  ks_speech_service_name        = try(var.ks_speech_service_definition.name, null) != null ? var.ks_speech_service_definition.name : (var.name_prefix != null ? "${var.name_prefix}-speech" : "ai-alz-speech-${random_string.name_suffix.result}")
  ks_speech_service_location    = try(var.ks_speech_service_definition.location, null) != null ? var.ks_speech_service_definition.location : var.location
  ks_speech_diagnostic_settings = var.ks_speech_service_definition.enable_diagnostic_settings ? (length(var.ks_speech_service_definition.diagnostic_settings) > 0 ? var.ks_speech_service_definition.diagnostic_settings : (
    local.deploy_diagnostics_settings ? {
      sendToLogAnalytics = {
        name                                     = "sendToLogAnalytics-ks-speech-${random_string.name_suffix.result}"
        workspace_resource_id                    = local.log_analytics_workspace_id
        log_analytics_destination_type           = "Dedicated"
        log_groups                               = ["allLogs"]
        metric_categories                        = ["AllMetrics"]
        log_categories                           = []
        storage_account_resource_id              = null
        event_hub_authorization_rule_resource_id = null
        event_hub_name                           = null
        marketplace_partner_resource_id          = null
      }
    } : {}
  )) : {}
  ks_speech_default_role_assignments = var.ks_speech_service_definition.assign_deployment_principal_rbac ? {
    deployment_principal_contributor = {
      role_definition_id_or_name = "Cognitive Services Contributor"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    deployment_principal_user = {
      role_definition_id_or_name = "Cognitive Services User"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  } : {}
  ks_speech_role_assignments = merge(local.ks_speech_default_role_assignments, var.ks_speech_service_definition.role_assignments)
}
