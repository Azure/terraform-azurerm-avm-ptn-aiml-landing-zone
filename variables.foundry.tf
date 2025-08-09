## Passing most of the Foundry Pattern module's inputs in here to allow for flexibility.
#TODO: remove DNS zone ID's injection for everything.  This comes in as an RG id where the
variable "ai_foundry_definition" {
  type = object({
    # AI Foundry Hub Configuration
    create_byor      = optional(bool, true)
    purge_on_destroy = optional(bool, false)
    ai_foundry = optional(object({
      name                     = optional(string, null)
      disable_local_auth       = optional(bool, false)
      allow_project_management = optional(bool, true)
      create_ai_agent_service  = optional(bool, false)
      #network_injections is statically set to vnet/subnet created in the module.
      private_dns_zone_resource_ids = optional(list(string), [])
      sku                           = optional(string, "S0")
      role_assignments = optional(map(object({
        role_definition_id_or_name             = string
        principal_id                           = string
        description                            = optional(string, null)
        skip_service_principal_aad_check       = optional(bool, false)
        condition                              = optional(string, null)
        condition_version                      = optional(string, null)
        delegated_managed_identity_resource_id = optional(string, null)
        principal_type                         = optional(string, null)
      })), {})
    }), {})
    #AI model configurations
    ai_model_deployments = optional(map(object({
      name                   = string
      rai_policy_name        = optional(string)
      version_upgrade_option = optional(string, "OnceNewDefaultVersionAvailable")
      model = object({
        format  = string
        name    = string
        version = string
      })
      scale = object({
        capacity = optional(number)
        family   = optional(string)
        size     = optional(string)
        tier     = optional(string)
        type     = string
      })
    })), {})
    # AI Projects Configuration
    ai_projects = optional(map(object({
      name                       = string
      sku                        = optional(string, "S0")
      display_name               = string
      description                = string
      create_project_connections = optional(bool, false)
      cosmos_db_connection = optional(object({
        existing_resource_id = optional(string, null)
        new_resource_map_key = optional(string, null)
      }), {})
      ai_search_connection = optional(object({
        existing_resource_id = optional(string, null)
        new_resource_map_key = optional(string, null)
      }), {})
      key_vault_connection = optional(object({
        existing_resource_id = optional(string, null)
        new_resource_map_key = optional(string, null)
      }), {})
      storage_account_connection = optional(object({
        existing_resource_id = optional(string, null)
        new_resource_map_key = optional(string, null)
      }), {})
    })), {})
    # Bring Your Own Resources (BYOR) Configuration
    # One or more AI search installations.
    ai_search_definition = optional(map(object({
      existing_resource_id         = optional(string, null)
      name                         = optional(string)
      private_dns_zone_resource_id = optional(string, null)
      enable_diagnostic_settings   = optional(bool, true)
      sku                          = optional(string, "standard")
      local_authentication_enabled = optional(bool, true)
      partition_count              = optional(number, 1)
      replica_count                = optional(number, 2)
      semantic_search_sku          = optional(string, "standard")
      semantic_search_enabled      = optional(bool, false)
      hosting_mode                 = optional(string, "default")
      tags                         = optional(map(string), {})
      role_assignments = optional(map(object({
        role_definition_id_or_name             = string
        principal_id                           = string
        description                            = optional(string, null)
        skip_service_principal_aad_check       = optional(bool, false)
        condition                              = optional(string, null)
        condition_version                      = optional(string, null)
        delegated_managed_identity_resource_id = optional(string, null)
        principal_type                         = optional(string, null)
      })), {})
      enable_telemetry = optional(bool, true)
    })), {})

    cosmosdb_definition = optional(map(object({
      existing_resource_id         = optional(string, null)
      private_dns_zone_resource_id = optional(string, null)
      enable_diagnostic_settings   = optional(bool, true)
      name                         = optional(string)
      secondary_regions = optional(list(object({
        location          = string
        zone_redundant    = optional(bool, true)
        failover_priority = optional(number, 0)
      })), [])
      public_network_access_enabled    = optional(bool, false)
      analytical_storage_enabled       = optional(bool, true)
      automatic_failover_enabled       = optional(bool, true)
      local_authentication_disabled    = optional(bool, true)
      partition_merge_enabled          = optional(bool, false)
      multiple_write_locations_enabled = optional(bool, false)
      analytical_storage_config = optional(object({
        schema_type = string
      }), null)
      consistency_policy = optional(object({
        max_interval_in_seconds = optional(number, 300)
        max_staleness_prefix    = optional(number, 100001)
        consistency_level       = optional(string, "Session")
      }), {})
      backup = optional(object({
        retention_in_hours  = optional(number)
        interval_in_minutes = optional(number)
        storage_redundancy  = optional(string)
        type                = optional(string)
        tier                = optional(string)
      }), {})
      capabilities = optional(set(object({
        name = string
      })), [])
      capacity = optional(object({
        total_throughput_limit = optional(number, -1)
      }), {})
      cors_rule = optional(object({
        allowed_headers    = set(string)
        allowed_methods    = set(string)
        allowed_origins    = set(string)
        exposed_headers    = set(string)
        max_age_in_seconds = optional(number, null)
      }), null)
      role_assignments = optional(map(object({
        role_definition_id_or_name             = string
        principal_id                           = string
        description                            = optional(string, null)
        skip_service_principal_aad_check       = optional(bool, false)
        condition                              = optional(string, null)
        condition_version                      = optional(string, null)
        delegated_managed_identity_resource_id = optional(string, null)
        principal_type                         = optional(string, null)
      })), {})
      tags = optional(map(string), {})
    })), {})

    key_vault_definition = optional(map(object({
      existing_resource_id         = optional(string, null)
      name                         = optional(string)
      private_dns_zone_resource_id = optional(string, null)
      enable_diagnostic_settings   = optional(bool, true)
      sku                          = optional(string, "standard")
      tenant_id                    = optional(string)
      role_assignments = optional(map(object({
        role_definition_id_or_name             = string
        principal_id                           = string
        description                            = optional(string, null)
        skip_service_principal_aad_check       = optional(bool, false)
        condition                              = optional(string, null)
        condition_version                      = optional(string, null)
        delegated_managed_identity_resource_id = optional(string, null)
        principal_type                         = optional(string, null)
      })), {})
      tags = optional(map(string), {})
    })), {})

    law_definition = optional(map(object({
      existing_resource_id = optional(string)
      name                 = optional(string)
      retention            = optional(number, 30)
      sku                  = optional(string, "PerGB2018")
      tags                 = optional(map(string), {})
    })), {})

    storage_account_definition = optional(map(object({
      existing_resource_id       = optional(string, null)
      enable_diagnostic_settings = optional(bool, true)
      name                       = optional(string, null)
      account_kind               = optional(string, "StorageV2")
      account_tier               = optional(string, "Standard")
      account_replication_type   = optional(string, "ZRS")
      endpoints = optional(map(object({
        type                         = string
        private_dns_zone_resource_id = optional(string, null)
        })), {
        blob = {
          type = "blob"
        }
      })
      access_tier               = optional(string, "Hot")
      shared_access_key_enabled = optional(bool, false)
      role_assignments = optional(map(object({
        role_definition_id_or_name             = string
        principal_id                           = string
        description                            = optional(string, null)
        skip_service_principal_aad_check       = optional(bool, false)
        condition                              = optional(string, null)
        condition_version                      = optional(string, null)
        delegated_managed_identity_resource_id = optional(string, null)
        principal_type                         = optional(string, null)
      })), {})
      tags = optional(map(string), {})
    })), {})
  })
  default     = {}
  description = <<DESCRIPTION
Comprehensive configuration object for the Azure AI Foundry deployment including the hub, projects, and all dependent resources (BYOR).

This variable consolidates all configuration inputs from:
- AI Foundry Hub configuration (from variables.foundry.tf)
- AI Projects configuration (from variables.projects.tf)
- Bring Your Own Resources configuration (from variables.byor.tf)

The structure supports both creating new resources and connecting to existing ones, providing flexibility for different deployment scenarios.
DESCRIPTION
}
