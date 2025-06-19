variable "vnet_definition" {
  type = object({
    name          = string
    address_space = string
    enable_ddos   = optional(bool, false)
    subnets = optional(map(object({
      enabled         = optional(bool, true)
      name            = string
      address_prefix  = optional(string)
      dns_servers     = optional(list(string))
      udr_to_firewall = optional(bool, false)
      }
    )), {})
  })
}
