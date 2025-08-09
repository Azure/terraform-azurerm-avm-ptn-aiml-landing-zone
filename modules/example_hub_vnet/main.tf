
data "azurerm_client_config" "current" {}

module "avm_utl_regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.2"

  recommended_filter = false
}

resource "random_string" "name_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
  tags     = var.tags
}

#Create Hub Vnet (Subnets: AzureBastionSubnet, BuildVM subnet, Private Resolver Subnet?)
module "ai_lz_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.7.1"

  address_space       = [var.vnet_definition.address_space]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  name                = local.vnet_name
  subnets             = local.deployed_subnets
}

module "natgateway" {
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = "0.2.1"

  location            = azurerm_resource_group.this.location
  name                = local.nat_gateway_name
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = true
  public_ips = {
    public_ip_1 = {
      name = "${local.nat_gateway_name}-pip"
    }
  }
}

module "bastion_pip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.0"

  location            = azurerm_resource_group.this.location
  name                = "${local.bastion_name}-pip"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  zones               = local.region_zones
}

resource "azurerm_bastion_host" "bastion" {
  location            = azurerm_resource_group.this.location
  name                = local.bastion_name
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  ip_configuration {
    name                 = "${local.bastion_name}-ipconf"
    public_ip_address_id = module.bastion_pip.resource_id
    subnet_id            = module.ai_lz_vnet.subnets["AzureBastionSubnet"].resource_id
  }
}

# Add Azure Firewall with a permissive outbound rule for RFC 1918 traffic
module "fw_pip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.0"

  location            = azurerm_resource_group.this.location
  name                = "${local.firewall_name}-pip"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  zones               = local.region_zones
}

module "firewall" {
  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = "0.3.0"

  firewall_sku_name   = "AZFW_VNet"
  firewall_sku_tier   = "Standard"
  location            = azurerm_resource_group.this.location
  name                = local.firewall_name
  resource_group_name = azurerm_resource_group.this.name
  diagnostic_settings = {
    to_law = {
      name                  = "sendToLogAnalytics-fw-${random_string.name_suffix.result}"
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
      public_ip_address_id = module.fw_pip.resource_id
    }
  ]
  firewall_zones = local.region_zones
}

module "firewall_policy" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "0.3.3"

  location            = azurerm_resource_group.this.location
  name                = "${local.firewall_name}-policy"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
}

#TODO: add application rule collection support
module "firewall_network_rule_collection_group" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  version = "0.3.3"

  firewall_policy_rule_collection_group_firewall_policy_id      = module.firewall_policy.resource_id
  firewall_policy_rule_collection_group_name                    = local.firewall_policy_rule_collection_group_name
  firewall_policy_rule_collection_group_network_rule_collection = local.firewall_policy_rule_collection_group_network_rule_collection
  firewall_policy_rule_collection_group_priority                = local.firewall_policy_rule_collection_group_priority
}
# Add a log analytics workspace for the firewall logs to do any connectivity troubleshooting if needed.
module "log_analytics_workspace" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.4.2"

  location                                  = azurerm_resource_group.this.location
  name                                      = local.log_analytics_workspace_name
  resource_group_name                       = azurerm_resource_group.this.name
  enable_telemetry                          = var.enable_telemetry
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_sku               = "PerGB2018"
}
# Add DNS resolver with inbound endpoint
module "private_resolver" {
  source  = "Azure/avm-res-network-dnsresolver/azurerm"
  version = "0.8.0"

  location                    = azurerm_resource_group.this.location
  name                        = "example-resolver"
  resource_group_name         = azurerm_resource_group.this.name
  virtual_network_resource_id = module.ai_lz_vnet.resource_id
  inbound_endpoints = {
    "inbound1" = {
      name        = "inbound1"
      subnet_name = module.ai_lz_vnet.subnets["DNSResolverInbound"].name
    }
  }
}
# Create the Private DNS zones and link to the hub VNet
module "private_dns_zones" {
  source   = "Azure/avm-res-network-privatednszone/azurerm"
  version  = "0.3.4"
  for_each = local.private_dns_zones

  domain_name         = each.value.name
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  virtual_network_links = {
    alz_vnet_link = {
      vnetlinkname      = "${module.ai_lz_vnet.name}-link"
      vnetid            = module.ai_lz_vnet.resource_id
      autoregistration  = false
      resolution_policy = "NxDomainRedirect" #doing this since the automation build systems aren't privately connected
    }
  }
}
# Create a jump VM for verifying connectivity to the linked vnet and private connection resources.
resource "random_integer" "zone_index" {
  max = length(local.region_zones)
  min = length(local.region_zones) > 0 ? 1 : 0
}

module "jumpvm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.19.3"

  location = azurerm_resource_group.this.location
  name     = local.jump_vm_name
  network_interfaces = {
    network_interface_1 = {
      name = "${local.jump_vm_name}-nic1"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${local.jump_vm_name}-nic1-ipconfig1"
          private_ip_subnet_resource_id = module.ai_lz_vnet.subnets["JumpboxSubnet"].resource_id
        }
      }
    }
  }
  resource_group_name = azurerm_resource_group.this.name
  zone                = length(local.region_zones) > 0 ? random_integer.zone_index.result : null
  account_credentials = {
    key_vault_configuration = {
      resource_id = module.avm_res_keyvault_vault.resource_id
    }
  }
  enable_telemetry = var.enable_telemetry
  sku_size         = var.jump_vm_definition.sku
  tags             = var.jump_vm_definition.tags

  depends_on = [module.avm_res_keyvault_vault]
}

module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "=0.10.0"

  location                    = azurerm_resource_group.this.location
  name                        = local.kv_name
  resource_group_name         = azurerm_resource_group.this.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true
  network_acls = {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [var.deployer_ip_address]
  }
  role_assignments = {
    deployment_user_secrets = { #give the deployment user access to secrets
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
  wait_for_rbac_before_key_operations = {
    create = "60s"
  }
  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
}
