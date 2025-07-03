/*
module "apim" {
  source  = "Azure/avm-res-apimanagement-service/azurerm"
  version = "0.0.2"

  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  name                          = local.apim_name
  publisher_email               = var.apim_definition.publisher_email
  zones                         = local.region_zones
  public_network_access_enabled = true
  virtual_network_type          = "Internal"
  virtual_network_subnet_id     = module.ai_lz_vnet.subnets["ApiManagementSubnet"].resource_id

  enable_telemetry           = var.enable_telemetry
  additional_location        = var.apim_definition.additional_locations
  certificate                = var.apim_definition.certificate
  client_certificate_enabled = var.apim_definition.client_certificate_enabled
  hostname_configuration     = var.apim_definition.hostname_configuration
  min_api_version            = var.apim_definition.min_api_version
  notification_sender_email  = var.apim_definition.notification_sender_email
  protocols                  = var.apim_definition.protocols
  publisher_name             = var.apim_definition.publisher_name
  sign_in                    = var.apim_definition.sign_in
  sign_up                    = var.apim_definition.sign_up
  sku_name                   = "${var.apim_definition.sku_root}_${var.apim_definition.sku_capacity}"
  tenant_access              = var.apim_definition.tenant_access
  tags                       = var.apim_definition.tags

  diagnostic_settings = {
    storage = {
      name                  = "sendToLogAnalytics-${random_string.name_suffix.result}"
      workspace_resource_id = var.law_definition.resource_id != null ? var.law_definition.resource_id : module.log_analytics_workspace[0].resource_id
    }
  }

  private_endpoints = {
    endpoint1 = {
      private_dns_zone_resource_ids = var.flag_platform_landing_zone ? [module.private_dns_zones.apim_zone.resource_id] : [local.private_dns_zones_existing.apim_zone.resource_id]
      subnet_resource_id            = module.ai_lz_vnet.subnets["PrivateEndpointSubnet"].resource_id
    }
  }

  role_assignments = local.apim_role_assignments

}
*/
