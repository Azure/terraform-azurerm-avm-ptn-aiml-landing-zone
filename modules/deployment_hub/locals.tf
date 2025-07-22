locals {
  bastion_name        = try(var.name_prefix, null) != null ? "${var.name_prefix}-build-bastion" : "ai-alz-build-bastion"
  build_kv_name       = try(var.name_prefix, null) != null ? "${var.name_prefix}-bldkv-${random_string.name_suffix.result}" : "ai-alz-bldkv-${random_string.name_suffix.result}"
  build_vm_name       = try(var.name_prefix, null) != null ? "${var.name_prefix}-tmpbldvm" : "ai-alz-tmpbldvm"
  deployed_subnets    = { for subnet_name, subnet in local.subnets : subnet_name => subnet if subnet.enabled }
  nat_gateway_name    = try(var.name_prefix, null) != null ? "${var.name_prefix}-build-nat-gateway" : "ai-alz-build-nat-gateway"
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
      name             = "BuildVMSubnet"
      address_prefixes = [cidrsubnet(var.vnet_definition.address_space, 2, 1)]
    }
  }
  vnet_name = try(var.name_prefix, null) != null ? "${var.name_prefix}-build-vnet" : "ai-alz-build-vnet"
}
