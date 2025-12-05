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
  tags                                      = var.law_definition.tags != null ? var.law_definition.tags : var.tags
}
