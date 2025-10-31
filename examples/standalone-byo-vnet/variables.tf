variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "byo_vnet_id" {
  type        = string
  description = <<DESCRIPTION
The ID of an existing Virtual Network to deploy resources into.
For more information about Azure Virtual Networks see <https://docs.microsoft.com/azure/virtual-network/virtual-networks-overview>.
DESCRIPTION
}

variable "byo_vnet_name" {
  type        = string
  description = <<DESCRIPTION
The name of an existing Virtual Network to deploy resources into.
For more information about Azure Virtual Networks see <https://docs.microsoft.com/azure/virtual-network/virtual-networks-overview>.
DESCRIPTION
}

variable "byo_vnet_resource_group_name" {
  type       = string
  description = <<DESCRIPTION
The name of the resource group that contains the existing Virtual Network.
For more information about Azure Resource Groups see <https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/>.
DESCRIPTION
}

variable "subscription_id" {
  type       = string
  description = <<DESCRIPTION
The ID of the subscription that contains the existing Virtual Network.
For more information about Azure Subscriptions see <https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/understand-subscriptions>.
DESCRIPTION
}