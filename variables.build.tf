/*
variable "build_key_vault_definition" {
  type = object({
    name      = optional(string)
    sku       = optional(string, "standard")
    tenant_id = optional(string)
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
Configuration object for the Azure Key Vault to be created for build services.

- `name` - (Optional) The name of the Key Vault. If not provided, a name will be generated.
- `sku` - (Optional) The SKU of the Key Vault. Default is "standard".
- `tenant_id` - (Optional) The tenant ID for the Key Vault. If not provided, the current tenant will be used.
- `role_assignments` - (Optional) Map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `role_definition_id_or_name` - The role definition ID or name to assign.
  - `principal_id` - The principal ID to assign the role to.
  - `description` - (Optional) Description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
  - `condition` - (Optional) Condition for the role assignment.
  - `condition_version` - (Optional) Version of the condition.
  - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
  - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
- `tags` - (Optional) Map of tags to assign to the Key Vault.
DESCRIPTION
}
*/
variable "buildvm_definition" {
  type = object({
    name             = optional(string)
    sku              = optional(string, "Standard_B2s")
    tags             = optional(map(string), {})
    enable_telemetry = optional(bool, true)
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Build VM to be created for managing the implementation services.

- `name` - (Optional) The name of the Build VM. If not provided, a name will be generated.
- `sku` - (Optional) The VM size/SKU for the Build VM. Default is "Standard_B2s".
- `tags` - (Optional) Map of tags to assign to the Build VM.
- `enable_telemetry` - (Optional) Whether telemetry is enabled for the Build VM module. Default is true.
DESCRIPTION
}
