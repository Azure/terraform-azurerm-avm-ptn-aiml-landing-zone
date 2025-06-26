module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "=0.10.0"

  location                        = azurerm_resource_group.this.location
  name                            = local.genai_key_vault_name
  resource_group_name             = azurerm_resource_group.this.name
  tenant_id                       = var.genai_key_vault_definition.tenant_id != null ? var.genai_key_vault_definition.tenant_id : data.azurerm_client_config.current.tenant_id
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  public_network_access_enabled   = false

  network_acls = { #TODO check to see if we need to support custom network ACLs
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  role_assignments = local.genai_key_vault_role_assignments
  tags             = var.genai_key_vault_definition.tags

  diagnostic_settings = {
    to_law = {
      name                  = "sendToLogAnalytics"
      workspace_resource_id = var.law_definition.resource_id != null ? var.law_definition.resource_id : module.log_analytics_workspace[0].resource_id
    }
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }

  wait_for_rbac_before_key_operations = {
    create = "60s"
  }



  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = [module.private_dns_zones.key_vault_zone.resource_id]
      subnet_resource_id            = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
    }
  }

  depends_on = [module.private_dns_zones, module.hub_vnet_peering]
}

/*
# The PE resource for the key vault.  Separating it from the module to allow for the vm module to write secrets during deployment.
resource "azurerm_private_endpoint" "this" {
  for_each = { for k, v in var.private_endpoints : k => v if var.private_endpoints_manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pe-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = "default"
      subresource_name   = "vault"
    }
  }
  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }
}


#TODO:
# validate the defaults for the cosmosdb module
# create private endpoint config
module "cosmosdb" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.8.0"

  resource_group_name              = azurerm_resource_group.this.name
  location                         = azurerm_resource_group.this.location
  name                             = local.genai_cosmosdb_name
  public_network_access_enabled    = var.genai_cosmosdb_definition.public_network_access_enabled
  enable_telemetry                 = var.enable_telemetry
  analytical_storage_enabled       = var.genai_cosmosdb_definition.analytical_storage_enabled
  automatic_failover_enabled       = var.genai_cosmosdb_definition.automatic_failover_enabled
  local_authentication_disabled    = var.genai_cosmosdb_definition.local_authentication_disabled
  partition_merge_enabled          = var.genai_cosmosdb_definition.partition_merge_enabled
  multiple_write_locations_enabled = var.genai_cosmosdb_definition.multiple_write_locations_enabled

  diagnostic_settings = {
    to_law = {
      name                  = "sendToLogAnalytics"
      workspace_resource_id = var.law_definition.resource_id != null ? var.law_definition.resource_id : module.log_analytics_workspace[0].resource_id
    }
  }

  capacity = {
    total_throughput_limit = var.genai_cosmosdb_definition.capacity.total_throughput_limit
  }

  cors_rule = var.genai_cosmosdb_definition.cors_rule

  consistency_policy = {
    consistency_level       = var.genai_cosmosdb_definition.consistency_policy.consistency_level
    max_interval_in_seconds = var.genai_cosmosdb_definition.consistency_policy.max_interval_in_seconds
    max_staleness_prefix    = var.genai_cosmosdb_definition.consistency_policy.max_staleness_prefix
  }

  #backup = null#var.genai_cosmosdb_definition.backup

  geo_locations = local.genai_cosmosdb_secondary_regions

  analytical_storage_config = var.genai_cosmosdb_definition.analytical_storage_config
}
*/

#TODO:
# Implement subservice passthrough in variables and here
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.3"

  location                      = azurerm_resource_group.this.location
  name                          = local.genai_storage_account_name
  resource_group_name           = azurerm_resource_group.this.name
  shared_access_key_enabled     = var.genai_storage_account_definition.shared_access_key_enabled
  public_network_access_enabled = var.genai_storage_account_definition.public_network_access_enabled
  account_kind                  = var.genai_storage_account_definition.account_kind
  account_tier                  = var.genai_storage_account_definition.account_tier
  account_replication_type      = var.genai_storage_account_definition.account_replication_type
  access_tier                   = var.genai_storage_account_definition.access_tier
  enable_telemetry              = var.enable_telemetry

  private_endpoints = {
    for endpoint in var.genai_storage_account_definition.endpoint_types :
    endpoint => {
      name                          = "${local.genai_storage_account_name}-${endpoint}-pe"
      private_dns_zone_resource_ids = [module.private_dns_zones["storage_${lower(endpoint)}_zone"].resource_id]
      subnet_resource_id            = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
      subresource_name              = endpoint
    }
  }

  diagnostic_settings_storage_account = {
    storage = {
      name                  = "sendToLogAnalytics"
      workspace_resource_id = var.law_definition.resource_id != null ? var.law_definition.resource_id : module.log_analytics_workspace[0].resource_id
    }
  }

  role_assignments = local.genai_storage_account_role_assignments

  tags = var.genai_storage_account_definition.tags

  depends_on = [module.private_dns_zones, module.hub_vnet_peering]

}

module "containerregistry" {
  source                        = "Azure/avm-res-containerregistry-registry/azurerm"
  version                       = "0.4.0"
  enable_telemetry              = var.enable_telemetry
  name                          = local.genai_container_registry_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  public_network_access_enabled = var.genai_container_registry_definition.public_network_access_enabled
  zone_redundancy_enabled       = length(local.region_zones) > 1 ? var.genai_container_registry_definition.zone_redundancy_enabled : false

  private_endpoints = {
    container_registry = {
      private_dns_zone_resource_ids = [module.private_dns_zones.container_registry_zone.resource_id]
      subnet_resource_id            = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
    }
  }

  diagnostic_settings = {
    storage = {
      name                  = "sendToLogAnalytics"
      workspace_resource_id = var.law_definition.resource_id != null ? var.law_definition.resource_id : module.log_analytics_workspace[0].resource_id
    }
  }

  role_assignments = local.genai_container_registry_role_assignments

  depends_on = [module.private_dns_zones, module.hub_vnet_peering]

}
