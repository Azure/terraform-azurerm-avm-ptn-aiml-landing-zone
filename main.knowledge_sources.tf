module "search_service" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.1.5"


  location            = azurerm_resource_group.this.location
  name                = local.ks_ai_search_name
  resource_group_name = azurerm_resource_group.this.name
  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = [module.private_dns_zones.ai_search_zone.resource_id]
      subnet_resource_id            = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
    }
  }

  sku                           = var.ks_ai_search_definition.sku
  public_network_access_enabled = var.ks_ai_search_definition.public_network_access_enabled
  local_authentication_enabled  = var.ks_ai_search_definition.local_authentication_enabled
  semantic_search_sku           = var.ks_ai_search_definition.semantic_search_sku
  replica_count                 = var.ks_ai_search_definition.replica_count
  partition_count               = var.ks_ai_search_definition.partition_count
  diagnostic_settings = {
    storage = {
      name                  = "sendToLogAnalytics"
      workspace_resource_id = var.law_definition.resource_id != null ? var.law_definition.resource_id : module.log_analytics_workspace[0].resource_id
    }
  }

  enable_telemetry = var.enable_telemetry # see variables.tf


}
