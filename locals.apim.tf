locals {
  apim_diagnostic_settings = length(var.apim_definition.diagnostic_settings) > 0 ? var.apim_definition.diagnostic_settings : local.apim_diagnostic_settings_inner
  apim_diagnostic_settings_inner = ((try(var.law_definition.deploy, false) == true) ? {
    sendToLogAnalytics = {
      name                                     = "sendToLogAnalytics-apim-${random_string.name_suffix.result}"
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
  apim_name             = try(var.apim_definition.name, null) != null ? var.apim_definition.name : (var.name_prefix != null ? "${var.name_prefix}-apim-${random_string.name_suffix.result}" : "ai-alz-apim-${random_string.name_suffix.result}")
  apim_role_assignments = try(var.apim_definition.role_assignments, {})
}
