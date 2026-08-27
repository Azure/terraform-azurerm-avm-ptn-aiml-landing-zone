moved {
  from = azurerm_nat_gateway.this
  to   = azapi_resource.this
}

moved {
  from = azurerm_public_ip.this["primary"]
  to   = azapi_resource.public_ip
}

removed {
  from = azurerm_nat_gateway_public_ip_association.this

  lifecycle {
    destroy = false
  }
}

resource "azapi_resource" "public_ip" {
  location  = var.location
  name      = var.public_ip_name
  parent_id = var.parent_id
  type      = var.resource_types.network_public_ip_addresses
  body = {
    properties = {
      idleTimeoutInMinutes     = 30
      publicIPAddressVersion   = "IPv4"
      publicIPAllocationMethod = "Static"
    }
    sku = {
      name = "Standard"
      tier = "Regional"
    }
    zones = length(var.zones) == 0 ? ["1", "2", "3"] : sort(tolist(var.zones))
  }
  tags = var.tags

  create_headers         = var.telemetry_headers
  delete_headers         = var.telemetry_headers
  ignore_body_changes    = length(var.ignore_body_changes.network_public_ip_addresses) > 0 ? var.ignore_body_changes.network_public_ip_addresses : null
  read_headers           = var.telemetry_headers
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.telemetry_headers

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.network_nat_gateways
  body = {
    properties = {
      idleTimeoutInMinutes = var.idle_timeout_in_minutes
      publicIpAddresses = [
        {
          id = azapi_resource.public_ip.id
        }
      ]
    }
    sku = {
      name = "Standard"
    }
    zones = length(var.zones) == 0 ? null : sort(tolist(var.zones))
  }
  tags = var.tags

  create_headers         = var.telemetry_headers
  delete_headers         = var.telemetry_headers
  ignore_body_changes    = length(var.ignore_body_changes.network_nat_gateways) > 0 ? var.ignore_body_changes.network_nat_gateways : null
  read_headers           = var.telemetry_headers
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.telemetry_headers

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
