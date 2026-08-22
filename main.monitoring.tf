module "log_analytics_workspace" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.4.2"
  count   = var.law_definition.resource_id == null && var.law_definition.deploy ? 1 : 0

  location                                  = azurerm_resource_group.this.location
  name                                      = local.log_analytics_workspace_name
  resource_group_name                       = azurerm_resource_group.this.name
  enable_telemetry                          = var.enable_telemetry
  log_analytics_workspace_retention_in_days = var.law_definition.retention
  log_analytics_workspace_sku               = var.law_definition.sku
  tags                                      = merge(local.tags, var.law_definition.tags != null ? var.law_definition.tags : {})
}

data "azapi_resource" "existing_application_insights" {
  count = var.app_insights_definition.resource_id != null && var.law_definition.resource_id != null && !var.app_insights_definition.allow_mixed_workspaces ? 1 : 0

  resource_id            = var.app_insights_definition.resource_id
  type                   = "Microsoft.Insights/components@2020-02-02"
  response_export_values = ["properties.WorkspaceResourceId"]
}

resource "terraform_data" "observability_contract" {
  lifecycle {
    precondition {
      condition     = !var.app_insights_definition.deploy || var.app_insights_definition.resource_id != null || var.law_definition.deploy || var.law_definition.resource_id != null
      error_message = "Application Insights creation requires a created or existing Log Analytics workspace."
    }
    precondition {
      condition     = var.app_insights_definition.resource_id == null || var.law_definition.resource_id != null || var.app_insights_definition.allow_mixed_workspaces
      error_message = "Reusing Application Insights requires `law_definition.resource_id` unless `app_insights_definition.allow_mixed_workspaces` is true."
    }
    precondition {
      condition = (
        var.app_insights_definition.resource_id == null ||
        var.law_definition.resource_id == null ||
        var.app_insights_definition.allow_mixed_workspaces ||
        try(
          trimsuffix(lower(data.azapi_resource.existing_application_insights[0].output.properties.WorkspaceResourceId), "/") ==
          trimsuffix(lower(var.law_definition.resource_id), "/"),
          false
        )
      )
      error_message = "The existing Application Insights component must use `law_definition.resource_id`; set `app_insights_definition.allow_mixed_workspaces` to true only for an intentional mixed-workspace deployment."
    }
  }
}

module "application_insights" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "0.4.0"
  count   = var.app_insights_definition.resource_id == null && var.app_insights_definition.deploy ? 1 : 0

  location                      = local.app_insights_location
  name                          = local.app_insights_name
  resource_group_name           = azurerm_resource_group.this.name
  workspace_id                  = local.log_analytics_workspace_id
  application_type              = var.app_insights_definition.application_type
  daily_data_cap_in_gb          = var.app_insights_definition.daily_data_cap_in_gb
  diagnostic_settings           = local.app_insights_diagnostic_settings
  disable_ip_masking            = var.app_insights_definition.disable_ip_masking
  enable_telemetry              = var.enable_telemetry
  internet_ingestion_enabled    = var.app_insights_definition.internet_ingestion_enabled
  internet_query_enabled        = var.app_insights_definition.internet_query_enabled
  local_authentication_disabled = var.app_insights_definition.local_authentication_disabled
  retention_in_days             = var.app_insights_definition.retention_in_days
  role_assignments              = var.app_insights_definition.role_assignments
  tags                          = merge(local.tags, var.app_insights_definition.tags != null ? var.app_insights_definition.tags : {})

  depends_on = [terraform_data.observability_contract]
}
