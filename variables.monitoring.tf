variable "law_definition" {
  type = object({
    name      = optional(string)
    retention = optional(number, 30)
    sku       = optional(string, "PerGB2018")
    tags      = optional(map(string), {})
  })
  default     = {}
  description = "Definition of the Log Analytics Workspace to be created."
}
