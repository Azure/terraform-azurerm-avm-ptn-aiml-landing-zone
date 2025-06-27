module "container_apps_managed_environment" {
  source  = "Azure/avm-res-app-managedenvironment/azurerm"
  version = "0.3.0"

  location                           = azurerm_resource_group.this.location
  name                               = local.container_app_environment_name
  resource_group_name                = azurerm_resource_group.this.name
  infrastructure_resource_group_name = "rg-managed-${azurerm_resource_group.this.name}"
  infrastructure_subnet_id           = module.ai_lz_vnet.subnets["ContainerAppEnvironmentSubnet"].resource_id
  internal_load_balancer_enabled     = var.container_app_environment_definition.internal_load_balancer_enabled
  enable_telemetry                   = var.enable_telemetry
  log_analytics_workspace = {
    resource_id = local.cae_log_analytics_workspace_resource_id
  }
  workload_profile        = var.container_app_environment_definition.workload_profile
  zone_redundancy_enabled = length(local.region_zones) > 1 ? var.container_app_environment_definition.zone_redundancy_enabled : false

  diagnostic_settings = {
    to_law = {
      name                  = "sendToLogAnalytics-${random_string.name_suffix.result}"
      workspace_resource_id = var.law_definition.resource_id != null ? var.law_definition.resource_id : module.log_analytics_workspace[0].resource_id
    }
  }

  role_assignments = local.container_app_environment_role_assignments
  tags             = var.container_app_environment_definition.tags

}
