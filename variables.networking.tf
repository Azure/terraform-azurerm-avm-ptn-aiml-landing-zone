variable "vnet_definition" {
  type = object({
    name          = optional(string)
    address_space = string
    enable_ddos   = optional(bool, false)
    dns_servers   = optional(list(string))
    subnets = optional(map(object({
      enabled        = optional(bool, true)
      name           = optional(string)
      address_prefix = optional(string)
      }
    )), {})
    peer_vnet_resource_id = optional(string)
  })
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

variable "bastion_definition" {
  type = object({
    name  = optional(string)
    sku   = optional(string, "Standard")
    tags  = optional(map(string), {})
    zones = optional(list(string), ["1", "2", "3"])
  })
  default = {}
}

variable "dns_zones_network_links" {
  type = map(object({
    vnetlinkname     = string
    vnetid           = string
    autoregistration = optional(bool, false)
  }))
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

