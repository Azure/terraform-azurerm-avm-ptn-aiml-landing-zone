output "application_insights_name" {
  description = "The name of the created Application Insights component, or null when an existing component is reused."
  value       = var.app_insights_definition.resource_id == null && var.app_insights_definition.deploy ? local.app_insights_name : null
}

output "application_insights_resource_id" {
  description = "The resource ID of the created or reused Application Insights component. No connection string or instrumentation key is exposed."
  value       = local.app_insights_resource_id
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace used for monitoring."
  value       = local.log_analytics_workspace_id
}
