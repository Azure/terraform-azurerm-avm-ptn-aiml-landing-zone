#TODO: Come up with a standard set of NSG rules for the AI ALZ. This is a starting point.
locals {
  base_nsg_rules = {
    "rule01" = {
      name                         = "Allow-RFC-1918-Any"
      access                       = "Allow"
      destination_address_prefixes = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      destination_port_range       = "*"
      direction                    = "Outbound"
      priority                     = 100
      protocol                     = "*"
      source_address_prefixes      = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      source_port_range            = "*"
    }
  }
  nsg_name = try(var.nsgs_definition.name, null) != null ? var.nsgs_definition.name : (try(var.name_prefix, null) != null ? "${var.name_prefix}-ai-alz-nsg" : "ai-alz-nsg")
  nsg_rules = merge(
    local.base_nsg_rules,
    var.nsgs_definition.security_rules
  )
}
