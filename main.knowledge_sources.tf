module "search_service" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.2.0"
  count   = var.ks_ai_search_definition.deploy ? 1 : 0

  location                     = azurerm_resource_group.this.location
  name                         = local.ks_ai_search_name
  resource_group_name          = azurerm_resource_group.this.name
  diagnostic_settings          = local.ks_ai_search_diagnostic_settings
  enable_telemetry             = var.enable_telemetry # see variables.tf
  local_authentication_enabled = var.ks_ai_search_definition.local_authentication_enabled
  network_rule_bypass_option   = var.ks_ai_search_definition.network_rule_bypass_option
  partition_count              = var.ks_ai_search_definition.partition_count
  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? null : (!var.flag_platform_landing_zone ? [module.private_dns_zones.ai_search_zone.resource_id] : [local.private_dns_zones_existing.ai_search_zone.resource_id])
      subnet_resource_id            = local.subnet_ids["PrivateEndpointSubnet"]
    }

  }
  public_network_access_enabled = var.ks_ai_search_definition.public_network_access_enabled
  replica_count                 = var.ks_ai_search_definition.replica_count
  role_assignments              = local.ks_ai_search_role_assignments
  semantic_search_sku           = var.ks_ai_search_definition.semantic_search_sku
  sku                           = var.ks_ai_search_definition.sku
  tags                          = merge(local.tags, var.ks_ai_search_definition.tags != null ? var.ks_ai_search_definition.tags : {})

  depends_on = [module.private_dns_zones, module.hub_vnet_peering]
}

data "azapi_resource_list" "ks_speech_role_definition" {
  for_each = local.ks_speech_named_role_assignments

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

resource "azapi_resource" "speech_service" {
  count = var.ks_speech_service_definition.deploy ? 1 : 0

  location  = local.ks_speech_service_location
  name      = local.ks_speech_service_name
  parent_id = azurerm_resource_group.this.id
  type      = var.resource_types.cognitiveservices_accounts
  body = {
    kind = "SpeechServices"
    sku = {
      name = var.ks_speech_service_definition.sku
    }
    properties = {
      customSubDomainName = local.ks_speech_service_name
      disableLocalAuth    = !var.ks_speech_service_definition.local_authentication_enabled
      networkAcls = {
        bypass        = "AzureServices"
        defaultAction = var.ks_speech_service_definition.public_network_access_enabled ? "Allow" : "Deny"
      }
      publicNetworkAccess = var.ks_speech_service_definition.public_network_access_enabled ? "Enabled" : "Disabled"
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.cognitiveservices_accounts) > 0 ? var.ignore_body_changes.cognitiveservices_accounts : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = ["properties.endpoint", "identity.principalId"]
  retry                  = var.retry
  tags                   = merge(local.tags, var.ks_speech_service_definition.tags != null ? var.ks_speech_service_definition.tags : {})
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  identity {
    type = "SystemAssigned"
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [module.private_dns_zones, module.hub_vnet_peering]
}

resource "azapi_resource" "speech_private_endpoint" {
  count = var.ks_speech_service_definition.deploy && !var.ks_speech_service_definition.public_network_access_enabled ? 1 : 0

  location  = local.ks_speech_service_location
  name      = local.ks_speech_private_endpoint_name
  parent_id = azurerm_resource_group.this.id
  type      = var.resource_types.network_private_endpoints
  body = {
    properties = {
      privateLinkServiceConnections = [{
        name = "${local.ks_speech_service_name}-account"
        properties = {
          groupIds             = ["account"]
          privateLinkServiceId = azapi_resource.speech_service[0].id
        }
      }]
      subnet = {
        id = local.subnet_ids["PrivateEndpointSubnet"]
      }
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  retry                  = var.retry
  tags                   = merge(local.tags, var.ks_speech_service_definition.tags != null ? var.ks_speech_service_definition.tags : {})
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

  lifecycle {
    ignore_changes = [body.properties.customDnsConfigs]
  }
}

resource "azapi_resource" "speech_private_dns_zone_group" {
  count = var.ks_speech_service_definition.deploy && !var.ks_speech_service_definition.public_network_access_enabled && !var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? 1 : 0

  name      = "default"
  parent_id = azapi_resource.speech_private_endpoint[0].id
  type      = var.resource_types.network_private_endpoints_private_dns_zone_groups
  body = {
    properties = {
      privateDnsZoneConfigs = [{
        name = "cognitive-services"
        properties = {
          privateDnsZoneId = local.ks_speech_private_dns_zone_id
        }
      }]
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups) > 0 ? var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups : null
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

resource "azapi_resource" "speech_diagnostic_setting" {
  for_each = var.ks_speech_service_definition.deploy ? local.ks_speech_diagnostic_settings : {}

  name      = coalesce(each.value.name, "diag-${local.ks_speech_service_name}")
  parent_id = azapi_resource.speech_service[0].id
  type      = var.resource_types.insights_diagnostic_settings
  body = {
    properties = { for key, value in {
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      logAnalyticsDestinationType = each.value.log_analytics_destination_type
      logs = concat(
        [for category in each.value.log_categories : { category = category, enabled = true }],
        [for group in each.value.log_groups : { categoryGroup = group, enabled = true }]
      )
      marketplacePartnerId = each.value.marketplace_partner_resource_id
      metrics              = [for category in each.value.metric_categories : { category = category, enabled = true }]
      storageAccountId     = each.value.storage_account_resource_id
      workspaceId          = each.value.workspace_resource_id
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

resource "azapi_resource" "speech_role_assignment" {
  for_each = var.ks_speech_service_definition.deploy ? local.ks_speech_resolved_role_assignments : {}

  name      = uuidv5("url", "${azapi_resource.speech_service[0].id}|${each.value.principal_id}|${each.value.role_definition_id}")
  parent_id = azapi_resource.speech_service[0].id
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = { for key, value in {
      condition                          = try(each.value.condition, null)
      conditionVersion                   = try(each.value.condition_version, null)
      delegatedManagedIdentityResourceId = try(each.value.delegated_managed_identity_resource_id, null)
      description                        = try(each.value.description, null)
      principalId                        = each.value.principal_id
      principalType                      = try(each.value.principal_type, null)
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

resource "azapi_resource" "bing_grounding" {
  count = var.ks_bing_grounding_definition.deploy ? 1 : 0

  location  = "global"
  name      = local.ks_bing_grounding_name
  parent_id = azurerm_resource_group.this.id
  type      = var.resource_types.bing_accounts
  body = {
    kind = "Bing.Grounding"
    sku = {
      name = var.ks_bing_grounding_definition.sku
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes       = length(var.ignore_body_changes.bing_accounts) > 0 ? var.ignore_body_changes.bing_accounts : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values    = []
  retry                     = var.retry
  schema_validation_enabled = false
  tags                      = merge(local.tags, var.ks_bing_grounding_definition.tags != null ? var.ks_bing_grounding_definition.tags : {})
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # The Microsoft.Bing/accounts resource provider normalizes tag keys by
  # lower-casing the first character (e.g. "SecurityControl" -> "securityControl"),
  # which produces a permanent, non-idempotent diff on every plan. Tags are still
  # applied on create; ignore subsequent drift so the plan stays idempotent.
  lifecycle {
    ignore_changes = [tags]
  }
}
