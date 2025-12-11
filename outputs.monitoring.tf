output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace used for monitoring."
  value       = length(module.log_analytics_workspace) > 0 ? module.log_analytics_workspace[0].resource_id : var.law_definition.resource_id
}
