variable "jumpvm_definition" {
  type = object({
    deploy           = optional(bool, true)
    name             = optional(string)
    sku              = optional(string, "Standard_B2s")
    tags             = optional(map(string))
    enable_telemetry = optional(bool, true)
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Jump VM to be created for managing the implementation services.

- `name` - (Optional) The name of the Jump VM. If not provided, a name will be generated.
- `sku` - (Optional) The VM size/SKU for the Jump VM. Default is "Standard_B2s".
- `tags` - (Optional) Map of tags to assign to the Jump VM.
- `enable_telemetry` - (Optional) Whether telemetry is enabled for the Jump VM module. Default is true.
DESCRIPTION
}
