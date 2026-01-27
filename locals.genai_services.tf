locals {
  genai_app_configuration_default_role_assignments = {}
  genai_app_configuration_diagnostic_settings      = var.genai_app_configuration_definition.enable_diagnostic_settings ? (length(var.genai_app_configuration_definition.diagnostic_settings) > 0 ? var.genai_app_configuration_definition.diagnostic_settings : local.genai_app_configuration_diagnostic_settings_inner) : {}
  genai_app_configuration_diagnostic_settings_inner = ((try(var.law_definition.deploy, false) == true) ? {
    sendToLogAnalytics = {
      name                                     = "sendToLogAnalytics-genai-appconfig-${random_string.name_suffix.result}"
      workspace_resource_id                    = local.log_analytics_workspace_id
      log_analytics_destination_type           = "Dedicated"
      log_groups                               = ["allLogs"]
      metric_categories                        = ["AllMetrics"]
      log_categories                           = []
      storage_account_resource_id              = null
      event_hub_authorization_rule_resource_id = null
      event_hub_name                           = null
      marketplace_partner_resource_id          = null
    }
  } : {})
  genai_app_configuration_name = try(var.genai_app_configuration_definition.name, null) != null ? var.genai_app_configuration_definition.name : (var.name_prefix != null ? "${var.name_prefix}-genai-appconfig-${random_string.name_suffix.result}" : "genai-appconfig-${random_string.name_suffix.result}")
  genai_app_configuration_role_assignments = merge(
    local.genai_app_configuration_default_role_assignments,
    var.genai_app_configuration_definition.role_assignments
  )
  genai_container_registry_default_role_assignments = {}
  genai_container_registry_diagnostic_settings      = var.genai_container_registry_definition.enable_diagnostic_settings ? (length(var.genai_container_registry_definition.diagnostic_settings) > 0 ? var.genai_container_registry_definition.diagnostic_settings : local.genai_container_registry_diagnostic_settings_inner) : {}
  genai_container_registry_diagnostic_settings_inner = ((try(var.law_definition.deploy, false) == true) ? {
    sendToLogAnalytics = {
      name                                     = "sendToLogAnalytics-genai-acr-${random_string.name_suffix.result}"
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
  genai_container_registry_name = try(var.genai_container_registry_definition.name, null) != null ? var.genai_container_registry_definition.name : (var.name_prefix != null ? "${var.name_prefix}genaicr${random_string.name_suffix.result}" : "genaicr${random_string.name_suffix.result}")
  genai_container_registry_role_assignments = merge(
    local.genai_container_registry_default_role_assignments,
    var.genai_container_registry_definition.role_assignments
  )
  genai_cosmosdb_diagnostic_settings = var.genai_cosmosdb_definition.enable_diagnostic_settings ? (length(var.genai_cosmosdb_definition.diagnostic_settings) > 0 ? var.genai_cosmosdb_definition.diagnostic_settings : local.genai_cosmosdb_diagnostic_settings_inner) : {}
  genai_cosmosdb_diagnostic_settings_inner = ((try(var.law_definition.deploy, false) == true) ? {
    sendToLogAnalytics = {
      name                                     = "sendToLogAnalytics-genai-cosmosdb-${random_string.name_suffix.result}"
      workspace_resource_id                    = local.log_analytics_workspace_id
      log_analytics_destination_type           = "Dedicated"
      log_groups                               = ["allLogs"]
      metric_categories                        = ["SLI", "Requests"]
      log_categories                           = []
      storage_account_resource_id              = null
      event_hub_authorization_rule_resource_id = null
      event_hub_name                           = null
      marketplace_partner_resource_id          = null
    }
  } : {})
  genai_cosmosdb_name = try(var.genai_cosmosdb_definition.name, null) != null ? var.genai_cosmosdb_definition.name : (var.name_prefix != null ? "${var.name_prefix}-genai-cosmosdb-${random_string.name_suffix.result}" : "genai-cosmosdb-${random_string.name_suffix.result}")
  # Handle secondary regions logic:
  # - If null, set to empty list
  # - If empty list, set to paired region details(default?)
  # - Otherwise, use the provided list
  genai_cosmosdb_secondary_regions = var.genai_cosmosdb_definition.secondary_regions == null ? [] : (
    try(length(var.genai_cosmosdb_definition.secondary_regions) == 0, false) ? [
      {
        location          = local.paired_region
        zone_redundant    = false #length(local.paired_region_zones) > 1 ? true : false TODO: set this back to dynamic based on region zone availability after testing. Our subs don't have quota for zonal deployments.
        failover_priority = 1
      },
      {
        location          = azurerm_resource_group.this.location
        zone_redundant    = false #length(local.region_zones) > 1 ? true : false
        failover_priority = 0
      }
    ] : var.genai_cosmosdb_definition.secondary_regions
  )
  genai_key_vault_default_role_assignments = {
  }
  genai_key_vault_diagnostic_settings = var.genai_key_vault_definition.enable_diagnostic_settings ? (length(var.genai_key_vault_definition.diagnostic_settings) > 0 ? var.genai_key_vault_definition.diagnostic_settings : local.genai_key_vault_diagnostic_settings_inner) : {}
  genai_key_vault_diagnostic_settings_inner = ((try(var.law_definition.deploy, false) == true) ? {
    sendToLogAnalytics = {
      name                                     = "sendToLogAnalytics-genai-kv-${random_string.name_suffix.result}"
      workspace_resource_id                    = local.log_analytics_workspace_id
      log_analytics_destination_type           = "Dedicated"
      log_groups                               = ["allLogs"]
      metric_categories                        = ["AllMetrics"]
      log_categories                           = []
      storage_account_resource_id              = null
      event_hub_authorization_rule_resource_id = null
      event_hub_name                           = null
      marketplace_partner_resource_id          = null
    }
  } : {})
  genai_key_vault_name = try(var.genai_key_vault_definition.name, null) != null ? var.genai_key_vault_definition.name : (var.name_prefix != null ? "${var.name_prefix}-genai-kv-${random_string.name_suffix.result}" : "genai-kv-${random_string.name_suffix.result}")
  genai_key_vault_role_assignments = merge(
    local.genai_key_vault_default_role_assignments,
    var.genai_key_vault_definition.role_assignments
  )
  genai_storage_account_default_role_assignments = {
  }
  genai_storage_account_diagnostic_settings = var.genai_storage_account_definition.enable_diagnostic_settings ? (length(var.genai_storage_account_definition.diagnostic_settings) > 0 ? var.genai_storage_account_definition.diagnostic_settings : local.genai_storage_account_diagnostic_settings_inner) : {}
  genai_storage_account_diagnostic_settings_inner = ((try(var.law_definition.deploy, false) == true) ? {
    sendToLogAnalytics = {
      name                                     = "sendToLogAnalytics-genai-sa-${random_string.name_suffix.result}"
      workspace_resource_id                    = local.log_analytics_workspace_id
      log_analytics_destination_type           = "Dedicated"
      log_groups                               = ["allLogs"]
      metric_categories                        = ["Capacity", "Transaction"]
      log_categories                           = []
      storage_account_resource_id              = null
      event_hub_authorization_rule_resource_id = null
      event_hub_name                           = null
      marketplace_partner_resource_id          = null
    }
  } : {})
  genai_storage_account_name = try(var.genai_storage_account_definition.name, null) != null ? var.genai_storage_account_definition.name : (var.name_prefix != null ? "${var.name_prefix}genaisa${random_string.name_suffix.result}" : "genaisa${random_string.name_suffix.result}")
  genai_storage_account_role_assignments = merge(
    local.genai_storage_account_default_role_assignments,
    var.genai_storage_account_definition.role_assignments
  )
}
