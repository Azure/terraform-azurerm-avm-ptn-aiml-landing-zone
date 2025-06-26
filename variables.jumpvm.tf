variable "jumpvm_definition" {
  type = object({
    name                = optional(string)
    sku                 = optional(string, "Standard_B2s")
    tags                = optional(map(string), {})
    enable_telemetry    = optional(bool, true)
  })
  default     = {}
  description = "Definition of the Jump VM to be created for managing the implementation services."

}
