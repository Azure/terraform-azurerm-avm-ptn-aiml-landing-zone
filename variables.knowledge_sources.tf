variable "ks_ai_search_definition" {
  type = object({
    name                          = optional(string)
    private_dns_zone_resource_id  = optional(string)
    sku                           = optional(string, "standard")
    local_authentication_enabled  = optional(bool, true)
    partition_count               = optional(number, 1)
    public_network_access_enabled = optional(bool, false)
    replica_count                 = optional(number, 2)
    semantic_search_sku           = optional(string, "standard")
    tags                          = optional(map(string), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
    enable_telemetry = optional(bool, true)
  })
  default     = {}
  description = "Definition of the AI Search service to be created as part of the enterprise and public knowledge services."
}
