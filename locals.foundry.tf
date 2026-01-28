locals {
  ai_foundry_name = try(var.ai_foundry_definition.name, null) != null ? var.ai_foundry_definition.name : (var.name_prefix != null ? "${var.name_prefix}-ai-foundry-${random_string.name_suffix.result}" : "ai-foundry-${random_string.name_suffix.result}")
  foundry_ai_foundry = merge(
    var.ai_foundry_definition.ai_foundry, {
      name = local.ai_foundry_name
      network_injections = [{
        scenario                   = "agent"
        subnetArmId                = local.subnet_ids["AIFoundrySubnet"]
        useMicrosoftManagedNetwork = false
      }]
      private_dns_zone_resource_ids = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? null : [
        (var.flag_platform_landing_zone ? module.private_dns_zones.ai_foundry_openai_zone.resource_id : local.private_dns_zones_existing.ai_foundry_openai_zone.resource_id),
        (var.flag_platform_landing_zone ? module.private_dns_zones.ai_foundry_ai_services_zone.resource_id : local.private_dns_zones_existing.ai_foundry_ai_services_zone.resource_id),
        (var.flag_platform_landing_zone ? module.private_dns_zones.ai_foundry_cognitive_services_zone.resource_id : local.private_dns_zones_existing.ai_foundry_cognitive_services_zone.resource_id)
      ]
      private_endpoints_manage_dns_zone_group = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? false : var.ai_foundry_definition.ai_foundry.private_endpoints_manage_dns_zone_group
    }
  )
  foundry_ai_search_definition = { for key, value in var.ai_foundry_definition.ai_search_definition : key => merge(
    var.ai_foundry_definition.ai_search_definition[key], {
      private_dns_zone_resource_id            = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? null : (var.flag_platform_landing_zone ? module.private_dns_zones.ai_search_zone.resource_id : local.private_dns_zones_existing.ai_search_zone.resource_id)
      private_endpoints_manage_dns_zone_group = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? false : var.ai_foundry_definition.ai_search_definition[key].private_endpoints_manage_dns_zone_group
    }
  ) }
  foundry_cosmosdb_definition = { for key, value in var.ai_foundry_definition.cosmosdb_definition : key => merge(
    var.ai_foundry_definition.cosmosdb_definition[key], {
      private_dns_zone_resource_id            = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? null : (var.flag_platform_landing_zone ? module.private_dns_zones.cosmos_sql_zone.resource_id : local.private_dns_zones_existing.cosmos_sql_zone.resource_id)
      private_endpoints_manage_dns_zone_group = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? false : var.ai_foundry_definition.cosmosdb_definition[key].private_endpoints_manage_dns_zone_group
    }
  ) }
  foundry_diagnostic_settings = var.ai_foundry_definition.ai_foundry.enable_diagnostic_settings ? (length(var.ai_foundry_definition.ai_foundry.diagnostic_settings) > 0 ? var.ai_foundry_definition.ai_foundry.diagnostic_settings : local.foundry_diagnostic_settings_inner) : {}
  foundry_diagnostic_settings_inner = ((try(var.law_definition.deploy, false) == true) ? {
    sendToLogAnalytics = {
      name                                     = "sendToLogAnalytics-foundry-${random_string.name_suffix.result}"
      workspace_resource_id                    = local.log_analytics_workspace_id
      log_analytics_destination_type           = null
      log_groups                               = ["allLogs"]
      metric_categories                        = ["AllMetrics"]
      log_categories                           = []
      storage_account_resource_id              = null
      event_hub_authorization_rule_resource_id = null
      event_hub_name                           = null
      marketplace_partner_resource_id          = null
    }
  } : {})
  foundry_key_vault_definition = { for key, value in var.ai_foundry_definition.key_vault_definition : key => merge(
    var.ai_foundry_definition.key_vault_definition[key], {
      private_dns_zone_resource_id            = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? null : (var.flag_platform_landing_zone ? module.private_dns_zones.key_vault_zone.resource_id : local.private_dns_zones_existing.key_vault_zone.resource_id)
      private_endpoints_manage_dns_zone_group = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? false : var.ai_foundry_definition.key_vault_definition[key].private_endpoints_manage_dns_zone_group
    }
  ) }
  foundry_storage_account_definition = { for key, value in var.ai_foundry_definition.storage_account_definition : key => merge(
    var.ai_foundry_definition.storage_account_definition[key], {
      endpoints = {
        for ek, ev in value.endpoints :
        ek => {
          private_dns_zone_resource_id            = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? null : (var.flag_platform_landing_zone ? module.private_dns_zones["storage_${lower(ek)}_zone"].resource_id : local.private_dns_zones_existing["storage_${lower(ek)}_zone"].resource_id)
          private_endpoints_manage_dns_zone_group = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? false : var.ai_foundry_definition.storage_account_definition[key].endpoints[ek].private_endpoints_manage_dns_zone_group
          type                                    = lower(ek)
        }
      }
    }
  ) }
}

