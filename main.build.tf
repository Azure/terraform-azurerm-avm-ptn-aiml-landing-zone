module "buildvm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.20.0"
  count   = var.flag_platform_landing_zone && var.buildvm_definition.deploy ? 1 : 0

  location = azurerm_resource_group.this.location
  name     = local.build_vm_name
  network_interfaces = {
    network_interface_1 = {
      name = "${local.build_vm_name}-nic1"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${local.build_vm_name}-nic1-ipconfig1"
          private_ip_subnet_resource_id = local.subnet_ids["DevOpsBuildSubnet"]
        }
      }
    }
  }
  resource_group_name = azurerm_resource_group.this.name
  zone                = length(local.region_zones) > 0 ? random_integer.zone_index[0].result : null
  account_credentials = {
    key_vault_configuration = var.genai_key_vault_definition.deploy ? {
      resource_id = module.avm_res_keyvault_vault[0].resource_id
      secret_configuration = {
        name = "azureuser-password"
      }
    } : null
    password_authentication_disabled = false
  }
  enable_telemetry = var.enable_telemetry
  managed_identities = {
    system_assigned = true
  }
  os_type = "Linux"
  role_assignments_system_managed_identity = {
    rg_owner = {
      scope_resource_id          = azurerm_resource_group.this.id
      role_definition_id_or_name = "Owner"
      description                = "Assign the owner role to the build machine's system assigned identity on the resource group."
    }
  }
  sku_size = var.buildvm_definition.sku
  source_image_reference = { #TODO: Determine if we want to provide flexibility for the VM sku type being created
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  tags = var.buildvm_definition.tags
}

