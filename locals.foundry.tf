locals {
  ai_foundry_name = try(var.ai_foundry_definition.name, null) != null ? var.ai_foundry_definition.name : (try(var.name_prefix, null) != null ? "${var.name_prefix}-ai-foundry-${random_string.name_suffix.result}" : "ai-foundry-${random_string.name_suffix.result}")
}
