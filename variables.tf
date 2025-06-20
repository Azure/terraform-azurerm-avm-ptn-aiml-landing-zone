variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "name_prefix" {
  type        = string
  default     = null
  description = "Optional Prefix to be used for naming resources. This is useful for ensuring standard naming without requiring a name input for each name."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Map of tags to be assigned to this resource"
}
