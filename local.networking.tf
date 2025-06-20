locals {
  bastion_name     = try(var.bastion_definition.name, null) != null ? var.bastion_definition.name : (try(var.name_prefix, null) != null ? "${var.name_prefix}-bastion" : "ai-alz-bastion")
  deployed_subnets = { for subnet_name, subnet in local.subnets : subnet_name => subnet if subnet.enabled }
  firewall_name    = try(var.firewall_definition.name, null) != null ? var.firewall_definition.name : (try(var.name_prefix, null) != null ? "${var.name_prefix}-fw" : "ai-alz-fw")
  route_table_name = "${local.vnet_name}-firewall-route-table"
  subnets = {
    AzureBastionSubnet = {
      enabled          = var.flag_platform_landing_zone == true ? try(var.vnet_definition.subnets["AzureBastionSubnet"].enabled, true) : try(var.vnet_definition.subnets["AzureBastionSubnet"].enabled, false)
      name             = "AzureBastionSubnet"
      address_prefixes = try(var.vnet_definition.subnets["AzureBastionSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AzureBastionSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 3, 5)]
      route_table      = null
    }
    AzureFirewallSubnet = {
      enabled          = var.flag_platform_landing_zone == true ? try(var.vnet_definition.subnets["AzureFirewallSubnet"].enabled, true) : try(var.vnet_definition.subnets["AzureFirewallSubnet"].enabled, false)
      name             = "AzureFirewallSubnet"
      address_prefixes = try(var.vnet_definition.subnets["AzureFirewallSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AzureFirewallSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 3, 4)]
      route_table      = null
    }
    JumpboxSubnet = {
      enabled          = var.flag_platform_landing_zone == true ? try(var.vnet_definition.subnets["JumpboxSubnet"].enabled, true) : try(var.vnet_definition.subnets["JumpboxSubnet"].enabled, false)
      name             = try(var.vnet_definition.subnets["JumpboxSubnet"].name, null) != null ? var.vnet_definition.subnets["JumpboxSubnet"].name : "JumpboxSubnet"
      address_prefixes = try(var.vnet_definition.subnets["JumpboxSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["JumpboxSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 6)]
      route_table = var.flag_platform_landing_zone == true ? {
        id = module.firewall_route_table[0].resource_id
      } : null
    }
    AppGatewaySubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["AppGatewaySubnet"].name, null) != null ? var.vnet_definition.subnets["AppGatewaySubnet"].name : "AppGatewaySubnet"
      address_prefixes = try(var.vnet_definition.subnets["AppGatewaySubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AppGatewaySubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 5)]
      route_table = var.flag_platform_landing_zone == true ? {
        id = module.firewall_route_table[0].resource_id
      } : null
    }
    APIMSubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["APIMSubnet"].name, null) != null ? var.vnet_definition.subnets["APIMSubnet"].name : "APIMSubnet"
      address_prefixes = try(var.vnet_definition.subnets["APIMSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["APIMSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 4)]
      route_table = var.flag_platform_landing_zone == true ? {
        id = module.firewall_route_table[0].resource_id
      } : null
    }
    AIFoundrySubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["AIFoundrySubnet"].name, null) != null ? var.vnet_definition.subnets["AIFoundrySubnet"].name : "AIFoundrySubnet"
      address_prefixes = try(var.vnet_definition.subnets["AIFoundrySubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AIFoundrySubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 3)]
      route_table = var.flag_platform_landing_zone == true ? {
        id = module.firewall_route_table[0].resource_id
      } : null
    }
    DevOpsBuildSubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["DevOpsBuildSubnet"].name, null) != null ? var.vnet_definition.subnets["DevOpsBuildSubnet"].name : "DevOpsBuildSubnet"
      address_prefixes = try(var.vnet_definition.subnets["DevOpsBuildSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["DevOpsBuildSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 2)]
      route_table = var.flag_platform_landing_zone == true ? {
        id = module.firewall_route_table[0].resource_id
      } : null
    }
    ContainerAppEnvironmentSubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].name, null) != null ? var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].name : "ContainerAppEnvironmentSubnet"
      address_prefixes = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      route_table = var.flag_platform_landing_zone == true ? {
        id = module.firewall_route_table[0].resource_id
      } : null
    }
    PrivateEndpointSubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["PrivateEndpointSubnet"].name, null) != null ? var.vnet_definition.subnets["PrivateEndpointSubnet"].name : "PrivateEndpointSubnet"
      address_prefixes = try(var.vnet_definition.subnets["PrivateEndpointSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["PrivateEndpointSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 0)]
      route_table = var.flag_platform_landing_zone == true ? {
        id = module.firewall_route_table[0].resource_id
      } : null
    }
  }
  vnet_name = try(var.vnet_definition.name, null) != null ? var.vnet_definition.name : (try(var.name_prefix, null) != null ? "${var.name_prefix}-vnet" : "ai-alz-vnet")
}
