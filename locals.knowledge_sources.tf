locals {
  ks_ai_search_name      = try(var.ks_ai_search_definition.name, null) != null ? var.ks_ai_search_definition.name : (var.name_prefix != null ? "${var.name_prefix}-ks-ai-search" : "ai-alz-ks-ai-search-${random_string.name_suffix.result}")
  ks_bing_grounding_name = try(var.ks_bing_grounding_definition.name, null) != null ? var.ks_bing_grounding_definition.name : (var.name_prefix != null ? "${var.name_prefix}-ks-bing-grounding" : "ai-alz-ks-bing-grounding-${random_string.name_suffix.result}")
}
