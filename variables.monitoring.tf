variable "law_definition" {
  type = object({
    deploy      = optional(bool, true)
    resource_id = optional(string)
    name        = optional(string)
    retention   = optional(number, 30)
    sku         = optional(string, "PerGB2018")
    tags        = optional(map(string), {})
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Log Analytics Workspace to be created for monitoring and logging. If no resource_id is provided, and deploy is set to false, then each resource will default to not including diagnostic settings unless an explicit diagnostic_setting value is provided for that resource. Explicitly set resource diagnostic_settings values will always be preferred.
- `deploy` - (Optional) Boolean to indicate whether to deploy a new Log Analytics Workspace if no resource_id is provided. Default is true.
- `resource_id` - (Optional) The resource ID of an existing Log Analytics Workspace to use. If provided, the workspace will not be created and the other inputs will be ignored.
- `name` - (Optional) The name of the Log Analytics Workspace. If not provided, a name will be generated.
- `retention` - (Optional) The data retention period in days for the workspace. Default is 30.
- `sku` - (Optional) The SKU of the Log Analytics Workspace. Default is "PerGB2018".
- `tags` - (Optional) Map of tags to assign to the Log Analytics Workspace.
DESCRIPTION
}
