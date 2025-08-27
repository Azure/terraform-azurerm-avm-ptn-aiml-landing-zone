locals {
  genai_app_configuration_default_role_assignments = {}
  genai_app_configuration_name                     = try(var.genai_app_configuration_definition.name, null) != null ? var.genai_app_configuration_definition.name : (var.name_prefix != null ? "${var.name_prefix}-genai-appconfig-${random_string.name_suffix.result}" : "genai-appconfig-${random_string.name_suffix.result}")
  genai_app_configuration_role_assignments = merge(
    local.genai_app_configuration_default_role_assignments,
    var.genai_app_configuration_definition.role_assignments
  )
  genai_container_registry_default_role_assignments = {}
  genai_container_registry_name                     = try(var.genai_container_registry_definition.name, null) != null ? var.genai_container_registry_definition.name : (var.name_prefix != null ? "${var.name_prefix}genaicr${random_string.name_suffix.result}" : "genaicr${random_string.name_suffix.result}")
  genai_container_registry_role_assignments = merge(
    local.genai_container_registry_default_role_assignments,
    var.genai_container_registry_definition.role_assignments
  )
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
  genai_key_vault_name = try(var.genai_key_vault_definition.name, null) != null ? var.genai_key_vault_definition.name : (var.name_prefix != null ? "${var.name_prefix}-genai-kv-${random_string.name_suffix.result}" : "genai-kv-${random_string.name_suffix.result}")
  genai_key_vault_role_assignments = merge(
    local.genai_key_vault_default_role_assignments,
    var.genai_key_vault_definition.role_assignments
  )
  genai_storage_account_default_role_assignments = {
  }
  genai_storage_account_name = try(var.genai_storage_account_definition.name, null) != null ? var.genai_storage_account_definition.name : (var.name_prefix != null ? "${var.name_prefix}genaisa${random_string.name_suffix.result}" : "genaisa${random_string.name_suffix.result}")
  genai_storage_account_role_assignments = merge(
    local.genai_storage_account_default_role_assignments,
    var.genai_storage_account_definition.role_assignments
  )
}
