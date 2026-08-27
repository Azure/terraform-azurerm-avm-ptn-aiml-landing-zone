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

data "azapi_resource_list" "app_insights_role_definition" {
  for_each = local.app_insights_named_role_assignments

  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  query_parameters = {
    "$filter" = ["roleName eq '${replace(each.value.role_definition_id_or_name, "'", "''")}'"]
  }
  type    = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = {
    role_definition_id = "value[0].id"
  }
  retry = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      read = timeouts.value.read
    }
  }
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

resource "azapi_resource" "application_insights" {
  count = var.app_insights_definition.resource_id == null && var.app_insights_definition.deploy ? 1 : 0

  location  = local.app_insights_location
  name      = local.app_insights_name
  parent_id = azurerm_resource_group.this.id
  type      = var.resource_types.insights_components
  body = {
    kind = "web"
    properties = {
      Application_Type                = var.app_insights_definition.application_type
      DisableIpMasking                = var.app_insights_definition.disable_ip_masking
      DisableLocalAuth                = var.app_insights_definition.local_authentication_disabled
      Flow_Type                       = "Bluefield"
      Request_Source                  = "rest"
      RetentionInDays                 = var.app_insights_definition.retention_in_days
      WorkspaceResourceId             = local.log_analytics_workspace_id
      publicNetworkAccessForIngestion = var.app_insights_definition.internet_ingestion_enabled ? "Enabled" : "Disabled"
      publicNetworkAccessForQuery     = var.app_insights_definition.internet_query_enabled ? "Enabled" : "Disabled"
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.insights_components) > 0 ? var.ignore_body_changes.insights_components : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = ["properties.WorkspaceResourceId"]
  retry                  = var.retry
  tags                   = merge(local.tags, var.app_insights_definition.tags != null ? var.app_insights_definition.tags : {})
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [terraform_data.observability_contract]
}

resource "azapi_resource_action" "application_insights_daily_cap" {
  count = var.app_insights_definition.resource_id == null && var.app_insights_definition.deploy ? 1 : 0

  action      = "currentbillingfeatures"
  method      = "PUT"
  resource_id = azapi_resource.application_insights[0].id
  type        = var.resource_types.insights_components_currentbillingfeatures
  body = {
    CurrentBillingFeatures = ["Basic"]
    DataVolumeCap = {
      Cap                            = var.app_insights_definition.daily_data_cap_in_gb
      StopSendNotificationWhenHitCap = false
    }
  }
  headers                = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource" "application_insights_diagnostic_setting" {
  for_each = var.app_insights_definition.resource_id == null && var.app_insights_definition.deploy ? local.app_insights_diagnostic_settings : {}

  name      = coalesce(try(each.value.name, null), "diag-${local.app_insights_name}")
  parent_id = azapi_resource.application_insights[0].id
  type      = var.resource_types.insights_diagnostic_settings
  body = {
    properties = { for key, value in {
      eventHubAuthorizationRuleId = try(each.value.event_hub_authorization_rule_resource_id, null)
      eventHubName                = try(each.value.event_hub_name, null)
      logAnalyticsDestinationType = try(each.value.log_analytics_destination_type, "Dedicated")
      logs = [for log in try(each.value.logs, []) : { for log_key, log_value in {
        category      = log.category
        categoryGroup = log.category_group
        enabled       = log.enabled
        retentionPolicy = {
          days    = log.retention_policy.days
          enabled = log.retention_policy.enabled
        }
      } : log_key => log_value if log_value != null }]
      marketplacePartnerId = try(each.value.marketplace_partner_resource_id, null)
      metrics = [for metric in try(each.value.metrics, []) : { for metric_key, metric_value in {
        category = metric.category
        enabled  = metric.enabled
        retentionPolicy = {
          days    = metric.retention_policy.days
          enabled = metric.retention_policy.enabled
        }
      } : metric_key => metric_value if metric_value != null }]
      storageAccountId = try(each.value.storage_account_resource_id, null)
      workspaceId      = each.value.workspace_resource_id
    } : key => value if value != null }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.insights_diagnostic_settings) > 0 ? var.ignore_body_changes.insights_diagnostic_settings : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource" "application_insights_role_assignment" {
  for_each = var.app_insights_definition.resource_id == null && var.app_insights_definition.deploy ? local.app_insights_resolved_role_assignments : {}

  name      = uuidv5("url", "${azapi_resource.application_insights[0].id}|${each.value.principal_id}|${each.value.role_definition_id}")
  parent_id = azapi_resource.application_insights[0].id
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = { for key, value in {
      condition                          = each.value.condition
      conditionVersion                   = each.value.condition_version
      delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
      description                        = each.value.description
      principalId                        = each.value.principal_id
      principalType                      = each.value.principal_type
      roleDefinitionId                   = each.value.role_definition_id
    } : key => value if value != null }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
