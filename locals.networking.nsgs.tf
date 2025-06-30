locals {
  nsg_name = try(var.nsgs_definition.name, null) != null ? var.nsgs_definition.name : (try(var.name_prefix, null) != null ? "${var.name_prefix}-ai-alz-nsg" : "ai-alz-nsg")
  base_nsg_rules = {
    "rule01" = {
      name                         = "Allow-RFC-1918-Any"
      access                       = "Allow"
      destination_address_prefixes = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      destination_port_range       = "Any"
      direction                    = "Outbound"
      priority                     = 100
      protocol                     = "Any"
      source_address_prefix        = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      source_port_range            = "*"
    }
  }

  nsg_rules = merge(
    local.base_nsg_rules,
    var.nsgs_definition.security_rules
  )
}
