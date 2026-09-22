locals {
  # Static (plan-time known) gate for whether automatic diagnostic settings should be created.
  # Using only input variables here keeps for_each/count keys known at plan time. The actual
  # workspace_resource_id value may still be unknown until apply, which is allowed.
  deploy_diagnostics_settings  = var.law_definition.resource_id != null || var.law_definition.deploy
  log_analytics_workspace_id   = var.law_definition.resource_id != null ? var.law_definition.resource_id : (length(module.log_analytics_workspace) > 0 ? module.log_analytics_workspace[0].resource_id : null)
  log_analytics_workspace_name = try(var.law_definition.name, null) != null ? var.law_definition.name : (var.name_prefix != null ? "${var.name_prefix}-law" : "ai-alz-law")
  app_insights_diagnostic_settings = !var.app_insights_definition.enable_diagnostic_settings ? {} : (length(var.app_insights_definition.diagnostic_settings) > 0 ? var.app_insights_definition.diagnostic_settings : tomap({
    sendToLogAnalytics = {
      name                  = null
      workspace_resource_id = local.log_analytics_workspace_id
      logs = toset([{
        category       = null
        category_group = "allLogs"
        enabled        = true
        retention_policy = {
          days    = 0
          enabled = false
        }
      }])
      metrics = toset([{
        category = "AllMetrics"
        enabled  = true
        retention_policy = {
          days    = 0
          enabled = false
        }
      }])
      log_analytics_destination_type           = "Dedicated"
      storage_account_resource_id              = null
      event_hub_authorization_rule_resource_id = null
      event_hub_name                           = null
      marketplace_partner_resource_id          = null
    }
  }))
  app_insights_location               = lower(var.location) == "westcentralus" ? "eastus" : var.location
  app_insights_name                   = try(var.app_insights_definition.name, null) != null ? var.app_insights_definition.name : (var.name_prefix != null ? "${var.name_prefix}-app-insights" : "ai-alz-app-insights-${random_string.name_suffix.result}")
  app_insights_resource_id            = var.app_insights_definition.resource_id != null ? var.app_insights_definition.resource_id : try(azapi_resource.application_insights[0].id, null)
  app_insights_named_role_assignments = { for key, assignment in var.app_insights_definition.role_assignments : key => assignment if !startswith(assignment.role_definition_id_or_name, "/") && !can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", assignment.role_definition_id_or_name)) }
  app_insights_resolved_role_assignments = { for key, assignment in var.app_insights_definition.role_assignments : key => merge(assignment, {
    role_definition_id = startswith(assignment.role_definition_id_or_name, "/") ? assignment.role_definition_id_or_name : (
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", assignment.role_definition_id_or_name)) ?
      "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${assignment.role_definition_id_or_name}" :
      data.azapi_resource_list.app_insights_role_definition[key].output.role_definition_id
    )
  }) }
}
