module "container_apps_managed_environment" {
  source  = "Azure/avm-res-app-managedenvironment/azurerm"
  version = "0.3.0"
  count   = var.container_app_environment_definition.deploy ? 1 : 0

  location            = azurerm_resource_group.this.location
  name                = local.container_app_environment_name
  resource_group_name = azurerm_resource_group.this.name
  diagnostic_settings = var.container_app_environment_definition.enable_diagnostic_settings && local.deploy_diagnostics_settings ? {
    to_law = {
      name                           = "sendToLogAnalytics-cae-${random_string.name_suffix.result}"
      workspace_resource_id          = local.log_analytics_workspace_id
      log_analytics_destination_type = "AzureDiagnostics"
    }
  } : null
  enable_telemetry                   = var.enable_telemetry
  infrastructure_resource_group_name = "rg-managed-${azurerm_resource_group.this.name}"
  infrastructure_subnet_id           = local.subnet_ids["ContainerAppEnvironmentSubnet"]
  internal_load_balancer_enabled     = var.container_app_environment_definition.internal_load_balancer_enabled
  log_analytics_workspace = {
    resource_id = local.cae_log_analytics_workspace_resource_id
  }
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = var.container_app_environment_definition.user_assigned_managed_identity_ids
  }
  role_assignments        = local.container_app_environment_role_assignments
  tags                    = var.container_app_environment_definition.tags != null ? var.container_app_environment_definition.tags : var.tags
  workload_profile        = var.container_app_environment_definition.workload_profile
  zone_redundancy_enabled = length(local.region_zones) > 1 ? var.container_app_environment_definition.zone_redundancy_enabled : false
}
