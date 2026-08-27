variable "location" {
  type        = string
  description = "The Azure region in which to create the NAT Gateway and its public IP address."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the NAT Gateway."
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = "The resource ID of the resource group in which to create the NAT Gateway and its public IP address."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "parent_id must be a valid resource group resource ID."
  }
}

variable "public_ip_name" {
  type        = string
  description = "The name of the Standard, static public IP address associated with the NAT Gateway."
  nullable    = false
}

variable "idle_timeout_in_minutes" {
  type        = number
  default     = 4
  description = "The NAT Gateway idle timeout in minutes."
  nullable    = false

  validation {
    condition     = var.idle_timeout_in_minutes >= 4 && var.idle_timeout_in_minutes <= 120
    error_message = "idle_timeout_in_minutes must be between 4 and 120."
  }
}

variable "zones" {
  type        = set(string)
  default     = []
  description = "Zero or one availability zone for the Standard NAT Gateway. With no explicit NAT zone, its Standard public IP is zone-redundant across zones 1, 2, and 3; with one zone, the public IP uses the same zone."
  nullable    = false

  validation {
    condition     = length(var.zones) <= 1 && alltrue([for zone in var.zones : contains(["1", "2", "3"], zone)])
    error_message = "zones must be empty or contain exactly one of \"1\", \"2\", or \"3\" for the Standard NAT Gateway SKU."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "A map of tags to assign to the NAT Gateway and public IP address."
}

variable "telemetry_headers" {
  type        = map(string)
  default     = null
  description = "Optional request headers used to propagate the parent module's AVM telemetry settings."
}

variable "resource_types" {
  type = object({
    network_nat_gateways        = optional(string, "Microsoft.Network/natGateways@2025-05-01")
    network_public_ip_addresses = optional(string, "Microsoft.Network/publicIPAddresses@2025-05-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by this module.

- `network_nat_gateways` - Resource type and API version for the NAT Gateway.
- `network_public_ip_addresses` - Resource type and API version for the public IP address.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = list(string)
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Retry configuration applied to the NAT Gateway and public IP AzAPI resources."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = "Per-operation timeouts applied to the NAT Gateway and public IP AzAPI resources."
}

variable "ignore_body_changes" {
  type = object({
    network_nat_gateways        = optional(list(string), [])
    network_public_ip_addresses = optional(list(string), [])
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Body-relative dot-notation paths to ignore for each AzAPI resource. Ignored configuration is not sent to Azure until its path is removed, and changes take effect only after apply.

- `network_nat_gateways` - Paths ignored on the NAT Gateway.
- `network_public_ip_addresses` - Paths ignored on the public IP address.
DESCRIPTION
}
