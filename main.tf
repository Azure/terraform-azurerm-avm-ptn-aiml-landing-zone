resource "azapi_resource" "this" {
  location               = var.location
  name                   = var.resource_group_name
  parent_id              = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  type                   = var.resource_types.resources_resource_groups
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.resources_resource_groups) > 0 ? var.ignore_body_changes.resources_resource_groups : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

# used to randomize resource names that are globally unique
resource "random_string" "name_suffix" {
  length  = 4
  special = false
  upper   = false
}

# AzAPI issue #981 can resolve CLI credentials instead of the configured provider identity.
# Remove this exception when https://github.com/Azure/terraform-provider-azapi/issues/981 is fixed.
# tflint-ignore: provider_azurerm_disallowed
data "azurerm_client_config" "current" {}

module "avm_utl_regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.2"
}
