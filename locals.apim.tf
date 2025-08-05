locals {
  apim_default_role_assignments = {}
  apim_name                     = try(var.apim_definition.name, null) != null ? var.apim_definition.name : (var.name_prefix != null ? "${var.name_prefix}-apim-${random_string.name_suffix.result}" : "ai-alz-apim-${random_string.name_suffix.result}")
  apim_role_assignments = merge(
    local.apim_default_role_assignments,
    try(var.apim_definition.role_assignments, {})
  )
}
