locals {
  application_gateway_name = try(var.app_gateway_definition.name, null) != null ? var.app_gateway_definition.name : (var.name_prefix != null ? "${var.name_prefix}-appgw" : "ai-alz-appgw")
  application_gateway_role_assignments = merge(
    local.application_gateway_role_assignments_base,
    try(var.app_gateway_definition.role_assignments, {})
  )
  application_gateway_role_assignments_base = {}
  bastion_name                              = try(var.bastion_definition.name, null) != null ? var.bastion_definition.name : (var.name_prefix != null ? "${var.name_prefix}-bastion" : "ai-alz-bastion")
  default_virtual_network_link = {
    alz_vnet_link = {
      vnetlinkname      = "${local.vnet_name}-link"
      vnetid            = local.vnet_resource_id
      autoregistration  = false
      resolution_policy = var.private_dns_zones.allow_internet_resolution_fallback == false ? "Default" : "NxDomainRedirect"
      tags              = local.private_dns_zone_tags
    }
  }
  deployed_subnets = { for subnet_name, subnet in local.subnets : subnet_name => subnet if subnet.enabled }
  firewall_name    = try(var.firewall_definition.name, null) != null ? var.firewall_definition.name : (var.name_prefix != null ? "${var.name_prefix}-fw" : "ai-alz-fw")
  # Private DNS zones names needed for Private Endpoints
  private_dns_zone_map = {
    key_vault_zone                     = "privatelink.vaultcore.azure.net"
    apim_zone                          = "privatelink.azure-api.net"
    cosmos_sql_zone                    = "privatelink.documents.azure.com"
    cosmos_mongo_zone                  = "privatelink.mongo.cosmos.azure.com"
    cosmos_cassandra_zone              = "privatelink.cassandra.cosmos.azure.com"
    cosmos_gremlin_zone                = "privatelink.gremlin.cosmos.azure.com"
    cosmos_table_zone                  = "privatelink.table.cosmos.azure.com"
    cosmos_analytical_zone             = "privatelink.analytics.cosmos.azure.com"
    cosmos_postgres_zone               = "privatelink.postgres.cosmos.azure.com"
    storage_blob_zone                  = "privatelink.blob.core.windows.net"
    storage_queue_zone                 = "privatelink.queue.core.windows.net"
    storage_table_zone                 = "privatelink.table.core.windows.net"
    storage_file_zone                  = "privatelink.file.core.windows.net"
    storage_dlfs_zone                  = "privatelink.dfs.core.windows.net"
    storage_web_zone                   = "privatelink.web.core.windows.net"
    ai_search_zone                     = "privatelink.search.windows.net"
    container_registry_zone            = "privatelink.azurecr.io"
    app_configuration_zone             = "privatelink.azconfig.io"
    ai_foundry_openai_zone             = "privatelink.openai.azure.com"
    ai_foundry_ai_services_zone        = "privatelink.services.ai.azure.com"
    ai_foundry_cognitive_services_zone = "privatelink.cognitiveservices.azure.com"
  }
  # Maps of Private DNS zone resource IDs, either from existing or created zones
  private_dns_zone_resource_map = { for k, v in local.private_dns_zone_map : k =>
    {
      name = v
      id = try(coalesce(
        try("${var.private_dns_zones.existing_zones_resource_group_resource_id}/providers/Microsoft.Network/privateDnsZones/${v}", null),
        try(module.private_dns_zones[k].resource_id, null)
      ), null)
    }
  }
  # Tags for Private DNS zones, excluding any with ":" in the name - Odd quirk of Private DNS zones, they don't like that char
  private_dns_zone_tags = { for k, v in var.private_dns_zones.tags != null ? var.private_dns_zones.tags : var.tags : k => v if !strcontains(k, ":") }
  route_table_name      = "${local.vnet_name}-firewall-route-table"
  subnet_ids            = length(var.vnet_definition.existing_byo_vnet) > 0 ? { for key, m in module.byo_subnets : key => try(m.resource_id, m.id) } : { for key, s in module.ai_lz_vnet[0].subnets : key => s.resource_id }
  subnets = {
    AzureBastionSubnet = {
      enabled          = var.flag_platform_landing_zone == true ? try(local.subnets_definition["AzureBastionSubnet"].enabled, true) : try(local.subnets_definition["AzureBastionSubnet"].enabled, false)
      name             = "AzureBastionSubnet"
      address_prefixes = try(local.subnets_definition["AzureBastionSubnet"].address_prefix, null) != null ? [local.subnets_definition["AzureBastionSubnet"].address_prefix] : [cidrsubnet(local.vnet_address_space, 3, 5)]
      route_table      = null
      #network_security_group = {
      #  id = module.nsgs.resource_id
      #}
    }
    AzureFirewallSubnet = {
      enabled          = var.flag_platform_landing_zone == true ? try(local.subnets_definition["AzureFirewallSubnet"].enabled, true) : try(local.subnets_definition["AzureFirewallSubnet"].enabled, false)
      name             = "AzureFirewallSubnet"
      address_prefixes = try(local.subnets_definition["AzureFirewallSubnet"].address_prefix, null) != null ? [local.subnets_definition["AzureFirewallSubnet"].address_prefix] : [cidrsubnet(local.vnet_address_space, 3, 4)]
      route_table      = null
    }
    JumpboxSubnet = {
      enabled          = var.flag_platform_landing_zone == true ? try(local.subnets_definition["JumpboxSubnet"].enabled, true) : try(local.subnets_definition["JumpboxSubnet"].enabled, false)
      name             = try(local.subnets_definition["JumpboxSubnet"].name, null) != null ? local.subnets_definition["JumpboxSubnet"].name : "JumpboxSubnet"
      address_prefixes = try(local.subnets_definition["JumpboxSubnet"].address_prefix, null) != null ? [local.subnets_definition["JumpboxSubnet"].address_prefix] : [cidrsubnet(local.vnet_address_space, 4, 6)]
      route_table = ((var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) == 0) ||
        (var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) > 0 && try(values(var.vnet_definition.existing_byo_vnet)[0].firewall_ip_address, null) != null)) ? {
        id = module.firewall_route_table[0].resource_id
      } : null
      network_security_group = {
        id = module.nsgs.resource_id
      }
    }
    AppGatewaySubnet = {
      enabled          = true
      name             = try(local.subnets_definition["AppGatewaySubnet"].name, null) != null ? local.subnets_definition["AppGatewaySubnet"].name : "AppGatewaySubnet"
      address_prefixes = try(local.subnets_definition["AppGatewaySubnet"].address_prefix, null) != null ? [local.subnets_definition["AppGatewaySubnet"].address_prefix] : [cidrsubnet(local.vnet_address_space, 4, 5)]
      route_table = ((var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) == 0) ||
        (var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) > 0 && try(values(var.vnet_definition.existing_byo_vnet)[0].firewall_ip_address, null) != null)) ? {
        id = module.firewall_route_table[0].resource_id
      } : null
      network_security_group = {
        id = module.nsgs.resource_id
      }
      delegations = [{
        name = "AppGatewaySubnetDelegation"
        service_delegation = {
          name = "Microsoft.Network/applicationGateways"
        }
      }]
    }
    APIMSubnet = {
      enabled          = true
      name             = try(local.subnets_definition["APIMSubnet"].name, null) != null ? local.subnets_definition["APIMSubnet"].name : "APIMSubnet"
      address_prefixes = try(local.subnets_definition["APIMSubnet"].address_prefix, null) != null ? [local.subnets_definition["APIMSubnet"].address_prefix] : [cidrsubnet(local.vnet_address_space, 4, 4)]
      route_table = ((var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) == 0) ||
        (var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) > 0 && try(values(var.vnet_definition.existing_byo_vnet)[0].firewall_ip_address, null) != null)) ? {
        id = module.firewall_route_table[0].resource_id
      } : null
      network_security_group = {
        id = module.nsgs.resource_id
      }
    }
    AIFoundrySubnet = {
      enabled          = true
      name             = try(local.subnets_definition["AIFoundrySubnet"].name, null) != null ? local.subnets_definition["AIFoundrySubnet"].name : "AIFoundrySubnet"
      address_prefixes = try(local.subnets_definition["AIFoundrySubnet"].address_prefix, null) != null ? [local.subnets_definition["AIFoundrySubnet"].address_prefix] : [cidrsubnet(local.vnet_address_space, 4, 3)]
      route_table = ((var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) == 0) ||
        (var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) > 0 && try(values(var.vnet_definition.existing_byo_vnet)[0].firewall_ip_address, null) != null)) ? {
        id = module.firewall_route_table[0].resource_id
      } : null
      network_security_group = {
        id = module.nsgs.resource_id
      }
      delegations = [{
        name = "AgentServiceDelegation"
        service_delegation = {
          name    = "Microsoft.App/environments"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }]
    }
    DevOpsBuildSubnet = {
      enabled          = true
      name             = try(local.subnets_definition["DevOpsBuildSubnet"].name, null) != null ? local.subnets_definition["DevOpsBuildSubnet"].name : "DevOpsBuildSubnet"
      address_prefixes = try(local.subnets_definition["DevOpsBuildSubnet"].address_prefix, null) != null ? [local.subnets_definition["DevOpsBuildSubnet"].address_prefix] : [cidrsubnet(local.vnet_address_space, 4, 2)]
      route_table = ((var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) == 0) ||
        (var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) > 0 && try(values(var.vnet_definition.existing_byo_vnet)[0].firewall_ip_address, null) != null)) ? {
        id = module.firewall_route_table[0].resource_id
      } : null
      network_security_group = {
        id = module.nsgs.resource_id
      }
    }
    ContainerAppEnvironmentSubnet = {
      delegations = [{
        name = "ContainerAppEnvironmentSubnetDelegation"
        service_delegation = {
          name = "Microsoft.App/environments"
        }
      }]
      enabled          = true
      name             = try(local.subnets_definition["ContainerAppEnvironmentSubnet"].name, null) != null ? local.subnets_definition["ContainerAppEnvironmentSubnet"].name : "ContainerAppEnvironmentSubnet"
      address_prefixes = try(local.subnets_definition["ContainerAppEnvironmentSubnet"].address_prefix, null) != null ? [local.subnets_definition["ContainerAppEnvironmentSubnet"].address_prefix] : [cidrsubnet(local.vnet_address_space, 4, 1)]
      route_table = ((var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) == 0) ||
        (var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) > 0 && try(values(var.vnet_definition.existing_byo_vnet)[0].firewall_ip_address, null) != null)) ? {
        id = module.firewall_route_table[0].resource_id
      } : null
    }
    PrivateEndpointSubnet = {
      enabled          = true
      name             = try(local.subnets_definition["PrivateEndpointSubnet"].name, null) != null ? local.subnets_definition["PrivateEndpointSubnet"].name : "PrivateEndpointSubnet"
      address_prefixes = try(local.subnets_definition["PrivateEndpointSubnet"].address_prefix, null) != null ? [local.subnets_definition["PrivateEndpointSubnet"].address_prefix] : [cidrsubnet(local.vnet_address_space, 4, 0)]
      route_table = ((var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) == 0) ||
        (var.flag_platform_landing_zone && length(var.vnet_definition.existing_byo_vnet) > 0 && try(values(var.vnet_definition.existing_byo_vnet)[0].firewall_ip_address, null) != null)) ? {
        id = module.firewall_route_table[0].resource_id
      } : null
      network_security_group = {
        id = module.nsgs.resource_id
      }
    }
  }
  subnets_definition    = var.vnet_definition.subnets
  virtual_network_links = merge(local.default_virtual_network_link, var.private_dns_zones.network_links)
  vnet_address_space    = length(var.vnet_definition.existing_byo_vnet) > 0 ? data.azurerm_virtual_network.ai_lz_vnet[0].address_space[0] : var.vnet_definition.address_space
  vnet_name             = length(var.vnet_definition.existing_byo_vnet) > 0 ? try(basename(values(var.vnet_definition.existing_byo_vnet)[0].vnet_resource_id), null) : (try(var.vnet_definition.name, null) != null ? var.vnet_definition.name : (var.name_prefix != null ? "${var.name_prefix}-vnet" : "ai-alz-vnet"))
  vnet_resource_id      = length(var.vnet_definition.existing_byo_vnet) > 0 ? data.azurerm_virtual_network.ai_lz_vnet[0].id : module.ai_lz_vnet[0].resource_id
  #web_application_firewall_managed_rules = var.waf_policy_definition.managed_rules == null ? {
  #  managed_rule_set = tomap({
  #    owasp = {
  #      version = "3.2"
  #      type    = "OWASP"
  #      rule_group_override = null
  #    }
  #  })
  #} : var.waf_policy_definition.managed_rules
  web_application_firewall_policy_name = try(var.waf_policy_definition.name, null) != null ? var.waf_policy_definition.name : (var.name_prefix != null ? "${var.name_prefix}-waf-policy" : "ai-alz-waf-policy")
}
