locals {
  route_table_name = "${var.vnet_definition.name}-firewall-route-table"

  subnets = {
    AzureBastionSubnet = {
      enabled        = try(var.vnet_definition.subnets["AzureBastionSubnet"].enabled, false)
      name           = "AzureBastionSubnet"
      address_prefix = try(var.vnet_definition.subnets["AzureBastionSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AzureBastionSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 8)]
      route_table    = null
    }
    AzureFirewallSubnet = {
      enabled        = try(var.vnet_definition.subnets["AzureBastionSubnet"].enabled, false)
      name           = "AzureFirewallSubnet"
      address_prefix = try(var.vnet_definition.subnets["AzureFirewallSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AzureFirewallSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 7)]
      route_table    = null
    }
    JumpboxSubnet = {
      enabled          = try(var.vnet_definition.subnets["AzureBastionSubnet"].enabled, false)
      name             = try(var.vnet_definition.subnets["JumpboxSubnet"].name, null) != null ? var.vnet_definition.subnets["JumpboxSubnet"].name : "JumpboxSubnet"
      address_prefixes = try(var.vnet_definition.subnets["JumpboxSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["JumpboxSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 6)]
      route_table = try(var.vnet_definition.subnets["JumpboxSubnet"].udr_to_firewall, false) != false ? {
        id = module.firewall_route_table.resource_id
      } : null
    }
    AppGatewaySubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["AppGatewaySubnet"].name, null) != null ? var.vnet_definition.subnets["AppGatewaySubnet"].name : "AppGatewaySubnet"
      address_prefixes = try(var.vnet_definition.subnets["AppGatewaySubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AppGatewaySubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 5)]
      route_table = try(var.vnet_definition.subnets["AppGatewaySubnet"].udr_to_firewall, false) != false ? {
        id = module.firewall_route_table.resource_id
      } : null
    }
    APIMSubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["APIMSubnet"].name, null) != null ? var.vnet_definition.subnets["APIMSubnet"].name : "APIMSubnet"
      address_prefixes = try(var.vnet_definition.subnets["APIMSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["APIMSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 4)]
      route_table = try(var.vnet_definition.subnets["APIMSubnet"].udr_to_firewall, false) != false ? {
        id = module.firewall_route_table.resource_id
      } : null
    }
    AIFoundrySubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["AIFoundrySubnet"].name, null) != null ? var.vnet_definition.subnets["AIFoundrySubnet"].name : "AIFoundrySubnet"
      address_prefixes = try(var.vnet_definition.subnets["AIFoundrySubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AIFoundrySubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 3)]
      route_table = try(var.vnet_definition.subnets["AIFoundrySubnet"].udr_to_firewall, false) != false ? {
        id = module.firewall_route_table.resource_id
      } : null
    }
    DevOpsBuildSubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["DevOpsBuildSubnet"].name, null) != null ? var.vnet_definition.subnets["DevOpsBuildSubnet"].name : "DevOpsBuildSubnet"
      address_prefixes = try(var.vnet_definition.subnets["DevOpsBuildSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["DevOpsBuildSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 2)]
      route_table = try(var.vnet_definition.subnets["DevOpsBuildSubnet"].udr_to_firewall, false) != false ? {
        id = module.firewall_route_table.resource_id
      } : null
    }
    ContainerAppEnvironmentSubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].name, null) != null ? var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].name : "ContainerAppEnvironmentSubnet"
      address_prefixes = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      route_table = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].udr_to_firewall, false) != false ? {
        id = module.firewall_route_table.resource_id
      } : null
    }
    PrivateEndpointSubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["PrivateEndpointSubnet"].name, null) != null ? var.vnet_definition.subnets["PrivateEndpointSubnet"].name : "PrivateEndpointSubnet"
      address_prefixes = try(var.vnet_definition.subnets["PrivateEndpointSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["PrivateEndpointSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 0)]
      route_table = try(var.vnet_definition.subnets["PrivateEndpointSubnet"].udr_to_firewall, false) != false ? {
        id = module.firewall_route_table.resource_id
      } : null
    }
  }

  deployed_subnets = { for subnet_name, subnet in local.subnets : subnet_name => subnet if subnet.enabled }

}
