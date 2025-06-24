locals {
  log_analytics_workspace_name = try(var.law_definition.name, null) != null ? var.law_definition.name : (try(var.name_prefix, null) != null ? "${var.name_prefix}-law" : "ai-alz-law")
}

