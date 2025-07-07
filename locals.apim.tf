locals {
  apim_default_role_assignments = {}
  apim_name                     = try(var.apim_definition.name, null) != null ? var.apim_definition.name : (try(var.name_prefix, null) != null ? "${var.name_prefix}-apim" : "ai-alz-apim")
  apim_role_assignments = merge(
    local.apim_default_role_assignments,
    try(var.apim_definition.role_assignments, {})
  )
}
