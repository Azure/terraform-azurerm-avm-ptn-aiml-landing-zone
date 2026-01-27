locals {
  cae_diagnostic_settings = var.container_app_environment_definition.enable_diagnostic_settings ? (length(var.container_app_environment_definition.diagnostic_settings) > 0 ? var.container_app_environment_definition.diagnostic_settings : local.cae_diagnostic_settings_inner) : {}
  cae_diagnostic_settings_inner = ((try(var.law_definition.deploy, false) == true) ? {
    sendToLogAnalytics = {
      name                                     = "sendToLogAnalytics-cae-${random_string.name_suffix.result}"
      workspace_resource_id                    = local.log_analytics_workspace_id
      log_analytics_destination_type           = null
      log_groups                               = ["allLogs"]
      metric_categories                        = ["AllMetrics"]
      log_categories                           = []
      storage_account_resource_id              = null
      event_hub_authorization_rule_resource_id = null
      event_hub_name                           = null
      marketplace_partner_resource_id          = null
    }
  } : {})
  cae_log_analytics_workspace_resource_id = (
    var.container_app_environment_definition.log_analytics_workspace_resource_id != null ?
    var.container_app_environment_definition.log_analytics_workspace_resource_id :
    local.log_analytics_workspace_id
  )
  container_app_environment_default_role_assignments = {}
  container_app_environment_name = (
    try(var.container_app_environment_definition.name, null) != null ?
    var.container_app_environment_definition.name :
    (var.name_prefix != null ? "${var.name_prefix}-container-app-env" : "ai-alz-container-app-env-${random_string.name_suffix.result}")
  )
  container_app_environment_role_assignments = merge(
    local.container_app_environment_default_role_assignments,
    var.container_app_environment_definition.role_assignments
  )
}
