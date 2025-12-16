module "search_service" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.2.0"
  count   = var.ks_ai_search_definition.deploy ? 1 : 0

  location            = azurerm_resource_group.this.location
  name                = local.ks_ai_search_name
  resource_group_name = azurerm_resource_group.this.name
  diagnostic_settings = var.ks_ai_search_definition.enable_diagnostic_settings && local.deploy_diagnostics_settings ? {
    search = {
      name                  = "sendToLogAnalytics-search-${random_string.name_suffix.result}"
      workspace_resource_id = local.log_analytics_workspace_id
    }
  } : null
  enable_telemetry             = var.enable_telemetry # see variables.tf
  local_authentication_enabled = var.ks_ai_search_definition.local_authentication_enabled
  partition_count              = var.ks_ai_search_definition.partition_count
  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = var.flag_platform_landing_zone ? [module.private_dns_zones.ai_search_zone.resource_id] : [local.private_dns_zones_existing.ai_search_zone.resource_id]
      subnet_resource_id            = local.subnet_ids["PrivateEndpointSubnet"]
    }
  }
  public_network_access_enabled = var.ks_ai_search_definition.public_network_access_enabled
  replica_count                 = var.ks_ai_search_definition.replica_count
  semantic_search_sku           = var.ks_ai_search_definition.semantic_search_sku
  sku                           = var.ks_ai_search_definition.sku

  depends_on = [module.private_dns_zones, module.hub_vnet_peering]
}

resource "azapi_resource" "bing_grounding" {
  count = var.ks_bing_grounding_definition.deploy ? 1 : 0

  location  = "global"
  name      = local.ks_bing_grounding_name
  parent_id = azurerm_resource_group.this.id
  type      = "Microsoft.Bing/accounts@2025-05-01-preview"
  body = {
    kind = "Bing.Grounding"
    sku = {
      name = var.ks_bing_grounding_definition.sku
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  tags                      = var.ks_bing_grounding_definition.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
