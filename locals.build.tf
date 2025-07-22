locals {
  build_key_vault_default_role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
  build_key_vault_name = try(var.build_key_vault_definition.name, null) != null ? var.build_key_vault_definition.name : (try(var.name_prefix, null) != null ? "${var.name_prefix}-build-kv-${random_string.name_suffix.result}" : "build-kv-${random_string.name_suffix.result}")
  build_key_vault_role_assignments = merge(
    local.build_key_vault_default_role_assignments,
    var.build_key_vault_definition.role_assignments
  )
  build_vm_name = try(var.buildvm_definition.name, null) != null ? var.buildvm_definition.name : (try(var.name_prefix, null) != null ? "${var.name_prefix}-build" : "ai-alz-buildvm")
}
