locals {
  bastion_name = var.name_prefix != null ? "${var.name_prefix}-example-bastion" : "ai-alz-example-bastion"
  default_outbound_network_ruleset = [
    {
      name                  = "OutboundToInternet"
      description           = "Allow traffic outbound to the Internet"
      destination_addresses = ["0.0.0.0/0"]
      destination_ports     = ["443", "80"]
      source_addresses      = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      protocols             = ["TCP", "UDP"]
    }
  ]
  deployed_subnets                           = { for subnet_name, subnet in local.subnets : subnet_name => subnet if subnet.enabled }
  firewall_name                              = var.name_prefix != null ? "${var.name_prefix}-example-fw" : "ai-alz-example-fw"
  firewall_policy_network_ruleset            = local.default_outbound_network_ruleset
  firewall_policy_rule_collection_group_name = "NetworkRuleCollectionGroup"
  firewall_policy_rule_collection_group_network_rule_collection = [
    {
      action   = "Allow"
      name     = local.firewall_policy_rule_collection_group_name
      priority = local.firewall_policy_rule_collection_group_priority
      rule     = local.firewall_policy_network_ruleset
    }
  ]
  firewall_policy_rule_collection_group_priority = 400
  jump_vm_name                                   = "ai-alz-jumpvm"
  kv_name                                        = var.name_prefix != null ? "${var.name_prefix}-kv-${random_string.name_suffix.result}" : "ai-alz-keyvault-${random_string.name_suffix.result}"
  log_analytics_workspace_name                   = var.name_prefix != null ? "${var.name_prefix}-example-law" : "ai-alz-example-law"
  nat_gateway_name                               = var.name_prefix != null ? "${var.name_prefix}-example-nat-gateway" : "ai-alz-example-nat-gateway"
  private_dns_zones = {
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
  region_zones        = local.region_zones_lookup != null ? local.region_zones_lookup : []
  region_zones_lookup = [for region in module.avm_utl_regions.regions : region if(lower(region.name) == lower(azurerm_resource_group.this.location) || (lower(region.display_name) == lower(azurerm_resource_group.this.location)))][0].zones
  subnets = {
    AzureBastionSubnet = {
      enabled          = true
      name             = "AzureBastionSubnet"
      address_prefixes = [cidrsubnet(var.vnet_definition.address_space, 2, 0)]
    }
    JumpboxSubnet = {
      enabled          = true
      name             = "JumpboxSubnet"
      address_prefixes = [cidrsubnet(var.vnet_definition.address_space, 2, 1)]
      nat_gateway = {
        id = module.natgateway.resource_id
      }
    }
    AzureFirewallSubnet = {
      enabled          = true
      name             = "AzureFirewallSubnet"
      address_prefixes = [cidrsubnet(var.vnet_definition.address_space, 2, 2)]
    }
    DNSResolverInbound = {
      enabled          = true
      name             = "DNSResolverInbound"
      address_prefixes = [cidrsubnet(var.vnet_definition.address_space, 2, 3)]
      delegation = [{
        name = "DNSResolverInboundDelegation"
        service_delegation = {
          name = "Microsoft.Network/dnsResolvers"
        }
      }]
    }
  }
  vnet_name = var.name_prefix != null ? "${var.name_prefix}-example-vnet" : "ai-alz-example-vnet"
}
