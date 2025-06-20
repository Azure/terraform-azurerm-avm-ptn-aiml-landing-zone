locals {
  genai_key_vault_default_role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
  genai_key_vault_name = try(var.genai_key_vault_definition.name, null) != null ? var.genai_key_vault_definition.name : (try(var.name_prefix, null) != null ? "${var.name_prefix}-genai-kv-${random_string.name_suffix.result}" : "genai-kv-${random_string.name_suffix.result}")
  genai_key_vault_role_assignments = merge(
    local.genai_key_vault_default_role_assignments,
    var.genai_key_vault_definition.role_assignments
  )
}
