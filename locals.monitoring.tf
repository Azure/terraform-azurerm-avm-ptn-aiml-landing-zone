locals {
  deploy_diagnostics_settings  = var.law_definition.resource_id != null || length(module.log_analytics_workspace) > 0
  log_analytics_workspace_id   = var.law_definition.resource_id != null ? var.law_definition.resource_id : (length(module.log_analytics_workspace) > 0 ? module.log_analytics_workspace[0].resource_id : null)
  log_analytics_workspace_name = try(var.law_definition.name, null) != null ? var.law_definition.name : (var.name_prefix != null ? "${var.name_prefix}-law" : "ai-alz-law")
}

