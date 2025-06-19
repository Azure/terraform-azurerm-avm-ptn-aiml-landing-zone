

module "ai_lz_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.7.1"

  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_definition.address_space]
  name                = var.vnet_definition.name
  location            = azurerm_resource_group.this.location
  enable_telemetry    = var.enable_telemetry

  subnets = local.deployed_subnets
}

module "firewall_route_table" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.4.1"

  resource_group_name = azurerm_resource_group.this.name
  name                = local.route_table_name
  location            = azurerm_resource_group.this.location

  bgp_route_propagation_enabled = true

  /*
  routes = {
    default = {
      name                   = "default"
      address_prefix         = "0.0.0.0/0"
      next_hop_type         = var.firewall_ip_address
    }
  }
  */
}

