module "search_service" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.2.0"
  count   = var.ks_ai_search_definition.deploy ? 1 : 0

  location                     = azapi_resource.this.location
  name                         = local.ks_ai_search_name
  resource_group_name          = azapi_resource.this.name
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

resource "azapi_resource" "bing_grounding" {
  count = var.ks_bing_grounding_definition.deploy ? 1 : 0

  location  = "global"
  name      = local.ks_bing_grounding_name
  parent_id = azapi_resource.this.id
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
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
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
