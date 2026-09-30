variable "security_definition" {
  type = object({
    deployment_principal_id                                 = optional(string)
    deployment_principal_type                               = optional(string)
    grant_deployment_principal_app_configuration_data_owner = optional(bool, false)
    workload_managed_identities = optional(map(object({
      principal_id                  = string
      app_configuration_data_reader = optional(bool, false)
      container_registry_pull       = optional(bool, false)
      key_vault_secrets_user        = optional(bool, false)
    })), {})
  })
  default     = {}
  description = <<DESCRIPTION
Security and identity-based RBAC configuration for the landing zone.

- `deployment_principal_id` - (Optional) Object ID of the principal that deploys and administers the landing zone. When omitted, the object ID from the current AzureRM client configuration is used.
- `deployment_principal_type` - (Optional) Type of the deployment principal. Valid values are `User`, `Group`, and `ServicePrincipal`. Leave null when Azure should infer the principal type.
- `grant_deployment_principal_app_configuration_data_owner` - (Optional) Grant the deployment principal the App Configuration Data Owner role on the GenAI App Configuration store. Default is false.
- `workload_managed_identities` - (Optional) Map of existing system-assigned or user-assigned managed identity principal IDs and the least-privilege data-plane roles to automate. This module does not create workload identities.
  - `principal_id` - Principal ID of the managed identity.
  - `app_configuration_data_reader` - (Optional) Grant App Configuration Data Reader on the GenAI App Configuration store. Default is false.
  - `container_registry_pull` - (Optional) Grant AcrPull on the GenAI Container Registry. Default is false.
  - `key_vault_secrets_user` - (Optional) Grant Key Vault Secrets User on the GenAI Key Vault. Default is false. This grants access only; it does not create or return secrets.
DESCRIPTION

  validation {
    condition = (
      var.security_definition.deployment_principal_id == null ||
      trimspace(var.security_definition.deployment_principal_id) != ""
    )
    error_message = "The deployment_principal_id must be a non-empty string or null."
  }
  validation {
    condition = (
      var.security_definition.deployment_principal_type == null ||
      contains(["User", "Group", "ServicePrincipal"], var.security_definition.deployment_principal_type)
    )
    error_message = "The deployment_principal_type must be one of: 'User', 'Group', 'ServicePrincipal', or null."
  }
  validation {
    condition = alltrue([
      for identity in values(var.security_definition.workload_managed_identities) :
      trimspace(identity.principal_id) != ""
    ])
    error_message = "Each workload_managed_identities principal_id must be a non-empty string."
  }
  validation {
    condition = alltrue([
      for identity in values(var.security_definition.workload_managed_identities) :
      identity.app_configuration_data_reader || identity.container_registry_pull || identity.key_vault_secrets_user
    ])
    error_message = "Each workload_managed_identities entry must enable at least one supported role."
  }
  validation {
    condition = (
      length(distinct([
        for identity in values(var.security_definition.workload_managed_identities) :
        identity.principal_id
      ])) == length(var.security_definition.workload_managed_identities)
    )
    error_message = "Each workload_managed_identities principal_id must be unique."
  }
}
