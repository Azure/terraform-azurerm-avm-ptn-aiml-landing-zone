variable "vnet_definition" {
  type = object({
    name          = optional(string)
    address_space = string
    enable_ddos   = optional(bool, false)
    dns_servers   = optional(set(string))
    subnets = optional(map(object({
      enabled        = optional(bool, true)
      name           = optional(string)
      address_prefix = optional(string)
      }
    )), {})
    peer_vnet_resource_id = optional(string)
  })
}

variable "nsgs_definition" {
  type = object({
    name = optional(string)
    security_rules = optional(map(object({
      access                                     = string
      description                                = optional(string)
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(set(string))
      destination_application_security_group_ids = optional(set(string))
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(set(string))
      direction                                  = string
      name                                       = string
      priority                                   = number
      protocol                                   = string
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(set(string))
      source_application_security_group_ids      = optional(set(string))
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(set(string))
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    })))
  })
  default = {}
}

variable "bastion_definition" {
  type = object({
    name  = optional(string)
    sku   = optional(string, "Standard")
    tags  = optional(map(string), {})
    zones = optional(list(string), ["1", "2", "3"])
  })
  default = {}
}

variable "firewall_definition" {
  type = object({
    name  = optional(string)
    sku   = optional(string, "AZFW_VNet")
    tier  = optional(string, "Standard")
    zones = optional(list(string), ["1", "2", "3"])
    tags  = optional(map(string), {})
  })
  default = {}
}

variable "hub_vnet_peering_definition" {
  type = object({
    peer_vnet_resource_id                = optional(string)
    firewall_ip_address                  = optional(string)
    name                                 = optional(string)
    allow_forwarded_traffic              = optional(bool, true)
    allow_gateway_transit                = optional(bool, true)
    allow_virtual_network_access         = optional(bool, true)
    create_reverse_peering               = optional(bool, true)
    reverse_allow_forwarded_traffic      = optional(bool, false)
    reverse_allow_gateway_transit        = optional(bool, false)
    reverse_allow_virtual_network_access = optional(bool, true)
    reverse_name                         = optional(string)
    reverse_use_remote_gateways          = optional(bool, false)
    use_remote_gateways                  = optional(bool, false)
  })
  default = {}
}

variable "private_dns_zones" {
  type = object({
    existing_zones_subscription_id     = optional(string)
    existing_zones_resource_group_name = optional(string)
    network_links = optional(map(object({
      vnetlinkname     = string
      vnetid           = string
      autoregistration = optional(bool, false)
    })), {})
  })
  default = {}
}
