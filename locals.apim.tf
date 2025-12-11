locals {
  apim_default_role_assignments = {}
  apim_name                     = try(var.apim_definition.name, null) != null ? var.apim_definition.name : (var.name_prefix != null ? "${var.name_prefix}-apim-${random_string.name_suffix.result}" : "ai-alz-apim-${random_string.name_suffix.result}")
  apim_network_options = {
    # For Developer and Premium, a return route for the APIManagement tag is required in the UDRs on the subnet to prevent asymmetric routing issues.
    # Service endpoints are also recommended for these SKUs to improve connectivity reliability.
    # An NSG rule is required to allow the API Management plane to connect to the instances on port 3433.
    # Private Endpoints cannot be used with these SKUs when vnet integration is enabled.
    "Developer" = {
      management_return_via_internet = (var.apim_definition.virtual_network_integration.management_return_via_internet != null ?
        var.apim_definition.virtual_network_integration.management_return_via_internet :
        var.apim_definition.virtual_network_integration.enabled
      )
      public_network_access_enabled = true
      use_nsg                       = var.apim_definition.virtual_network_integration.enabled
      use_private_endpoint          = !var.apim_definition.virtual_network_integration.enabled
      use_service_delegation        = false
      use_service_endpoints = (var.apim_definition.virtual_network_integration.service_endpoints != null ?
        var.apim_definition.virtual_network_integration.service_endpoints :
        var.apim_definition.virtual_network_integration.enabled
      )
      use_virtual_network_subnet_id = var.apim_definition.virtual_network_integration.enabled
      virtual_network_type = (var.apim_definition.virtual_network_integration.enabled ?
        var.apim_definition.virtual_network_integration.public ? "External" : "Internal" :
        "None"
      )
    }
    "Premium" = {
      management_return_via_internet = (var.apim_definition.virtual_network_integration.management_return_via_internet != null ?
        var.apim_definition.virtual_network_integration.management_return_via_internet :
        var.apim_definition.virtual_network_integration.enabled
      )
      public_network_access_enabled = true
      use_nsg                       = var.apim_definition.virtual_network_integration.enabled
      use_private_endpoint          = !var.apim_definition.virtual_network_integration.enabled
      use_service_delegation        = false
      use_service_endpoints = (var.apim_definition.virtual_network_integration.service_endpoints != null ?
        var.apim_definition.virtual_network_integration.service_endpoints :
        var.apim_definition.virtual_network_integration.enabled
      )
      use_virtual_network_subnet_id = var.apim_definition.virtual_network_integration.enabled
      virtual_network_type = (var.apim_definition.virtual_network_integration.enabled ?
        var.apim_definition.virtual_network_integration.public ? "External" : "Internal" :
        "None"
      )
    }
    # V2 is much cleaner, type is always External when vnet is enabled and the routing/nsg are not needed.
    "StandardV2" = {
      management_return_via_internet = false
      public_network_access_enabled  = var.apim_definition.virtual_network_integration.public
      use_nsg                        = false
      use_private_endpoint           = true
      use_service_delegation         = true
      use_service_endpoints          = false
      use_virtual_network_subnet_id  = var.apim_definition.virtual_network_integration.enabled
      virtual_network_type           = var.apim_definition.virtual_network_integration.enabled ? "External" : "None"
    }
    "PremiumV2" = {
      management_return_via_internet = false
      public_network_access_enabled  = var.apim_definition.virtual_network_integration.public
      use_nsg                        = false
      use_private_endpoint           = true
      use_service_delegation         = true
      use_service_endpoints          = false
      use_virtual_network_subnet_id  = var.apim_definition.virtual_network_integration.enabled
      virtual_network_type           = var.apim_definition.virtual_network_integration.enabled ? "External" : "None"
    }
  }
  apim_networking = lookup(local.apim_network_options, var.apim_definition.sku_root, {
    management_return_via_internet = false
    public_network_access_enabled  = true
    use_nsg                        = false
    use_service_delegation         = false
    use_service_endpoints          = false
    use_private_endpoint           = true
    use_virtual_network_subnet_id  = false
    virtual_network_type           = "None"
  })
  apim_role_assignments = merge(
    local.apim_default_role_assignments,
    try(var.apim_definition.role_assignments, {})
  )
  apim_zones = (var.apim_definition.zones == null || length(var.apim_definition.zones) > 0 ? var.apim_definition.zones :
    contains(["Premium"], var.apim_definition.sku_root) ?
    range(1, max([
      for z in local.region_zones : z
      if(var.apim_definition.sku_capacity % z) == 0
    ]...) + 1)
    : null
  )
}
