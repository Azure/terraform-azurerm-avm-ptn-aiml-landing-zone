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
      role_definition_id_or_name = "25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    deployment_principal_user = {
      role_definition_id_or_name = "a97b65f3-24c7-4388-baec-2e87135dc908"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  } : {}
  ks_speech_role_assignments       = merge(local.ks_speech_default_role_assignments, var.ks_speech_service_definition.role_assignments)
  ks_speech_named_role_assignments = { for key, assignment in local.ks_speech_role_assignments : key => assignment if !startswith(assignment.role_definition_id_or_name, "/") && !can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", assignment.role_definition_id_or_name)) }
  ks_speech_resolved_role_assignments = { for key, assignment in local.ks_speech_role_assignments : key => merge(assignment, {
    role_definition_id = startswith(assignment.role_definition_id_or_name, "/") ? assignment.role_definition_id_or_name : (
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", assignment.role_definition_id_or_name)) ?
      "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${assignment.role_definition_id_or_name}" :
      data.azapi_resource_list.ks_speech_role_definition[key].output.role_definition_id
    )
  }) }
  ks_speech_private_endpoint_name = "pep-${local.ks_speech_service_name}"
  ks_speech_private_dns_zone_id   = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? null : (!var.flag_platform_landing_zone ? module.private_dns_zones.ai_foundry_cognitive_services_zone.resource_id : local.private_dns_zones_existing.ai_foundry_cognitive_services_zone.resource_id)
}
