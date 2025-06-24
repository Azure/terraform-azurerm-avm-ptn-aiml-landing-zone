variable "law_definition" {
  type = object({
    resource_id = optional(string)
    name        = optional(string)
    retention   = optional(number, 30)
    sku         = optional(string, "PerGB2018")
    tags        = optional(map(string), {})
  })
  default     = {}
  description = "Definition of the Log Analytics Workspace to be created. If `resource_id` is provided, the workspace will not be created and the other inputs will be ignored, and the workspace id provided will be used."
}
