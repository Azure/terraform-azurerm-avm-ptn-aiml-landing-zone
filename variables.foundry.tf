variable "ai_foundry_definition" {
  type = object({
    ai_foundry_project_description = optional(string, "AI Foundry project for agent services and AI workloads")
    ai_model_deployments = optional(map(object({
      name                   = string
      rai_policy_name        = optional(string)
      version_upgrade_option = optional(string, "OnceNewDefaultVersionAvailable")
      model = object({
        format  = string
        name    = string
        version = string
      })
      scale = object({
        capacity = optional(number)
        family   = optional(string)
        size     = optional(string)
        tier     = optional(string)
        type     = string
      })
    })), {})
    create_ai_agent_service    = optional(bool, false)
    create_project_connections = optional(bool, false)
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)

    ai_foundry_resources = optional(object({
      create_dependent_resources = optional(bool, true)
      ai_search = optional(object({
        existing_resource_id = optional(string, null)
        name                 = optional(string, null)
        #create_private_endpoint = optional(bool, true)
      }), {}),
      cosmos_db = optional(object({
        existing_resource_id = optional(string, null)
        name                 = optional(string, null)
        #create_private_endpoint = optional(bool, true)
      }), {}),
      storage_account = optional(object({
        existing_resource_id = optional(string, null)
        name                 = optional(string, null)
        #create_private_endpoint = optional(bool, true)
      }), {}),
      key_vault = optional(object({
        existing_resource_id = optional(string, null)
        name                 = optional(string, null)
        #create_private_endpoint = optional(bool, true)
      }), {})
    }))
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
    tags = optional(map(string), {})
  })
}
