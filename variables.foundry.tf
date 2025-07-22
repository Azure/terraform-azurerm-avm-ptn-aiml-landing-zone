variable "ai_foundry_definition" {
  type = object({
    # AI Foundry Hub Configuration
    ai_foundry = optional(object({
      name                       = optional(string, null)
      disable_local_auth         = optional(bool, false)
      allow_project_management   = optional(bool, true)
      create_ai_agent_service    = optional(bool, false)
      create_dependent_resources = optional(bool, true)
      network_injections = optional(list(object({
        scenario                   = optional(string, "agent")
        subnetArmId                = string
        useMicrosoftManagedNetwork = optional(bool, false)
      })), null)
      private_dns_zone_resource_id = optional(string, null)
      sku                          = optional(string, "S0")
    }), {})

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
        consistency_level       = optional(string, "BoundedStaleness")
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

    law_definition = optional(object({
      existing_resource_id = optional(string)
      name                 = optional(string)
      retention            = optional(number, 30)
      sku                  = optional(string, "PerGB2018")
      tags                 = optional(map(string), {})
    }), {})

    storage_account_definition = optional(map(object({
      existing_resource_id       = optional(string, null)
      enable_diagnostic_settings = optional(bool, true)
      name                       = optional(string, null)
      account_kind               = optional(string, "StorageV2")
      account_tier               = optional(string, "Standard")
      account_replication_type   = optional(string, "GRS")
      endpoints = optional(map(object({
        type                         = string
        private_dns_zone_resource_id = optional(string, null)
        })), {
        blob = {
          type = "blob"
        }
      })
      access_tier               = optional(string, "Hot")
      shared_access_key_enabled = optional(bool, true)
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

# AI Foundry Hub Configuration
- `ai_foundry` - (Optional) Configuration for the Azure AI Foundry hub service.
  - `name` - (Optional) The name of the AI Foundry service. If not provided, a name will be generated.
  - `disable_local_auth` - (Optional) Whether to disable local authentication for the AI Foundry service. Default is false.
  - `allow_project_management` - (Optional) Whether to allow project management capabilities in the AI Foundry service. Default is true.
  - `create_ai_agent_service` - (Optional) Whether to create an AI agent service as part of the AI Foundry deployment. Default is false.
  - `network_injections` - (Optional) List of network injection configurations for the AI Foundry service.
    - `scenario` - (Optional) The scenario for the network injection. Default is "agent".
    - `subnetArmId` - The subnet ID for the AI agent service.
    - `useMicrosoftManagedNetwork` - (Optional) Whether to use Microsoft managed network for the injection. Default is false.
  - `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for AI Foundry. If not provided, a private endpoint will not be created.
  - `sku` - (Optional) The SKU of the AI Foundry service. Default is "S0".

# AI Projects Configuration
- `ai_projects` - (Optional) Map of AI Foundry projects with their configurations. Each project can have its own settings. Map keys should match the dependent resources keys when creating connections.
  - `map key` - The unique identifier for the AI project.
    - `name` - The name of the AI project.
    - `sku` - (Optional) The SKU for the AI project. Default is "S0".
    - `display_name` - The display name for the AI project.
    - `description` - Description of the AI project.
    - `create_project_connections` - (Optional) Whether to create project connections to dependent resources. Default is false.
    - `cosmos_db_connection` - (Optional) Cosmos DB connection configuration.
      - `existing_resource_id` - (Optional) Resource ID of existing Cosmos DB to connect to.
      - `new_resource_map_key` - (Optional) Map key of new Cosmos DB resource to connect to.
    - `ai_search_connection` - (Optional) AI Search connection configuration.
      - `existing_resource_id` - (Optional) Resource ID of existing AI Search to connect to.
      - `new_resource_map_key` - (Optional) Map key of new AI Search resource to connect to.
    - `key_vault_connection` - (Optional) Key Vault connection configuration.
      - `existing_resource_id` - (Optional) Resource ID of existing Key Vault to connect to.
      - `new_resource_map_key` - (Optional) Map key of new Key Vault resource to connect to.
    - `storage_account_connection` - (Optional) Storage Account connection configuration.
      - `existing_resource_id` - (Optional) Resource ID of existing Storage Account to connect to.
      - `new_resource_map_key` - (Optional) Map key of new Storage Account resource to connect to.

# Bring Your Own Resources (BYOR) Configuration
- `ai_search_definition` - (Optional) Configuration for Azure AI Search services to be created as part of the enterprise and public knowledge services.
  - `map key` - The key for the map entry. This key should match the AI project key when creating multiple projects with multiple AI search services.
    - `existing_resource_id` - (Optional) The resource ID of an existing AI Search service to use. If provided, the service will not be created and the other inputs will be ignored.
    - `name` - (Optional) The name of the AI Search service. If not provided, a name will be generated.
    - `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for AI Search. If not provided, a private endpoint will not be created.
    - `sku` - (Optional) The SKU of the AI Search service. Default is "standard".
    - `local_authentication_enabled` - (Optional) Whether local authentication is enabled. Default is true.
    - `partition_count` - (Optional) The number of partitions for the search service. Default is 1.
    - `replica_count` - (Optional) The number of replicas for the search service. Default is 2.
    - `semantic_search_sku` - (Optional) The SKU for semantic search capabilities. Default is "standard".
    - `tags` - (Optional) Map of tags to assign to the AI Search service.
    - `role_assignments` - (Optional) Map of role assignments to create on the AI Search service.
    - `enable_telemetry` - (Optional) Whether telemetry is enabled for the AI Search module. Default is true.

- `cosmosdb_definition` - (Optional) Configuration for Azure Cosmos DB accounts to be created for GenAI services.
  - `map key` - The key for the map entry. This key should match the AI project key when creating multiple projects and multiple CosmosDB accounts.
    - `existing_resource_id` - (Optional) The resource ID of an existing Cosmos DB account to use.
    - `name` - (Optional) The name of the Cosmos DB account. If not provided, a name will be generated.
    - `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for Cosmos DB.
    - `secondary_regions` - (Optional) List of secondary regions for geo-replication.
    - `public_network_access_enabled` - (Optional) Whether public network access is enabled. Default is false.
    - `analytical_storage_enabled` - (Optional) Whether analytical storage is enabled. Default is true.
    - `automatic_failover_enabled` - (Optional) Whether automatic failover is enabled. Default is true.
    - `local_authentication_disabled` - (Optional) Whether local authentication is disabled. Default is true.
    - `partition_merge_enabled` - (Optional) Whether partition merge is enabled. Default is false.
    - `multiple_write_locations_enabled` - (Optional) Whether multiple write locations are enabled. Default is false.
    - `analytical_storage_config` - (Optional) Analytical storage configuration.
    - `consistency_policy` - (Optional) Consistency policy configuration.
    - `backup` - (Optional) Backup configuration.
    - `capabilities` - (Optional) Set of capabilities to enable on the Cosmos DB account.
    - `capacity` - (Optional) Capacity configuration.
    - `cors_rule` - (Optional) CORS rule configuration.
    - `role_assignments` - (Optional) Map of role assignments to create on the Cosmos DB account.
    - `tags` - (Optional) Map of tags to assign to the Cosmos DB account.

- `key_vault_definition` - (Optional) Configuration for Azure Key Vault to be created for GenAI services.
  - `map key` - The key for the map entry. This key should match the AI project key when creating multiple projects with multiple Key Vaults.
    - `existing_resource_id` - (Optional) The resource ID of an existing Key Vault to use.
    - `name` - (Optional) The name of the Key Vault. If not provided, a name will be generated.
    - `private_dns_zone_resource_id` - (Optional) The resource ID of the existing private DNS zone for Key Vault.
    - `sku` - (Optional) The SKU of the Key Vault. Default is "standard".
    - `tenant_id` - (Optional) The tenant ID for the Key Vault. If not provided, the current tenant will be used.
    - `role_assignments` - (Optional) Map of role assignments to create on the Key Vault.
    - `tags` - (Optional) Map of tags to assign to the Key Vault.

- `law_definition` - (Optional) Configuration for the Log Analytics Workspace to be created for monitoring and logging.
  - `existing_resource_id` - (Optional) The resource ID of an existing Log Analytics Workspace to use.
  - `name` - (Optional) The name of the Log Analytics Workspace. If not provided, a name will be generated.
  - `retention` - (Optional) The data retention period in days for the workspace. Default is 30.
  - `sku` - (Optional) The SKU of the Log Analytics Workspace. Default is "PerGB2018".
  - `tags` - (Optional) Map of tags to assign to the Log Analytics Workspace.

- `storage_account_definition` - (Optional) Configuration for Azure Storage Accounts to be created for GenAI services.
  - `map key` - The key for the map entry. This key should match the AI project key when creating multiple projects with multiple Storage Accounts.
    - `existing_resource_id` - (Optional) The resource ID of an existing Storage Account to use.
    - `name` - (Optional) The name of the Storage Account. If not provided, a name will be generated.
    - `account_kind` - (Optional) The kind of storage account. Default is "StorageV2".
    - `account_tier` - (Optional) The performance tier of the storage account. Default is "Standard".
    - `account_replication_type` - (Optional) The replication type for the storage account. Default is "GRS".
    - `endpoints` - (Optional) Map of endpoint configurations to enable. Default includes blob endpoint.
    - `access_tier` - (Optional) The access tier for the storage account. Default is "Hot".
    - `shared_access_key_enabled` - (Optional) Whether shared access keys are enabled. Default is true.
    - `role_assignments` - (Optional) Map of role assignments to create on the Storage Account.
    - `tags` - (Optional) Map of tags to assign to the Storage Account.
DESCRIPTION
}
