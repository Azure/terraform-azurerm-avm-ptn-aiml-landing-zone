locals {
  ai_foundry_name = try(var.ai_foundry_definition.name, null) != null ? var.ai_foundry_definition.name : (var.name_prefix != null ? "${var.name_prefix}-ai-foundry-${random_string.name_suffix.result}" : "ai-foundry-${random_string.name_suffix.result}")
  foundry_ai_foundry = merge(
    var.ai_foundry_definition.ai_foundry, {
      name = local.ai_foundry_name
      network_injections = [{
        scenario                   = "agent"
        subnetArmId                = local.subnet_ids["AIFoundrySubnet"]
        useMicrosoftManagedNetwork = false
      }]
      private_dns_zone_resource_ids = compact([
        local.private_dns_zone_resource_map.ai_foundry_openai_zone.id,
        local.private_dns_zone_resource_map.ai_foundry_ai_services_zone.id,
        local.private_dns_zone_resource_map.ai_foundry_cognitive_services_zone.id,
      ])
    }
  )
  foundry_ai_search_definition = { for key, value in var.ai_foundry_definition.ai_search_definition : key => merge(
    var.ai_foundry_definition.ai_search_definition[key], {
      private_dns_zone_resource_id = local.private_dns_zone_resource_map.id,
    }
  ) }
  foundry_cosmosdb_definition = { for key, value in var.ai_foundry_definition.cosmosdb_definition : key => merge(
    var.ai_foundry_definition.cosmosdb_definition[key], {
      private_dns_zone_resource_id = local.private_dns_zone_resource_map.id,
    }
  ) }
  foundry_key_vault_definition = { for key, value in var.ai_foundry_definition.key_vault_definition : key => merge(
    var.ai_foundry_definition.key_vault_definition[key], {
      private_dns_zone_resource_id = local.private_dns_zone_resource_map.id,
    }
  ) }
  foundry_storage_account_definition = { for key, value in var.ai_foundry_definition.storage_account_definition : key => merge(
    var.ai_foundry_definition.storage_account_definition[key], {
      endpoints = {
        for ek, ev in value.endpoints :
        ek => {
          private_dns_zone_resource_id = local.private_dns_zone_resource_map["storage_${lower(ek)}_zone"].id,
          type                         = lower(ek)
        }
      }
    }
  ) }
}

