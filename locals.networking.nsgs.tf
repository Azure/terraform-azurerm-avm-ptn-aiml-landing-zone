#TODO: Come up with a standard set of NSG rules for the AI ALZ. This is a starting point.
locals {
  # Common rules shared across most NSGs (but NOT Bastion)
  common_nsg_rules = {
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
  }

  # General NSG rules (for AppGateway, APIM, AIFoundry, DevOps, Jumpbox, PrivateEndpoint subnets)
  general_nsg_specific_rules = {
    "appgw_rule01" = {
      name                         = "Allow-AppGW_Management"
      access                       = "Allow"
      destination_address_prefixes = try(var.vnet_definition.subnets["AppGatewaySubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AppGatewaySubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 5)]
      destination_port_range       = "65503-65534"
      direction                    = "Inbound"
      priority                     = 110
      protocol                     = "*"
      source_address_prefix        = "Internet"
      source_port_range            = "*"
    }
    "appgw_rule02" = {
      name                         = "Allow-AppGW_Web"
      access                       = "Allow"
      destination_address_prefixes = try(var.vnet_definition.subnets["AppGatewaySubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AppGatewaySubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 5)]
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
      destination_address_prefixes = try(var.vnet_definition.subnets["AppGatewaySubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AppGatewaySubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 5)]
      destination_port_range       = "*"
      direction                    = "Inbound"
      priority                     = 4000
      protocol                     = "*"
      source_address_prefix        = "AzureLoadBalancer"
      source_port_range            = "*"
    }
  }

  # Bastion-specific NSG rules (for AzureBastionSubnet only)
  # Based on official Azure Bastion NSG requirements: https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg
  bastion_nsg_specific_rules = {
    # REQUIRED INBOUND RULES
    "AllowHttpsInbound" = {
      name                       = "AllowHttpsInbound"
      access                     = "Allow"
      destination_port_range     = "443"
      direction                  = "Inbound"
      priority                   = 1000
      protocol                   = "Tcp"
      source_address_prefix      = "Internet"
      source_port_range          = "*"
      destination_address_prefix = "*"
    }
    "AllowGatewayManagerInbound" = {
      name                       = "AllowGatewayManagerInbound"
      access                     = "Allow"
      destination_port_range     = "443"
      direction                  = "Inbound"
      priority                   = 1001
      protocol                   = "Tcp"
      source_address_prefix      = "GatewayManager"
      source_port_range          = "*"
      destination_address_prefix = "*"
    }
    "AllowAzureLoadBalancerInbound" = {
      name                       = "AllowAzureLoadBalancerInbound"
      access                     = "Allow"
      destination_port_range     = "443"
      direction                  = "Inbound"
      priority                   = 1002
      protocol                   = "Tcp"
      source_address_prefix      = "AzureLoadBalancer"
      source_port_range          = "*"
      destination_address_prefix = "*"
    }
    "AllowBastionHostCommunication" = {
      name                       = "AllowBastionHostCommunication"
      access                     = "Allow"
      destination_port_ranges    = ["8080", "5701"]
      direction                  = "Inbound"
      priority                   = 1003
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "VirtualNetwork"
    }
    # REQUIRED OUTBOUND RULES
    "AllowSshRdpOutbound" = {
      name                       = "AllowSshRdpOutbound"
      access                     = "Allow"
      destination_port_ranges    = ["22", "3389"]
      direction                  = "Outbound"
      priority                   = 1000
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "VirtualNetwork"
    }
    "AllowAzureCloudOutbound" = {
      name                       = "AllowAzureCloudOutbound"
      access                     = "Allow"
      destination_port_range     = "443"
      direction                  = "Outbound"
      priority                   = 1001
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "AzureCloud"
    }
    "AllowBastionCommunication" = {
      name                       = "AllowBastionCommunication"
      access                     = "Allow"
      destination_port_ranges    = ["8080", "5701"]
      direction                  = "Outbound"
      priority                   = 1002
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "VirtualNetwork"
    }
    "AllowGetSessionInformation" = {
      name                       = "AllowGetSessionInformation"
      access                     = "Allow"
      destination_port_range     = "80"
      direction                  = "Outbound"
      priority                   = 1003
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "Internet"
    }
  }

  # Container App Environment-specific NSG rules (for ContainerAppEnvironmentSubnet only)
  container_app_nsg_specific_rules = {
    # Container App Environment NSG Rules - Inbound (supports both Workload Profiles and Consumption-only)
    "cae_rule01" = {
      name                         = "Allow-CAE_Client_HTTP"
      access                       = "Allow"
      destination_address_prefixes = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      destination_port_ranges      = ["80", "31080"]
      direction                    = "Inbound"
      priority                     = 200
      protocol                     = "Tcp"
      source_address_prefix        = "VirtualNetwork"
      source_port_range            = "*"
    }
    "cae_rule02" = {
      name                         = "Allow-CAE_Client_HTTPS"
      access                       = "Allow"
      destination_address_prefixes = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      destination_port_ranges      = ["443", "31443"]
      direction                    = "Inbound"
      priority                     = 210
      protocol                     = "Tcp"
      source_address_prefix        = "VirtualNetwork"
      source_port_range            = "*"
    }
    "cae_rule03" = {
      name                         = "Allow-CAE_LoadBalancer_Health"
      access                       = "Allow"
      destination_address_prefixes = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      destination_port_range       = "30000-32767"
      direction                    = "Inbound"
      priority                     = 220
      protocol                     = "Tcp"
      source_address_prefix        = "AzureLoadBalancer"
      source_port_range            = "*"
    }
    "cae_rule04" = {
      name                         = "Allow-CAE_VNet_Internal"
      access                       = "Allow"
      destination_address_prefixes = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      destination_port_range       = "*"
      direction                    = "Inbound"
      priority                     = 230
      protocol                     = "*"
      source_address_prefixes      = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      source_port_range            = "*"
    }
    # Container App Environment NSG Rules - Outbound
    "cae_rule05" = {
      name                       = "Allow-CAE_MicrosoftContainerRegistry"
      access                     = "Allow"
      destination_address_prefix = "MicrosoftContainerRegistry"
      destination_port_range     = "443"
      direction                  = "Outbound"
      priority                   = 200
      protocol                   = "Tcp"
      source_address_prefixes    = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      source_port_range          = "*"
    }
    "cae_rule06" = {
      name                       = "Allow-CAE_AzureFrontDoor"
      access                     = "Allow"
      destination_address_prefix = "AzureFrontDoor.FirstParty"
      destination_port_range     = "443"
      direction                  = "Outbound"
      priority                   = 210
      protocol                   = "Tcp"
      source_address_prefixes    = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      source_port_range          = "*"
    }
    "cae_rule07" = {
      name                         = "Allow-CAE_VNet_Internal_Out"
      access                       = "Allow"
      destination_address_prefixes = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      destination_port_range       = "*"
      direction                    = "Outbound"
      priority                     = 220
      protocol                     = "*"
      source_address_prefixes      = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      source_port_range            = "*"
    }
    "cae_rule08" = {
      name                       = "Allow-CAE_AzureActiveDirectory"
      access                     = "Allow"
      destination_address_prefix = "AzureActiveDirectory"
      destination_port_range     = "443"
      direction                  = "Outbound"
      priority                   = 230
      protocol                   = "Tcp"
      source_address_prefixes    = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      source_port_range          = "*"
    }
    "cae_rule09" = {
      name                       = "Allow-CAE_AzureMonitor"
      access                     = "Allow"
      destination_address_prefix = "AzureMonitor"
      destination_port_range     = "443"
      direction                  = "Outbound"
      priority                   = 240
      protocol                   = "Tcp"
      source_address_prefixes    = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      source_port_range          = "*"
    }
    "cae_rule10" = {
      name                       = "Allow-CAE_AzureDNS"
      access                     = "Allow"
      destination_address_prefix = "168.63.129.16"
      destination_port_range     = "53"
      direction                  = "Outbound"
      priority                   = 250
      protocol                   = "*"
      source_address_prefixes    = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      source_port_range          = "*"
    }
    "cae_rule11" = {
      name                       = "Allow-CAE_AzureContainerRegistry"
      access                     = "Allow"
      destination_address_prefix = "AzureContainerRegistry"
      destination_port_range     = "443"
      direction                  = "Outbound"
      priority                   = 260
      protocol                   = "Tcp"
      source_address_prefixes    = try(var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 1)]
      source_port_range          = "*"
    }
  }

  # Bastion subnet enablement (used to avoid circular dependency)
  bastion_subnet_enabled = var.flag_platform_landing_zone == true ? try(var.vnet_definition.subnets["AzureBastionSubnet"].enabled, true) : try(var.vnet_definition.subnets["AzureBastionSubnet"].enabled, false)

  # Merged rule sets for each NSG type
  nsg_name = try(var.nsgs_definition.name, null) != null ? var.nsgs_definition.name : (var.name_prefix != null ? "${var.name_prefix}-ai-alz-nsg" : "ai-alz-nsg")
  nsg_rules = merge(
    local.common_nsg_rules,
    local.general_nsg_specific_rules,
    try(var.nsgs_definition.security_rules, {})
  )

  bastion_nsg_name = try(var.nsgs_definition.bastion_name, null) != null ? var.nsgs_definition.bastion_name : (var.name_prefix != null ? "${var.name_prefix}-bastion-nsg" : "ai-alz-bastion-nsg")
  bastion_nsg_rules = merge(
    # Note: Bastion NSG only includes Azure-required rules - no common rules to avoid conflicts
    local.bastion_nsg_specific_rules,
    try(var.nsgs_definition.bastion_security_rules, {})
  )

  container_app_nsg_name = try(var.nsgs_definition.container_app_name, null) != null ? var.nsgs_definition.container_app_name : (var.name_prefix != null ? "${var.name_prefix}-container-app-nsg" : "ai-alz-container-app-nsg")
  container_app_nsg_rules = merge(
    local.common_nsg_rules,
    local.container_app_nsg_specific_rules,
    try(var.nsgs_definition.container_app_security_rules, {})
  )
}