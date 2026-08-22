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

module "speech_service" {
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "0.11.1"
  count   = var.ks_speech_service_definition.deploy ? 1 : 0

  kind                  = "SpeechServices"
  location              = local.ks_speech_service_location
  name                  = local.ks_speech_service_name
  parent_id             = azurerm_resource_group.this.id
  sku_name              = var.ks_speech_service_definition.sku
  custom_subdomain_name = local.ks_speech_service_name
  diagnostic_settings   = local.ks_speech_diagnostic_settings
  enable_telemetry      = var.enable_telemetry
  local_auth_enabled    = var.ks_speech_service_definition.local_authentication_enabled
  managed_identities    = { system_assigned = true }
  network_acls          = { default_action = "Deny", bypass = "AzureServices" }
  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? [] : [!var.flag_platform_landing_zone ? module.private_dns_zones.ai_foundry_cognitive_services_zone.resource_id : local.private_dns_zones_existing.ai_foundry_cognitive_services_zone.resource_id]
      subnet_resource_id            = local.subnet_ids["PrivateEndpointSubnet"]
    }
  }
  private_endpoints_manage_dns_zone_group = !var.private_dns_zones.azure_policy_pe_zone_linking_enabled
  public_network_access_enabled           = var.ks_speech_service_definition.public_network_access_enabled
  role_assignments                        = local.ks_speech_role_assignments
  tags                                    = merge(local.tags, var.ks_speech_service_definition.tags != null ? var.ks_speech_service_definition.tags : {})

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
  tags                      = merge(local.tags, var.ks_bing_grounding_definition.tags != null ? var.ks_bing_grounding_definition.tags : {})
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  # The Microsoft.Bing/accounts resource provider normalizes tag keys by
  # lower-casing the first character (e.g. "SecurityControl" -> "securityControl"),
  # which produces a permanent, non-idempotent diff on every plan. Tags are still
  # applied on create; ignore subsequent drift so the plan stays idempotent.
  lifecycle {
    ignore_changes = [tags]
  }
}
