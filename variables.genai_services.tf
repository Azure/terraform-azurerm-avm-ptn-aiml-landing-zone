/*
variable "genai_key_vault_definition" {
  type = object({
    name                = optional(string)
    sku                 = optional(string, "standard")
    role_assignments = optional(map(object({
      enabled = optional(bool, true)
    }), {}))
    tags                = optional(map(string), {})
  })
  description = "Definition of the Key Vault to be created for GenAI services."
  default     = {}
}
*/
