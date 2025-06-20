

module "ai_lz_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.7.1"

  address_space       = [var.vnet_definition.address_space]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  diagnostic_settings = {
    sendToLogAnalytics = {
      name                           = "sendToLogAnalytics"
      workspace_resource_id          = module.log_analytics_workspace.resource_id
      log_analytics_destination_type = "Dedicated"
    }
  }
  enable_telemetry = var.enable_telemetry
  name             = local.vnet_name
  subnets          = local.deployed_subnets
}

module "firewall_route_table" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.4.1"
  count   = var.flag_platform_landing_zone ? 1 : 0

  location                      = azurerm_resource_group.this.location
  name                          = local.route_table_name
  resource_group_name           = azurerm_resource_group.this.name
  bgp_route_propagation_enabled = true

  routes = {
    azure_firewall = {
      name                   = "default-to-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall[0].resource.ip_configuration[0].private_ip_address
    }
  }
}

module "fw_pip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.0"
  count   = var.flag_platform_landing_zone ? 1 : 0

  location            = azurerm_resource_group.this.location
  name                = "${local.firewall_name}-pip"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  zones               = var.firewall_definition.zones
}

module "firewall" {
  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = "0.3.0"
  count   = var.flag_platform_landing_zone ? 1 : 0

  firewall_sku_name   = var.firewall_definition.sku
  firewall_sku_tier   = var.firewall_definition.tier
  location            = azurerm_resource_group.this.location
  name                = local.firewall_name
  resource_group_name = azurerm_resource_group.this.name
  diagnostic_settings = {
    to_law = {
      name                  = "sendToLogAnalytics"
      workspace_resource_id = module.log_analytics_workspace.resource_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  }
  enable_telemetry = var.enable_telemetry
  firewall_ip_configuration = [
    {
      name                 = "${local.firewall_name}-ipconfig1"
      subnet_id            = module.ai_lz_vnet.subnets["AzureFirewallSubnet"].resource_id
      public_ip_address_id = module.fw_pip[0].resource_id
    }
  ]
  firewall_zones = var.firewall_definition.zones
}

module "firewall_policy" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "0.3.3"
  count   = var.flag_platform_landing_zone ? 1 : 0

  location            = azurerm_resource_group.this.location
  name                = "${local.firewall_name}-policy"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
}

module "azure_bastion" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "0.7.2"

  location            = azurerm_resource_group.this.location
  name                = local.bastion_name
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  ip_configuration = {
    subnet_id = module.ai_lz_vnet.subnets["AzureBastionSubnet"].resource_id
  }
  sku   = var.bastion_definition.sku
  tags  = var.bastion_definition.tags
  zones = var.bastion_definition.zones
}

#TODO: priavate DNS zone

#TODO: App Gateway w WAF. (What is in the backend pool?
