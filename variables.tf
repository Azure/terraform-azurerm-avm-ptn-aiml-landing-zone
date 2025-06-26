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
  #TODO: add a validation rule to keep this under 10 characters only alphanumeric lowercase
  type        = string
  default     = null
  description = "Optional Prefix to be used for naming resources. This is useful for ensuring standard naming without requiring a name input for each name."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Map of tags to be assigned to this resource"
}

variable "flag_platform_landing_zone" {
  type        = bool
  default     = true
  description = "Flag to indicate if the platform landing zone is enabled. If true, the module will deploy resources and connect to a platform landing zone hub."
}

variable "flag_split_deployment_persona" {
  type        = string
  default     = "lza"
  description = "Flag to indicate which part to deploy in a split deployment. Valid values are build, or lza. If set to build, the module will deploy the initial vnet, bastion, and build machine resources. If set to platform, the module will deploy the remaining landing zone resources."
}

