#TODO: Come up with a standard set of NSG rules for the AI ALZ. This is a starting point.
locals {
  base_nsg_rules = {
    "rule01" = {
      name                         = "Allow-RFC-1918-Any"
      access                       = "Allow"
      destination_address_prefixes = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      destination_port_range       = "*"
      direction                    = "Outbound"
      priority                     = 100
      protocol                     = "*"
      source_address_prefixes      = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      source_port_range            = "*"
    }
    "appgw_rule01" = {
      name                       = "Allow-AppGW_Management"
      access                     = "Allow"
      destination_address_prefix = "*" # Allow to all addresses as per MS documentation, https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#network-security-groups
      destination_port_range     = "65200-65535"
      direction                  = "Inbound"
      priority                   = 110
      protocol                   = "*"
      source_address_prefix      = "GatewayManager"
      source_port_range          = "*"
    }
    "appgw_rule02" = {
      name                         = "Allow-AppGW_Web"
      access                       = "Allow"
      destination_address_prefixes = length(var.vnet_definition.existing_byo_vnet) > 0 ? module.byo_subnets["AppGatewaySubnet"].address_prefixes : module.ai_lz_vnet[0].subnets["AppGatewaySubnet"].address_prefixes
      destination_port_ranges      = ["80", "443"]
      direction                    = "Inbound"
      priority                     = 120
      protocol                     = "Tcp"
      source_address_prefix        = "*"
      source_port_range            = "*"
    }
    "appgw_rule03" = {
      name                         = "Allow-AppGW_LoadBalancer"
      access                       = "Allow"
      destination_address_prefixes = length(var.vnet_definition.existing_byo_vnet) > 0 ? module.byo_subnets["AppGatewaySubnet"].address_prefixes : module.ai_lz_vnet[0].subnets["AppGatewaySubnet"].address_prefixes
      destination_port_range       = "*"
      direction                    = "Inbound"
      priority                     = 4000
      protocol                     = "*"
      source_address_prefix        = "AzureLoadBalancer"
      source_port_range            = "*"
    }
    "apim_rule01" = {
      name                       = "Allow-APIM-Management"
      access                     = "Allow"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "3443"
      direction                  = "Inbound"
      priority                   = 130
      protocol                   = "Tcp"
      source_address_prefix      = "ApiManagement"
      source_port_range          = "*"
    }
    "apim_rule02" = {
      name                       = "Allow-APIM-Storage-Outbound"
      access                     = "Allow"
      destination_address_prefix = "Storage"
      destination_port_range     = "443"
      direction                  = "Outbound"
      priority                   = 110
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
    }
    "apim_rule03" = {
      name                       = "Allow-APIM-LoadBalancer"
      access                     = "Allow"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "6390"
      direction                  = "Inbound"
      priority                   = 140
      protocol                   = "Tcp"
      source_address_prefix      = "AzureLoadBalancer"
      source_port_range          = "*"
    }

  }
  nsg_name = try(var.nsgs_definition.name, null) != null ? var.nsgs_definition.name : (var.name_prefix != null ? "${var.name_prefix}-ai-alz-nsg" : "ai-alz-nsg")
  nsg_rules = merge(
    local.base_nsg_rules,
    var.nsgs_definition.security_rules
  )
}
