variable "container_app_environment_definition" {
  type = object({
    deploy                              = optional(bool, true)
    name                                = optional(string)
    enable_diagnostic_settings          = optional(bool, true)
    tags                                = optional(map(string))
    internal_load_balancer_enabled      = optional(bool, true)
    log_analytics_workspace_resource_id = optional(string)
    zone_redundancy_enabled             = optional(bool, true)
    user_assigned_managed_identity_ids  = optional(list(string), [])
    workload_profile = optional(list(object({
      name                  = string
      workload_profile_type = string
      })), [{
      name                  = "Consumption"
      workload_profile_type = "Consumption"
    }])
    app_logs_configuration = optional(object({
      destination = string
      log_analytics = optional(object({
        customer_id = string
        shared_key  = string
      }), null)
    }), null)

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
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Container App Environment to be created for GenAI services.

- `deploy` - (Optional) Whether to deploy the Container App Environment. Default is true.
- `name` - (Optional) The name of the Container App Environment. If not provided, a name will be generated.
- `enable_diagnostic_settings` - (Optional) Whether diagnostic settings are enabled. Default is true.
- `tags` - (Optional) Map of tags to assign to the Container App Environment.
- `internal_load_balancer_enabled` - (Optional) Whether the load balancer is internal. Default is true.
- `log_analytics_workspace_resource_id` - (Optional) Resource ID of the Log Analytics workspace for logging.
- `zone_redundancy_enabled` - (Optional) Whether zone redundancy is enabled. Default is true.
- `user_assigned_managed_identity_ids` - (Optional) List of user-assigned managed identity resource IDs.
- `workload_profile` - (Optional) List of workload profiles for the Container App Environment.
  - `name` - The name of the workload profile.
  - `workload_profile_type` - The type of workload profile (e.g., "Consumption", "Dedicated").
- `app_logs_configuration` - (Optional) Application logs configuration.
  - `destination` - The destination for application logs.
  - `log_analytics` - (Optional) Log Analytics configuration when destination is "log-analytics".
    - `customer_id` - The Log Analytics workspace customer ID.
    - `shared_key` - The Log Analytics workspace shared key.
- `role_assignments` - (Optional) Map of role assignments to create on the Container App Environment. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `role_definition_id_or_name` - The role definition ID or name to assign.
  - `principal_id` - The principal ID to assign the role to.
  - `description` - (Optional) Description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
  - `condition` - (Optional) Condition for the role assignment.
  - `condition_version` - (Optional) Version of the condition.
  - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
  - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
DESCRIPTION
}
