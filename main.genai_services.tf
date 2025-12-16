module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "=0.10.2"

  location            = azurerm_resource_group.this.location
  name                = local.genai_key_vault_name
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = var.genai_key_vault_definition.tenant_id != null ? var.genai_key_vault_definition.tenant_id : data.azurerm_client_config.current.tenant_id
  diagnostic_settings = local.deploy_diagnostics_settings ? {
    to_law = {
      name                  = "sendToLogAnalytics-kv-${random_string.name_suffix.result}"
      workspace_resource_id = local.log_analytics_workspace_id
    }
  } : null
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  network_acls                    = var.genai_key_vault_definition.network_acls
  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = var.flag_platform_landing_zone ? [module.private_dns_zones.key_vault_zone.resource_id] : [local.private_dns_zones_existing.key_vault_zone.resource_id]
      subnet_resource_id            = local.subnet_ids["PrivateEndpointSubnet"]
    }
  }
  public_network_access_enabled = var.genai_key_vault_definition.public_network_access_enabled
  role_assignments              = local.genai_key_vault_role_assignments
  tags                          = var.genai_key_vault_definition.tags
  wait_for_rbac_before_key_operations = {
    create = "60s"
  }
  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }

  depends_on = [module.private_dns_zones, module.hub_vnet_peering]
}

#moving this outside of the KV AVM module so I can set an implicit dependency from the jump vm module to order deletion properly.
#TODO: Review if this permission is too permissive.  Can this be Secrets User instead?
resource "azurerm_role_assignment" "deployment_user_kv_admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = module.avm_res_keyvault_vault.resource_id
  role_definition_name = "Key Vault Administrator"
}

#TODO:
# validate the defaults for the cosmosdb module
# create private endpoint config
module "cosmosdb" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.10.0"
  count   = var.genai_cosmosdb_definition.deploy ? 1 : 0

  location                   = azurerm_resource_group.this.location
  name                       = local.genai_cosmosdb_name
  resource_group_name        = azurerm_resource_group.this.name
  analytical_storage_config  = var.genai_cosmosdb_definition.analytical_storage_config
  analytical_storage_enabled = var.genai_cosmosdb_definition.analytical_storage_enabled
  automatic_failover_enabled = var.genai_cosmosdb_definition.automatic_failover_enabled
  capacity = {
    total_throughput_limit = var.genai_cosmosdb_definition.capacity.total_throughput_limit
  }
  consistency_policy = {
    consistency_level       = var.genai_cosmosdb_definition.consistency_policy.consistency_level
    max_interval_in_seconds = var.genai_cosmosdb_definition.consistency_policy.max_interval_in_seconds
    max_staleness_prefix    = var.genai_cosmosdb_definition.consistency_policy.max_staleness_prefix
  }
  cors_rule = var.genai_cosmosdb_definition.cors_rule
  diagnostic_settings = var.genai_cosmosdb_definition.enable_diagnostic_settings && local.deploy_diagnostics_settings ? {
    to_law = {
      name                  = "sendToLogAnalytics-cosmosdb-${random_string.name_suffix.result}"
      workspace_resource_id = local.log_analytics_workspace_id
    }
  } : null
  enable_telemetry = var.enable_telemetry
  geo_locations    = local.genai_cosmosdb_secondary_regions
  ip_range_filter = [
    "168.125.123.255",
    "170.0.0.0/24",                                                                 #TODO: check 0.0.0.0 for validity
    "0.0.0.0",                                                                      #Accept connections from within public Azure datacenters. https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-the-azure-portal
    "104.42.195.92", "40.76.54.131", "52.176.6.30", "52.169.50.45", "52.187.184.26" #Allow access from the Azure portal. https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-global-azure-datacenters-or-other-sources-within-azure
  ]
  local_authentication_disabled         = var.genai_cosmosdb_definition.local_authentication_disabled
  multiple_write_locations_enabled      = var.genai_cosmosdb_definition.multiple_write_locations_enabled
  network_acl_bypass_for_azure_services = true
  partition_merge_enabled               = var.genai_cosmosdb_definition.partition_merge_enabled
  private_endpoints = {
    "sql" = {
      subnet_resource_id            = local.subnet_ids["PrivateEndpointSubnet"]
      subresource_name              = "sql"
      private_dns_zone_resource_ids = var.flag_platform_landing_zone ? [module.private_dns_zones.cosmos_sql_zone.resource_id] : [local.private_dns_zones_existing.cosmos_sql_zone.resource_id]
    }
  }
  public_network_access_enabled = var.genai_cosmosdb_definition.public_network_access_enabled

  depends_on = [module.private_dns_zones, module.hub_vnet_peering]
}


#TODO:
# Implement subservice passthrough in variables and here
# removing for testing PE DNS zone strategy when platform flag is false

module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.6"
  count   = var.genai_storage_account_definition.deploy ? 1 : 0

  location                 = azurerm_resource_group.this.location
  name                     = local.genai_storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  access_tier              = var.genai_storage_account_definition.access_tier
  account_kind             = var.genai_storage_account_definition.account_kind
  account_replication_type = var.genai_storage_account_definition.account_replication_type
  account_tier             = var.genai_storage_account_definition.account_tier
  diagnostic_settings_storage_account = var.genai_storage_account_definition.enable_diagnostic_settings && local.deploy_diagnostics_settings ? {
    storage = {
      name                  = "sendToLogAnalytics-sa-${random_string.name_suffix.result}"
      workspace_resource_id = local.log_analytics_workspace_id
    }
  } : null
  enable_telemetry   = var.enable_telemetry
  local_user_enabled = false
  private_endpoints = {
    for endpoint in var.genai_storage_account_definition.endpoint_types :
    endpoint => {
      name                          = "${local.genai_storage_account_name}-${endpoint}-pe"
      private_dns_zone_resource_ids = var.flag_platform_landing_zone ? [module.private_dns_zones["storage_${lower(endpoint)}_zone"].resource_id] : [local.private_dns_zones_existing["storage_${lower(endpoint)}_zone"].resource_id]
      subnet_resource_id            = local.subnet_ids["PrivateEndpointSubnet"]
      subresource_name              = endpoint
    }
  }
  public_network_access_enabled = var.genai_storage_account_definition.public_network_access_enabled
  role_assignments              = local.genai_storage_account_role_assignments
  shared_access_key_enabled     = var.genai_storage_account_definition.shared_access_key_enabled
  tags                          = var.genai_storage_account_definition.tags

  depends_on = [module.private_dns_zones, module.hub_vnet_peering]
}


module "containerregistry" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.5.0"
  count   = var.genai_container_registry_definition.deploy ? 1 : 0

  location            = azurerm_resource_group.this.location
  name                = local.genai_container_registry_name
  resource_group_name = azurerm_resource_group.this.name
  diagnostic_settings = var.genai_container_registry_definition.enable_diagnostic_settings && local.deploy_diagnostics_settings ? {
    storage = {
      name                  = "sendToLogAnalytics-acr-${random_string.name_suffix.result}"
      workspace_resource_id = local.log_analytics_workspace_id
    }
  } : null
  enable_telemetry = var.enable_telemetry
  private_endpoints = {
    container_registry = {
      private_dns_zone_resource_ids = var.flag_platform_landing_zone ? [module.private_dns_zones.container_registry_zone.resource_id] : [local.private_dns_zones_existing.container_registry_zone.resource_id]
      subnet_resource_id            = local.subnet_ids["PrivateEndpointSubnet"]
    }
  }
  public_network_access_enabled = var.genai_container_registry_definition.public_network_access_enabled
  role_assignments              = local.genai_container_registry_role_assignments
  zone_redundancy_enabled       = length(local.region_zones) > 1 ? var.genai_container_registry_definition.zone_redundancy_enabled : false

  depends_on = [module.private_dns_zones, module.hub_vnet_peering]
}


module "app_configuration" {
  source  = "Azure/avm-res-appconfiguration-configurationstore/azure"
  version = "0.5.1"
  count   = var.genai_app_configuration_definition.deploy ? 1 : 0

  location                        = azurerm_resource_group.this.location
  name                            = local.genai_app_configuration_name
  resource_group_resource_id      = azurerm_resource_group.this.id
  azapi_schema_validation_enabled = false
  enable_telemetry                = var.enable_telemetry
  local_auth_enabled              = var.genai_app_configuration_definition.local_auth_enabled
  private_endpoints = {
    app_configuration = {
      private_dns_zone_resource_ids = var.flag_platform_landing_zone ? [module.private_dns_zones.app_configuration_zone.resource_id] : [local.private_dns_zones_existing.app_configuration_zone.resource_id]
      subnet_resource_id            = local.subnet_ids["PrivateEndpointSubnet"]
    }
  }
  role_assignments           = local.genai_app_configuration_role_assignments
  sku                        = var.genai_app_configuration_definition.sku
  soft_delete_retention_days = var.genai_app_configuration_definition.soft_delete_retention_in_days
  tags                       = var.genai_app_configuration_definition.tags
}

