module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "=0.10.0"
  count   = var.flag_standalone.deploy_build_resources ? 0 : 1

  location            = azurerm_resource_group.this.location
  name                = local.genai_key_vault_name
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = var.genai_key_vault_definition.tenant_id != null ? var.genai_key_vault_definition.tenant_id : data.azurerm_client_config.current.tenant_id
  diagnostic_settings = {
    to_law = {
      name                  = "sendToLogAnalytics-kv-${random_string.name_suffix.result}"
      workspace_resource_id = var.law_definition.resource_id != null ? var.law_definition.resource_id : module.log_analytics_workspace[0].resource_id
    }
  }
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  network_acls = { #TODO check to see if we need to support custom network ACLs
    default_action = "Allow"
    bypass         = "AzureServices"
  }
  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = var.flag_platform_landing_zone ? [module.private_dns_zones.key_vault_zone.resource_id] : [local.private_dns_zones_existing.key_vault_zone.resource_id]
      subnet_resource_id            = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
    }
  }
  public_network_access_enabled = false
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

#TODO:
# validate the defaults for the cosmosdb module
# create private endpoint config
module "cosmosdb" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.8.0"
  count   = var.flag_standalone.deploy_build_resources ? 0 : 1

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
  diagnostic_settings = {
    to_law = {
      name                  = "sendToLogAnalytics-cosmosdb-${random_string.name_suffix.result}"
      workspace_resource_id = var.law_definition.resource_id != null ? var.law_definition.resource_id : module.log_analytics_workspace[0].resource_id
    }
  }
  enable_telemetry                 = var.enable_telemetry
  geo_locations                    = local.genai_cosmosdb_secondary_regions
  local_authentication_disabled    = var.genai_cosmosdb_definition.local_authentication_disabled
  multiple_write_locations_enabled = var.genai_cosmosdb_definition.multiple_write_locations_enabled
  partition_merge_enabled          = var.genai_cosmosdb_definition.partition_merge_enabled
  public_network_access_enabled    = var.genai_cosmosdb_definition.public_network_access_enabled

  depends_on = [module.private_dns_zones, module.hub_vnet_peering]
}


#TODO:
# Implement subservice passthrough in variables and here
# removing for testing PE DNS zone strategy when platform flag is false

module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.3"
  count   = var.flag_standalone.deploy_build_resources ? 0 : 1

  location                 = azurerm_resource_group.this.location
  name                     = local.genai_storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  access_tier              = var.genai_storage_account_definition.access_tier
  account_kind             = var.genai_storage_account_definition.account_kind
  account_replication_type = var.genai_storage_account_definition.account_replication_type
  account_tier             = var.genai_storage_account_definition.account_tier
  diagnostic_settings_storage_account = {
    storage = {
      name                  = "sendToLogAnalytics-sa-${random_string.name_suffix.result}"
      workspace_resource_id = var.law_definition.resource_id != null ? var.law_definition.resource_id : module.log_analytics_workspace[0].resource_id
    }
  }
  enable_telemetry = var.enable_telemetry
  private_endpoints = {
    for endpoint in var.genai_storage_account_definition.endpoint_types :
    endpoint => {
      name                          = "${local.genai_storage_account_name}-${endpoint}-pe"
      private_dns_zone_resource_ids = var.flag_platform_landing_zone ? [module.private_dns_zones["storage_${lower(endpoint)}_zone"].resource_id] : [local.private_dns_zones_existing["storage_${lower(endpoint)}_zone"].resource_id]
      subnet_resource_id            = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
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
  version = "0.4.0"
  count   = var.flag_standalone.deploy_build_resources ? 0 : 1

  location            = azurerm_resource_group.this.location
  name                = local.genai_container_registry_name
  resource_group_name = azurerm_resource_group.this.name
  diagnostic_settings = {
    storage = {
      name                  = "sendToLogAnalytics-acr-${random_string.name_suffix.result}"
      workspace_resource_id = var.law_definition.resource_id != null ? var.law_definition.resource_id : module.log_analytics_workspace[0].resource_id
    }
  }
  enable_telemetry = var.enable_telemetry
  private_endpoints = {
    container_registry = {
      private_dns_zone_resource_ids = var.flag_platform_landing_zone ? [module.private_dns_zones.container_registry_zone.resource_id] : [local.private_dns_zones_existing.container_registry_zone.resource_id]
      subnet_resource_id            = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
    }
  }
  public_network_access_enabled = var.genai_container_registry_definition.public_network_access_enabled
  role_assignments              = local.genai_container_registry_role_assignments
  zone_redundancy_enabled       = length(local.region_zones) > 1 ? var.genai_container_registry_definition.zone_redundancy_enabled : false

  depends_on = [module.private_dns_zones, module.hub_vnet_peering]
}


module "app_configuration" {
  source  = "Azure/avm-res-appconfiguration-configurationstore/azure"
  version = "0.4.1"
  count   = var.flag_standalone.deploy_build_resources ? 0 : 1

  location                        = azurerm_resource_group.this.location
  name                            = local.genai_app_configuration_name
  resource_group_resource_id      = azurerm_resource_group.this.id
  azapi_schema_validation_enabled = false
  enable_telemetry                = var.enable_telemetry
  local_auth_enabled              = var.genai_app_configuration_definition.local_auth_enabled
  private_endpoints = {
    app_configuration = {
      private_dns_zone_resource_ids = var.flag_platform_landing_zone ? [module.private_dns_zones.app_configuration_zone.resource_id] : [local.private_dns_zones_existing.app_configuration_zone.resource_id]
      subnet_resource_id            = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
    }
  }
  role_assignments           = local.genai_app_configuration_role_assignments
  sku                        = var.genai_app_configuration_definition.sku
  soft_delete_retention_days = var.genai_app_configuration_definition.soft_delete_retention_in_days
  tags                       = var.genai_app_configuration_definition.tags
}

