
data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

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

resource "azurerm_public_ip" "bastionpip" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.this.location
  name                = "${local.bastion_name}-pip"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  location            = azurerm_resource_group.this.location
  name                = local.bastion_name
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                 = "${local.bastion_name}-ipconf"
    public_ip_address_id = azurerm_public_ip.bastionpip.id
    subnet_id            = module.ai_lz_vnet.subnets["AzureBastionSubnet"].resource_id
  }
}

module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "=0.10.0"

  location                    = azurerm_resource_group.this.location
  name                        = local.build_kv_name
  resource_group_name         = azurerm_resource_group.this.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
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

module "buildvm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.19.3"

  location = azurerm_resource_group.this.location
  name     = local.build_vm_name
  network_interfaces = {
    network_interface_1 = {
      name = "${local.build_vm_name}-nic1"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${local.build_vm_name}-nic1-ipconfig1"
          private_ip_subnet_resource_id = module.ai_lz_vnet.subnets["JumpboxSubnet"].resource_id
        }
      }
    }
  }
  resource_group_name = azurerm_resource_group.this.name
  zone                = null
  account_credentials = {
    key_vault_configuration = {
      resource_id = module.avm_res_keyvault_vault.resource_id
      secret_configuration = {
        name = "azureuser-password"
      }
    }
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
  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  tags = var.buildvm_definition.tags

  depends_on = [module.avm_res_keyvault_vault]
}

