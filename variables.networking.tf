variable "vnet_definition" {
  type = object({
    name          = optional(string)
    address_space = string
    enable_ddos   = optional(bool, false)
    subnets = optional(map(object({
      enabled        = optional(bool, true)
      name           = optional(string)
      address_prefix = optional(string)
      dns_servers    = optional(list(string))
      }
    )), {})
  })
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

variable "flag_platform_landing_zone" {
  type        = bool
  default     = true
  description = "Flag to indicate if the platform landing zone is enabled. If true, the module will deploy resources in a platform landing zone."
}
