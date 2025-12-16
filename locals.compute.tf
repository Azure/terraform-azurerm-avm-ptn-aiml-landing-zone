locals {
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
