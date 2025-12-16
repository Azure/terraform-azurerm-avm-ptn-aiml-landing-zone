

module "ai_lz_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.16.0"
  count   = length(var.vnet_definition.existing_byo_vnet) > 0 ? 0 : 1

  location      = azurerm_resource_group.this.location
  parent_id     = azurerm_resource_group.this.id
  address_space = var.vnet_definition.ipam_pools == null ? [var.vnet_definition.address_space] : null
  ddos_protection_plan = var.vnet_definition.ddos_protection_plan_resource_id != null ? {
    id     = var.vnet_definition.ddos_protection_plan_resource_id
    enable = true
  } : null
  diagnostic_settings = local.deploy_diagnostics_settings ? {
    sendToLogAnalytics = {
      name                           = "sendToLogAnalytics-vnet-${random_string.name_suffix.result}"
      workspace_resource_id          = local.log_analytics_workspace_id
      log_analytics_destination_type = "Dedicated"
    }
  } : null
  dns_servers = {
    dns_servers = var.vnet_definition.dns_servers
  }
  enable_telemetry = var.enable_telemetry
  ipam_pools       = var.vnet_definition.ipam_pools
  name             = local.vnet_name
  subnets          = local.deployed_subnets
}

data "azurerm_virtual_network" "ai_lz_vnet" {
  count = length(var.vnet_definition.existing_byo_vnet) > 0 ? 1 : 0

  name                = try(basename(values(var.vnet_definition.existing_byo_vnet)[0].vnet_resource_id), "")
  resource_group_name = split("/", try(values(var.vnet_definition.existing_byo_vnet)[0].vnet_resource_id, "/n/o/t/u/s/e/d"))[4]
}

module "byo_subnets" {
  source   = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"
  version  = "0.16.0"
  for_each = { for k, v in local.deployed_subnets : k => v if length(var.vnet_definition.existing_byo_vnet) > 0 }

  # Direct VNet resource id (module not instantiated when BYO is null due to empty for_each)
  parent_id              = values(var.vnet_definition.existing_byo_vnet)[0].vnet_resource_id
  address_prefixes       = each.value.ipam_pools == null ? each.value.address_prefixes : null
  delegations            = try(each.value.delegations, try(each.value.delegation, null), null)
  ipam_pools             = each.value.ipam_pools
  name                   = each.value.name
  network_security_group = try(each.value.network_security_group, null)
  route_table            = try(each.value.route_table, null)
}

module "nsgs" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  location            = azurerm_resource_group.this.location
  name                = local.nsg_name
  resource_group_name = var.nsgs_definition.resource_group_name != null ? var.nsgs_definition.resource_group_name : azurerm_resource_group.this.name
}

# NSGs are required during subnet creation but rules use cidrs which are not known until after vnet creation.
# Therefore, NSG rules are created in a separate resource after the VNet and subnets are created.
resource "azurerm_network_security_rule" "this" {
  for_each = local.nsg_rules

  access                                     = each.value.access
  direction                                  = each.value.direction
  name                                       = each.value.name
  network_security_group_name                = module.nsgs.resource.name
  priority                                   = each.value.priority
  protocol                                   = each.value.protocol
  resource_group_name                        = module.nsgs.resource.resource_group_name
  description                                = try(each.value.description, null)
  destination_address_prefix                 = try(each.value.destination_address_prefix, null)
  destination_address_prefixes               = try(each.value.destination_address_prefixes, null)
  destination_application_security_group_ids = try(each.value.destination_application_security_group_ids, null)
  destination_port_range                     = try(each.value.destination_port_range, null)
  destination_port_ranges                    = try(each.value.destination_port_ranges, null)
  source_address_prefix                      = try(each.value.source_address_prefix, null)
  source_address_prefixes                    = try(each.value.source_address_prefixes, null)
  source_application_security_group_ids      = try(each.value.source_application_security_group_ids, null)
  source_port_range                          = try(each.value.source_port_range, null)
  source_port_ranges                         = try(each.value.source_port_ranges, null)

  dynamic "timeouts" {
    for_each = try(each.value.timeouts, null) == null ? [] : [each.value.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

#TODO: Add the platform landing zone flag as a secondary decision point for the hub vnet peering?
module "hub_vnet_peering" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"
  version = "0.16.0"
  count   = length(var.vnet_definition.existing_byo_vnet) == 0 && try(var.vnet_definition.vnet_peering_configuration.peer_vnet_resource_id, null) != null ? 1 : 0

  parent_id                            = local.vnet_resource_id
  allow_forwarded_traffic              = var.vnet_definition.vnet_peering_configuration.allow_forwarded_traffic
  allow_gateway_transit                = var.vnet_definition.vnet_peering_configuration.allow_gateway_transit
  allow_virtual_network_access         = var.vnet_definition.vnet_peering_configuration.allow_virtual_network_access
  create_reverse_peering               = var.vnet_definition.vnet_peering_configuration.create_reverse_peering
  name                                 = var.vnet_definition.vnet_peering_configuration.name != null ? var.vnet_definition.vnet_peering_configuration.name : "${local.vnet_name}-local-to-remote"
  remote_virtual_network_id            = var.vnet_definition.vnet_peering_configuration.peer_vnet_resource_id
  reverse_allow_forwarded_traffic      = var.vnet_definition.vnet_peering_configuration.reverse_allow_forwarded_traffic
  reverse_allow_gateway_transit        = var.vnet_definition.vnet_peering_configuration.reverse_allow_gateway_transit
  reverse_allow_virtual_network_access = var.vnet_definition.vnet_peering_configuration.reverse_allow_virtual_network_access
  reverse_name                         = var.vnet_definition.vnet_peering_configuration.reverse_name != null ? var.vnet_definition.vnet_peering_configuration.reverse_name : "${local.vnet_name}-remote-to-local"
  reverse_use_remote_gateways          = var.vnet_definition.vnet_peering_configuration.reverse_use_remote_gateways
  use_remote_gateways                  = var.vnet_definition.vnet_peering_configuration.use_remote_gateways
}

#TODO: Add the platform landing zone flag as a secondary decision point for the vwan connection?
#peer_vwan_hub_resource_id
resource "azurerm_virtual_hub_connection" "this" {
  count = length(var.vnet_definition.existing_byo_vnet) == 0 && try(var.vnet_definition.vwan_hub_peering_configuration.peer_vwan_hub_resource_id, null) != null ? 1 : 0

  name                      = "${local.vnet_name}-to-${basename(var.vnet_definition.vwan_hub_peering_configuration.peer_vwan_hub_resource_id)}"
  remote_virtual_network_id = local.vnet_resource_id
  virtual_hub_id            = var.vnet_definition.vwan_hub_peering_configuration.peer_vwan_hub_resource_id
}

module "firewall_route_table" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.4.1"
  count = ((var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) == 0) ||
  (var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) > 0 && try(values(var.vnet_definition.existing_byo_vnet)[0].firewall_ip_address, null) != null)) ? 1 : 0

  location                      = azurerm_resource_group.this.location
  name                          = local.route_table_name
  resource_group_name           = var.firewall_definition.resource_group_name != null ? var.firewall_definition.resource_group_name : azurerm_resource_group.this.name
  bgp_route_propagation_enabled = true
  routes = var.use_internet_routing ? {
    internet_route = {
      name           = "default-to-internet"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
    } : {
    azure_firewall = {
      name                   = "default-to-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = length(var.vnet_definition.existing_byo_vnet) == 0 ? module.firewall[0].resource.ip_configuration[0].private_ip_address : values(var.vnet_definition.existing_byo_vnet)[0].firewall_ip_address
    }
  }
}

module "fw_pip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.0"
  count   = var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) == 0 ? 1 : 0

  location            = azurerm_resource_group.this.location
  name                = "${local.firewall_name}-pip"
  resource_group_name = var.firewall_definition.resource_group_name != null ? var.firewall_definition.resource_group_name : azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  zones               = var.firewall_definition.zones
}

module "firewall" {
  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = "0.4.0"
  count   = var.flag_platform_landing_zone && var.firewall_definition.deploy && length(var.vnet_definition.existing_byo_vnet) == 0 ? 1 : 0

  firewall_sku_name   = var.firewall_definition.sku
  firewall_sku_tier   = var.firewall_definition.tier
  location            = azurerm_resource_group.this.location
  name                = local.firewall_name
  resource_group_name = var.firewall_definition.resource_group_name != null ? var.firewall_definition.resource_group_name : azurerm_resource_group.this.name
  diagnostic_settings = local.deploy_diagnostics_settings ? {
    to_law = {
      name                  = "sendToLogAnalytics-fwpip-${random_string.name_suffix.result}"
      workspace_resource_id = local.log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : null
  enable_telemetry = var.enable_telemetry
  firewall_ip_configuration = [
    {
      name                 = "${local.firewall_name}-ipconfig1"
      subnet_id            = local.subnet_ids["AzureFirewallSubnet"]
      public_ip_address_id = module.fw_pip[0].resource_id
    }
  ]
  firewall_zones = var.firewall_definition.zones
}

module "firewall_policy" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "0.3.3"
  count   = var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) == 0 ? 1 : 0

  location            = azurerm_resource_group.this.location
  name                = "${local.firewall_name}-policy"
  resource_group_name = var.firewall_policy_definition.resource_group_name != null ? var.firewall_policy_definition.resource_group_name : azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
}

#TODO: add application rule collection support
module "firewall_network_rule_collection_group" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  version = "0.3.3"
  count   = var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) == 0 ? 1 : 0

  firewall_policy_rule_collection_group_firewall_policy_id      = module.firewall_policy[0].resource_id
  firewall_policy_rule_collection_group_name                    = local.firewall_policy_rule_collection_group_name
  firewall_policy_rule_collection_group_network_rule_collection = local.firewall_policy_rule_collection_group_network_rule_collection
  firewall_policy_rule_collection_group_priority                = local.firewall_policy_rule_collection_group_priority
}


module "azure_bastion" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "0.7.2"
  count   = var.flag_platform_landing_zone && var.bastion_definition.deploy ? 1 : 0

  location            = azurerm_resource_group.this.location
  name                = local.bastion_name
  resource_group_name = var.bastion_definition.resource_group_name != null ? var.bastion_definition.resource_group_name : azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  ip_configuration = {
    subnet_id = local.subnet_ids["AzureBastionSubnet"]
  }
  sku   = var.bastion_definition.sku
  tags  = var.bastion_definition.tags
  zones = var.bastion_definition.zones
}

module "private_dns_zones" {
  source   = "Azure/avm-res-network-privatednszone/azurerm"
  version  = "0.4.2"
  for_each = var.flag_platform_landing_zone ? local.private_dns_zones : {}

  domain_name           = each.value.name
  parent_id             = azurerm_resource_group.this.id
  enable_telemetry      = var.enable_telemetry
  virtual_network_links = local.virtual_network_links

  depends_on = [module.hub_vnet_peering]
}

module "app_gateway_waf_policy" {
  source  = "Azure/avm-res-network-applicationgatewaywebapplicationfirewallpolicy/azurerm"
  version = "0.2.0"

  location            = azurerm_resource_group.this.location
  managed_rules       = var.waf_policy_definition.managed_rules #local.web_application_firewall_managed_rules
  name                = local.web_application_firewall_policy_name
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  policy_settings     = var.waf_policy_definition.policy_settings
}


module "application_gateway" {
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "0.4.2"
  count   = var.app_gateway_definition.deploy ? 1 : 0

  backend_address_pools = var.app_gateway_definition.backend_address_pools
  backend_http_settings = var.app_gateway_definition.backend_http_settings
  frontend_ports        = var.app_gateway_definition.frontend_ports
  gateway_ip_configuration = {
    subnet_id = local.subnet_ids["AppGatewaySubnet"]
  }
  http_listeners                     = var.app_gateway_definition.http_listeners
  location                           = azurerm_resource_group.this.location
  name                               = local.application_gateway_name
  request_routing_rules              = var.app_gateway_definition.request_routing_rules
  resource_group_name                = azurerm_resource_group.this.name
  app_gateway_waf_policy_resource_id = module.app_gateway_waf_policy.resource_id
  authentication_certificate         = var.app_gateway_definition.authentication_certificate
  autoscale_configuration            = var.app_gateway_definition.autoscale_configuration
  diagnostic_settings = local.deploy_diagnostics_settings ? {
    to_law = {
      name                  = "sendToLogAnalytics-appgw-${random_string.name_suffix.result}"
      workspace_resource_id = local.log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : null
  enable_telemetry            = var.enable_telemetry
  http2_enable                = var.app_gateway_definition.http2_enable
  probe_configurations        = var.app_gateway_definition.probe_configurations
  public_ip_name              = "${local.application_gateway_name}-pip"
  redirect_configuration      = var.app_gateway_definition.redirect_configuration
  rewrite_rule_set            = var.app_gateway_definition.rewrite_rule_set
  role_assignments            = local.application_gateway_role_assignments
  sku                         = var.app_gateway_definition.sku
  ssl_certificates            = var.app_gateway_definition.ssl_certificates
  ssl_policy                  = var.app_gateway_definition.ssl_policy
  ssl_profile                 = var.app_gateway_definition.ssl_profile
  tags                        = var.app_gateway_definition.tags
  trusted_client_certificate  = var.app_gateway_definition.trusted_client_certificate
  trusted_root_certificate    = var.app_gateway_definition.trusted_root_certificate
  url_path_map_configurations = var.app_gateway_definition.url_path_map_configurations
  zones                       = local.region_zones

  depends_on = [
    azurerm_network_security_rule.this
  ]
}

