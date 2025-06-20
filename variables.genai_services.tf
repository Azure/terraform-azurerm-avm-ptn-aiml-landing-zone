variable "genai_key_vault_definition" {
  type = object({
    name      = optional(string)
    sku       = optional(string, "standard")
    tenant_id = optional(string)
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
    tags = optional(map(string), {})
  })
  default     = {}
  description = "Definition of the Key Vault to be created for GenAI services."
}
