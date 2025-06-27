variable "container_app_environment_definition" {
  type = object({
    name                                = optional(string)
    tags                                = optional(map(string), {})
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
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
  })
  default     = {}
  description = "Definition of the Container App Environment to be created for GenAI services."
}
