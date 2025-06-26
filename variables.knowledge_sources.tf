variable "ks_ai_search_definition" {
  type = object({
    name                = optional(string)
    sku                 = optional(string, "Standard")
    tags                = optional(map(string), {})
    enable_telemetry    = optional(bool, true)
  })
  default     = {}
  description = "Definition of the AI Search service to be created as part of the enterprise and public knowledge services."
}
