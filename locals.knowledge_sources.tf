locals {
  ks_ai_search_diagnostic_settings = length(var.ks_ai_search_definition.diagnostic_settings) > 0 ? var.ks_ai_search_definition.diagnostic_settings : local.ks_ai_search_diagnostic_settings_inner
  ks_ai_search_diagnostic_settings_inner = ((try(var.law_definition.deploy, false) == true) ? {
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
}
