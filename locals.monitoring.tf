locals {
  # Static (plan-time known) gate for whether automatic diagnostic settings should be created.
  # Using only input variables here keeps for_each/count keys known at plan time. The actual
  # workspace_resource_id value may still be unknown until apply, which is allowed.
  deploy_diagnostics_settings  = var.law_definition.resource_id != null || var.law_definition.deploy
  log_analytics_workspace_id   = var.law_definition.resource_id != null ? var.law_definition.resource_id : (length(module.log_analytics_workspace) > 0 ? module.log_analytics_workspace[0].resource_id : null)
  log_analytics_workspace_name = try(var.law_definition.name, null) != null ? var.law_definition.name : (var.name_prefix != null ? "${var.name_prefix}-law" : "ai-alz-law")
}
