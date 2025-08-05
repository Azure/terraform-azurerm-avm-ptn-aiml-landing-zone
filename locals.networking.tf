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
      vnetid            = module.ai_lz_vnet.resource_id
      autoregistration  = false
      resolution_policy = var.private_dns_zones.allow_internet_resolution_fallback == false ? "Default" : "NxDomainRedirect"
    }
  }
  deployed_subnets = { for subnet_name, subnet in local.subnets : subnet_name => subnet if subnet.enabled }
  firewall_name    = try(var.firewall_definition.name, null) != null ? var.firewall_definition.name : (var.name_prefix != null ? "${var.name_prefix}-fw" : "ai-alz-fw")
  private_dns_zone_map = {
    key_vault_zone = {
      name = "privatelink.vaultcore.azure.net"
    }
    apim_zone = {
      name = "privatelink.azure-api.net"
    }
    cosmos_sql_zone = {
      name = "privatelink.documents.azure.com"
    }
    cosmos_mongo_zone = {
      name = "privatelink.mongo.cosmos.azure.com"
    }
    cosmos_cassandra_zone = {
      name = "privatelink.cassandra.cosmos.azure.com"
    }
    cosmos_gremlin_zone = {
      name = "privatelink.gremlin.cosmos.azure.com"
    }
    cosmos_table_zone = {
      name = "privatelink.table.cosmos.azure.com"
    }
    cosmos_analytical_zone = {
      name = "privatelink.analytics.cosmos.azure.com"
    }
    cosmos_postgres_zone = {
      name = "privatelink.postgres.cosmos.azure.com"
    }
    storage_blob_zone = {
      name = "privatelink.blob.core.windows.net"
    }
    storage_queue_zone = {
      name = "privatelink.queue.core.windows.net"
    }
    storage_table_zone = {
      name = "privatelink.table.core.windows.net"
    }
    storage_file_zone = {
      name = "privatelink.file.core.windows.net"
    }
    storage_dlfs_zone = {
      name = "privatelink.dfs.core.windows.net"
    }
    storage_web_zone = {
      name = "privatelink.web.core.windows.net"
    }
    ai_search_zone = {
      name = "privatelink.search.windows.net"
    }
    container_registry_zone = {
      name = "privatelink.azurecr.io"
    }
    app_configuration_zone = {
      name = "privatelink.azconfig.io"
    }
    ai_foundry_openai_zone = {
      name = "privatelink.openai.azure.com"
    }
    ai_foundry_ai_services_zone = {
      name = "privatelink.services.ai.azure.com"
    }
    ai_foundry_cognitive_services_zone = {
      name = "privatelink.cognitiveservices.azure.com"
    }
  }
  private_dns_zones = var.flag_platform_landing_zone == true ? local.private_dns_zone_map : {}
  private_dns_zones_existing = var.flag_platform_landing_zone == false ? { for key, value in local.private_dns_zone_map : key => {
    name        = value.name
    resource_id = "${coalesce(var.private_dns_zones.existing_zones_resource_group_resource_id, "notused")}/providers/Microsoft.Network/privateDnsZones/${value.name}" #TODO: determine if there is a more elegant way to do this while avoiding errors
    }
  } : {}
  route_table_name = "${local.vnet_name}-firewall-route-table"
  subnets = {
    AzureBastionSubnet = {
      enabled          = var.flag_platform_landing_zone == true ? try(var.vnet_definition.subnets["AzureBastionSubnet"].enabled, true) : try(var.vnet_definition.subnets["AzureBastionSubnet"].enabled, false)
      name             = "AzureBastionSubnet"
      address_prefixes = try(var.vnet_definition.subnets["AzureBastionSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AzureBastionSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 3, 5)]
      route_table      = null
      #network_security_group = {
      #  id = module.nsgs.resource_id
      #}
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
      network_security_group = {
        id = module.nsgs.resource_id
      }
    }
    AppGatewaySubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["AppGatewaySubnet"].name, null) != null ? var.vnet_definition.subnets["AppGatewaySubnet"].name : "AppGatewaySubnet"
      address_prefixes = try(var.vnet_definition.subnets["AppGatewaySubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AppGatewaySubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 5)]
      route_table = var.flag_platform_landing_zone == true ? {
        id = module.firewall_route_table[0].resource_id
      } : null
      network_security_group = {
        id = module.nsgs.resource_id
      }
      delegation = [{
        name = "AppGatewaySubnetDelegation"
        service_delegation = {
          name = "Microsoft.Network/applicationGateways"
        }
      }]
    }
    APIMSubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["APIMSubnet"].name, null) != null ? var.vnet_definition.subnets["APIMSubnet"].name : "APIMSubnet"
      address_prefixes = try(var.vnet_definition.subnets["APIMSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["APIMSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 4)]
      route_table = var.flag_platform_landing_zone == true ? {
        id = module.firewall_route_table[0].resource_id
      } : null
      network_security_group = {
        id = module.nsgs.resource_id
      }
    }
    AIFoundrySubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["AIFoundrySubnet"].name, null) != null ? var.vnet_definition.subnets["AIFoundrySubnet"].name : "AIFoundrySubnet"
      address_prefixes = try(var.vnet_definition.subnets["AIFoundrySubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["AIFoundrySubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 3)]
      route_table = var.flag_platform_landing_zone == true ? {
        id = module.firewall_route_table[0].resource_id
      } : null
      network_security_group = {
        id = module.nsgs.resource_id
      }
      delegation = [{
        name = "AgentServiceDelegation"
        service_delegation = {
          name    = "Microsoft.App/environments"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }]
    }
    DevOpsBuildSubnet = {
      enabled          = true
      name             = try(var.vnet_definition.subnets["DevOpsBuildSubnet"].name, null) != null ? var.vnet_definition.subnets["DevOpsBuildSubnet"].name : "DevOpsBuildSubnet"
      address_prefixes = try(var.vnet_definition.subnets["DevOpsBuildSubnet"].address_prefix, null) != null ? [var.vnet_definition.subnets["DevOpsBuildSubnet"].address_prefix] : [cidrsubnet(var.vnet_definition.address_space, 4, 2)]
      route_table = var.flag_platform_landing_zone == true ? {
        id = module.firewall_route_table[0].resource_id
      } : null
      network_security_group = {
        id = module.nsgs.resource_id
      }
    }
    ContainerAppEnvironmentSubnet = {
      delegation = [{
        name = "ContainerAppEnvironmentSubnetDelegation"
        service_delegation = {
          name = "Microsoft.App/environments"
        }
      }]
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
      network_security_group = {
        id = module.nsgs.resource_id
      }
    }
  }
  virtual_network_links = merge(local.default_virtual_network_link, var.private_dns_zones.network_links)
  vnet_name             = try(var.vnet_definition.name, null) != null ? var.vnet_definition.name : (var.name_prefix != null ? "${var.name_prefix}-vnet" : "ai-alz-vnet")
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
