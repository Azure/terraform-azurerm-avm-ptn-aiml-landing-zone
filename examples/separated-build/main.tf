## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

module "build" {
  source = "../../modules/deployment_hub"

  location            = module.regions.regions[random_integer.region_index.result].name
  resource_group_name = "${module.naming.resource_group.name_unique}"
  vnet_definition = {
    name          = "temp-build-vnet"
    address_space = "10.10.0.0/24"
  }
  enable_telemetry = var.enable_telemetry
  name_prefix      = "${module.naming.resource_group.name_unique}-build"
}

