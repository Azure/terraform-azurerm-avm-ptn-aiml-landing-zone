locals {
  ks_ai_search_name = try(var.ks_ai_search_definition.name, null) != null ? var.ks_ai_search_definition.name : (try(var.name_prefix, null) != null ? "${var.name_prefix}-ks-ai-search" : "ai-alz-ks-ai-search")
}
