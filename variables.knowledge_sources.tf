variable "ks_ai_search_definition" {
  type = object({
    deploy                        = optional(bool, true)
    name                          = optional(string)
    enable_diagnostic_settings    = optional(bool, true)
    sku                           = optional(string, "standard")
    local_authentication_enabled  = optional(bool, true)
    partition_count               = optional(number, 1)
    public_network_access_enabled = optional(bool, false)
    replica_count                 = optional(number, 2)
    semantic_search_sku           = optional(string, "standard")
    tags                          = optional(map(string))
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
    enable_telemetry = optional(bool, true)
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure AI Search service to be created as part of the enterprise and public knowledge services.

- `deploy` - (Optional) Deploy the AI Search service. Default is true.
- `name` - (Optional) The name of the AI Search service. If not provided, a name will be generated.
- `sku` - (Optional) The SKU of the AI Search service. Default is "standard".
- `local_authentication_enabled` - (Optional) Whether local authentication is enabled. Default is true.
- `partition_count` - (Optional) The number of partitions for the search service. Default is 1.
- `public_network_access_enabled` - (Optional) Whether public network access is enabled. Default is false.
- `replica_count` - (Optional) The number of replicas for the search service. Default is 2.
- `semantic_search_sku` - (Optional) The SKU for semantic search capabilities. Default is "standard".
- `tags` - (Optional) Map of tags to assign to the AI Search service.
- `role_assignments` - (Optional) Map of role assignments to create on the AI Search service. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `role_definition_id_or_name` - The role definition ID or name to assign.
  - `principal_id` - The principal ID to assign the role to.
  - `description` - (Optional) Description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
  - `condition` - (Optional) Condition for the role assignment.
  - `condition_version` - (Optional) Version of the condition.
  - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
  - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
- `enable_telemetry` - (Optional) Whether telemetry is enabled for the AI Search module. Default is true.
DESCRIPTION
}

variable "ks_bing_grounding_definition" {
  type = object({
    deploy = optional(bool, true)
    name   = optional(string)
    sku    = optional(string, "G1")
    tags   = optional(map(string))
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Bing Grounding service to be created as part of the enterprise and public knowledge services.

- `deploy` - (Optional) Deploy the Bing Ground service. Default is true.
- `name` - (Optional) The name of the Bing Grounding service. If not provided, a name will be generated.
- `sku` - (Optional) The SKU of the Bing Grounding service. Default is "G1".
- `tags` - (Optional) Map of tags to assign to the Bing Grounding service.
DESCRIPTION
}
