variable "app_insights_definition" {
  type = object({
    deploy                        = optional(bool, false)
    resource_id                   = optional(string)
    name                          = optional(string)
    application_type              = optional(string, "web")
    daily_data_cap_in_gb          = optional(number, 100)
    disable_ip_masking            = optional(bool, false)
    internet_ingestion_enabled    = optional(bool, true)
    internet_query_enabled        = optional(bool, true)
    local_authentication_disabled = optional(bool, true)
    retention_in_days             = optional(number, 90)
    allow_mixed_workspaces        = optional(bool, false)
    enable_diagnostic_settings    = optional(bool, false)
    diagnostic_settings = optional(map(object({
      name = optional(string, null)
      logs = optional(set(object({
        category       = optional(string, null)
        category_group = optional(string, null)
        enabled        = optional(bool, true)
        retention_policy = optional(object({
          days    = optional(number, 0)
          enabled = optional(bool, false)
        }), {})
      })), [])
      metrics = optional(set(object({
        category = optional(string, null)
        enabled  = optional(bool, true)
        retention_policy = optional(object({
          days    = optional(number, 0)
          enabled = optional(bool, false)
        }), {})
      })), [])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    tags = optional(map(string))
  })
  default     = {}
  description = <<DESCRIPTION
Configuration for a workspace-based Application Insights component or an existing component.

- `deploy` - (Optional) Deploy a new component when `resource_id` is not supplied. Default is false to preserve existing Terraform deployments.
- `resource_id` - (Optional) Resource ID of an existing Application Insights component. The ID is passed through and no connection string is read or output.
- `name` - (Optional) Component name.
- `application_type` - (Optional) Application type. Default is "web".
- `daily_data_cap_in_gb` - (Optional) Daily data cap. Default is 100.
- `disable_ip_masking` - (Optional) Disable IP masking. Default is false.
- `internet_ingestion_enabled` - (Optional) Allow internet ingestion. Default is true while AMPLS composition remains deferred.
- `internet_query_enabled` - (Optional) Allow internet query. Default is true while AMPLS composition remains deferred.
- `local_authentication_disabled` - (Optional) Disable local authentication. Default is true.
- `retention_in_days` - (Optional) Retention period. Default is 90.
- `allow_mixed_workspaces` - (Optional) Allow reuse of Application Insights without an explicitly reused Log Analytics workspace. Default is false.
- `enable_diagnostic_settings` - (Optional) Enable component diagnostic settings. Default is false.
- `diagnostic_settings` - (Optional) Component diagnostic settings.
- `role_assignments` - (Optional) Component-scoped role assignments.
- `tags` - (Optional) Component tags.
DESCRIPTION
  nullable    = false

  validation {
    condition     = var.app_insights_definition.resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.Insights/components", var.app_insights_definition.resource_id))
    error_message = "`app_insights_definition.resource_id` must be a valid Application Insights component resource ID."
  }
}

variable "law_definition" {
  type = object({
    deploy      = optional(bool, true)
    resource_id = optional(string)
    name        = optional(string)
    retention   = optional(number, 30)
    sku         = optional(string, "PerGB2018")
    tags        = optional(map(string))
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Log Analytics Workspace to be created for monitoring and logging. If no resource_id is provided, and deploy is set to false, then each resource will default to not including diagnostic settings unless an explicit diagnostic_setting value is provided for that resource. Explicitly set resource diagnostic_settings values will always be preferred.
- `deploy` - (Optional) Boolean to indicate whether to deploy a new Log Analytics Workspace if no resource_id is provided. Default is true. Set to false with no resource_id provided to disable automatic diagnostic settings management for all resources (useful when policy-driven diagnostic settings are in place).
- `resource_id` - (Optional) The resource ID of an existing Log Analytics Workspace to use. If provided, the workspace will not be created and the other inputs will be ignored. When set, all resources will automatically be configured to send diagnostics to this workspace unless explicitly overridden.
- `name` - (Optional) The name of the Log Analytics Workspace. If not provided, a name will be generated.
- `retention` - (Optional) The data retention period in days for the workspace. Default is 30.
- `sku` - (Optional) The SKU of the Log Analytics Workspace. Default is "PerGB2018".
- `tags` - (Optional) Map of tags to assign to the Log Analytics Workspace.
DESCRIPTION
}
