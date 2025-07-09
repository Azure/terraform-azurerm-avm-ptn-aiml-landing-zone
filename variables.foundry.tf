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
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure AI Foundry project and related resources.

- `ai_foundry_project_description` - (Optional) Description for the AI Foundry project. Default is "AI Foundry project for agent services and AI workloads".
- `ai_model_deployments` - (Optional) Map of AI model deployments to create. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - The name of the model deployment.
  - `rai_policy_name` - (Optional) The name of the Responsible AI policy to apply.
  - `version_upgrade_option` - (Optional) Version upgrade option for the model. Default is "OnceNewDefaultVersionAvailable".
  - `model` - The model configuration.
    - `format` - The format of the model.
    - `name` - The name of the model.
    - `version` - The version of the model.
  - `scale` - The scaling configuration for the model.
    - `capacity` - (Optional) The capacity for the deployment.
    - `family` - (Optional) The family for the deployment.
    - `size` - (Optional) The size for the deployment.
    - `tier` - (Optional) The tier for the deployment.
    - `type` - The type of scaling (e.g., "Standard", "Manual").
- `create_ai_agent_service` - (Optional) Whether to create AI agent services. Default is false.
- `create_project_connections` - (Optional) Whether to create project connections. Default is false.
- `lock` - (Optional) Resource lock configuration.
  - `kind` - The type of lock (e.g., "CanNotDelete", "ReadOnly").
  - `name` - (Optional) The name of the lock. If not provided, a name will be generated.
- `ai_foundry_resources` - (Optional) Configuration for AI Foundry dependent resources.
  - `create_dependent_resources` - (Optional) Whether to create dependent resources. Default is true.
  - `ai_search` - (Optional) AI Search service configuration.
    - `existing_resource_id` - (Optional) Resource ID of an existing AI Search service to use.
    - `name` - (Optional) Name for the AI Search service if creating new.
  - `cosmos_db` - (Optional) Cosmos DB configuration.
    - `existing_resource_id` - (Optional) Resource ID of an existing Cosmos DB account to use.
    - `name` - (Optional) Name for the Cosmos DB account if creating new.
  - `storage_account` - (Optional) Storage account configuration.
    - `existing_resource_id` - (Optional) Resource ID of an existing storage account to use.
    - `name` - (Optional) Name for the storage account if creating new.
  - `key_vault` - (Optional) Key Vault configuration.
    - `existing_resource_id` - (Optional) Resource ID of an existing Key Vault to use.
    - `name` - (Optional) Name for the Key Vault if creating new.
- `role_assignments` - (Optional) Map of role assignments to create on the AI Foundry resources. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `role_definition_id_or_name` - The role definition ID or name to assign.
  - `principal_id` - The principal ID to assign the role to.
  - `description` - (Optional) Description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
  - `condition` - (Optional) Condition for the role assignment.
  - `condition_version` - (Optional) Version of the condition.
  - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
  - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
- `tags` - (Optional) Map of tags to assign to the AI Foundry resources.
DESCRIPTION
}
