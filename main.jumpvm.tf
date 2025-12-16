resource "random_integer" "zone_index" {
  count = length(local.region_zones) > 0 ? 1 : 0

  max = length(local.region_zones)
  min = 1
}

module "jumpvm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.20.0"
  count   = var.flag_platform_landing_zone && var.jumpvm_definition.deploy ? 1 : 0

  location = azurerm_resource_group.this.location
  name     = local.jump_vm_name
  network_interfaces = {
    network_interface_1 = {
      name = "${local.jump_vm_name}-nic1"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${local.jump_vm_name}-nic1-ipconfig1"
          private_ip_subnet_resource_id = local.subnet_ids["JumpboxSubnet"]
        }
      }
    }
  }
  resource_group_name = azurerm_resource_group.this.name
  zone                = length(local.region_zones) > 0 ? random_integer.zone_index[0].result : null
  account_credentials = var.genai_key_vault_definition.deploy ? {
    resource_id = module.avm_res_keyvault_vault[0].resource_id
  } : null
  enable_telemetry = var.enable_telemetry
  sku_size         = var.jumpvm_definition.sku
  tags             = var.jumpvm_definition.tags

  depends_on = [module.avm_res_keyvault_vault, azurerm_role_assignment.deployment_user_kv_admin]
}


#TODO
# feature toggle if not required
# credential to vault (ordering issues)
## Move the private endpoint for the vault outside the avm module ?
# Consider adding options for different OS versions


