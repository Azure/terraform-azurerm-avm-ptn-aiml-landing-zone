## Passing most of the Foundry Pattern module's inputs in here to allow for flexibility.
#TODO: remove DNS zone ID's injection for everything.  This comes in as an RG id where the
variable "ai_foundry_definition" {
  type = object({
    # AI Foundry Hub Configuration
    create_byor      = optional(bool, true)
    purge_on_destroy = optional(bool, false)
    tags             = optional(map(string))
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
      tags                         = optional(map(string))
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
      tags = optional(map(string))
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
      tags = optional(map(string))
    })), {})

    law_definition = optional(map(object({
      existing_resource_id = optional(string)
      name                 = optional(string)
      retention            = optional(number, 30)
      sku                  = optional(string, "PerGB2018")
      tags                 = optional(map(string))
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
      tags = optional(map(string))
    })), {})
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure AI Foundry deployment (hub, projects, and Bring Your Own Resources).

- `create_byor` - (Optional) Whether to create BYOR resources managed by this module. Default is true.
- `purge_on_destroy` - (Optional) Whether to purge soft-delete–capable resources on destroy. Default is false.

- `ai_foundry` - (Optional) Azure AI Foundry hub settings.
  - `name` - (Optional) Name of the hub. If not provided, a name will be generated.
  - `disable_local_auth` - (Optional) Whether to disable local authentication. Default is false.
  - `allow_project_management` - (Optional) Whether project management is allowed from the hub. Default is true.
  - `create_ai_agent_service` - (Optional) Whether to create the AI Agent service in the hub. Default is false.
  - `private_dns_zone_resource_ids` - (Optional) List of private DNS zone resource IDs for hub endpoints. Default is [].
  - `sku` - (Optional) The SKU for the hub. Default is "S0".
  - `role_assignments` - (Optional) Map of role assignments on the hub. The map key is deliberately arbitrary to avoid plan-time unknown key issues.
    - `role_definition_id_or_name` - Role definition ID or name to assign.
    - `principal_id` - Principal ID for the assignment.
    - `description` - (Optional) Description of the role assignment.
    - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principals. Default is false.
    - `condition` - (Optional) Condition for the role assignment.
    - `condition_version` - (Optional) Version of the condition.
    - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
    - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).

- `ai_model_deployments` - (Optional) Map of model deployment configurations to create. The map key is arbitrary.
  - `name` - The name of the deployment.
  - `rai_policy_name` - (Optional) Responsible AI policy name applied to the deployment.
  - `version_upgrade_option` - (Optional) Version upgrade option for the model. Default is "OnceNewDefaultVersionAvailable".
  - `model` - Model specification.
    - `format` - Model format (e.g., OpenAI, OSS foundation model format).
    - `name` - Model name.
    - `version` - Model version.
  - `scale` - Scale configuration for the deployment.
    - `capacity` - (Optional) Capacity value for the selected SKU family/size.
    - `family` - (Optional) SKU family.
    - `size` - (Optional) SKU size.
    - `tier` - (Optional) SKU tier.
    - `type` - Scale type (e.g., Standard/ProvisionedManaged/Serverless, depending on service).

- `ai_projects` - (Optional) Map of AI Project configurations to create. The map key is arbitrary.
  - `name` - Resource name of the project.
  - `sku` - (Optional) SKU for the project. Default is "S0".
  - `display_name` - Display name for the project.
  - `description` - Description of the project.
  - `create_project_connections` - (Optional) Whether to create project-level connections to dependent services. Default is false.
  - `cosmos_db_connection` - (Optional) Connection to Cosmos DB.
    - `existing_resource_id` - (Optional) Resource ID of an existing Cosmos DB to connect.
    - `new_resource_map_key` - (Optional) Key referencing a new resource from `cosmosdb_definition`.
  - `ai_search_connection` - (Optional) Connection to Azure AI Search.
    - `existing_resource_id` - (Optional) Resource ID of an existing AI Search to connect.
    - `new_resource_map_key` - (Optional) Key referencing a new resource from `ai_search_definition`.
  - `key_vault_connection` - (Optional) Connection to Key Vault.
    - `existing_resource_id` - (Optional) Resource ID of an existing Key Vault to connect.
    - `new_resource_map_key` - (Optional) Key referencing a new resource from `key_vault_definition`.
  - `storage_account_connection` - (Optional) Connection to Storage Account.
    - `existing_resource_id` - (Optional) Resource ID of an existing Storage Account to connect.
    - `new_resource_map_key` - (Optional) Key referencing a new resource from `storage_account_definition`.

- Bring Your Own Resources (BYOR) definitions
  - `ai_search_definition` - (Optional) Map defining one or more Azure AI Search services.
    - `existing_resource_id` - (Optional) Resource ID of an existing service to reuse.
    - `name` - (Optional) Name of the service if creating new.
    - `private_dns_zone_resource_id` - (Optional) Private DNS zone resource ID for the service.
    - `enable_diagnostic_settings` - (Optional) Whether diagnostic settings are enabled. Default is true.
    - `sku` - (Optional) Service SKU. Default is "standard".
    - `local_authentication_enabled` - (Optional) Whether local auth is enabled. Default is true.
    - `partition_count` - (Optional) Number of partitions. Default is 1.
    - `replica_count` - (Optional) Number of replicas. Default is 2.
    - `semantic_search_sku` - (Optional) Semantic search SKU. Default is "standard".
    - `semantic_search_enabled` - (Optional) Whether semantic search is enabled. Default is false.
    - `hosting_mode` - (Optional) Hosting mode. Default is "default".
    - `tags` - (Optional) Map of tags for the service.
    - `role_assignments` - (Optional) Map of role assignments on the service.
      - `role_definition_id_or_name` - Role definition ID or name to assign.
      - `principal_id` - Principal ID for the assignment.
      - `description` - (Optional) Description of the role assignment.
      - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principals. Default is false.
      - `condition` - (Optional) Condition for the role assignment.
      - `condition_version` - (Optional) Version of the condition.
      - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
      - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
    - `enable_telemetry` - (Optional) Whether telemetry is enabled for this resource. Default is true.

  - `cosmosdb_definition` - (Optional) Map defining one or more Azure Cosmos DB accounts.
    - `existing_resource_id` - (Optional) Resource ID of an existing account to reuse.
    - `private_dns_zone_resource_id` - (Optional) Private DNS zone resource ID.
    - `enable_diagnostic_settings` - (Optional) Whether diagnostic settings are enabled. Default is true.
    - `name` - (Optional) Name of the account if creating new.
    - `secondary_regions` - (Optional) List of secondary regions for geo-replication. Default is [].
      - `location` - Azure region name for the secondary location.
      - `zone_redundant` - (Optional) Whether zone redundancy is enabled. Default is true.
      - `failover_priority` - (Optional) Failover priority. Default is 0.
    - `public_network_access_enabled` - (Optional) Whether public network access is enabled. Default is false.
    - `analytical_storage_enabled` - (Optional) Whether analytical storage is enabled. Default is true.
    - `automatic_failover_enabled` - (Optional) Whether automatic failover is enabled. Default is true.
    - `local_authentication_disabled` - (Optional) Whether local authentication is disabled. Default is true.
    - `partition_merge_enabled` - (Optional) Whether partition merge is enabled. Default is false.
    - `multiple_write_locations_enabled` - (Optional) Whether multiple write locations are enabled. Default is false.
    - `analytical_storage_config` - (Optional) Analytical storage configuration. Default is null.
      - `schema_type` - Schema type for analytical storage.
    - `consistency_policy` - (Optional) Consistency policy configuration.
      - `max_interval_in_seconds` - (Optional) Max staleness interval in seconds. Default is 300.
      - `max_staleness_prefix` - (Optional) Max staleness prefix. Default is 100001.
      - `consistency_level` - (Optional) Consistency level. Default is "Session".
    - `backup` - (Optional) Backup configuration.
      - `retention_in_hours` - (Optional) Backup retention in hours.
      - `interval_in_minutes` - (Optional) Backup interval in minutes.
      - `storage_redundancy` - (Optional) Storage redundancy for backups.
      - `type` - (Optional) Backup type.
      - `tier` - (Optional) Backup tier.
    - `capabilities` - (Optional) Set of capabilities to enable.
      - `name` - Capability name.
    - `capacity` - (Optional) Capacity configuration.
      - `total_throughput_limit` - (Optional) Total throughput limit. Default is -1 (unlimited).
    - `cors_rule` - (Optional) CORS rule configuration. Default is null.
      - `allowed_headers` - Set of allowed headers.
      - `allowed_methods` - Set of allowed methods.
      - `allowed_origins` - Set of allowed origins.
      - `exposed_headers` - Set of exposed headers.
      - `max_age_in_seconds` - (Optional) Maximum age in seconds for CORS.
    - `role_assignments` - (Optional) Map of role assignments on the account.
      - `role_definition_id_or_name` - Role definition ID or name to assign.
      - `principal_id` - Principal ID for the assignment.
      - `description` - (Optional) Description of the role assignment.
      - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principals. Default is false.
      - `condition` - (Optional) Condition for the role assignment.
      - `condition_version` - (Optional) Version of the condition.
      - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
      - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
    - `tags` - (Optional) Map of tags for the account.

  - `key_vault_definition` - (Optional) Map defining one or more Azure Key Vaults.
    - `existing_resource_id` - (Optional) Resource ID of an existing vault to reuse.
    - `name` - (Optional) Name of the vault if creating new.
    - `private_dns_zone_resource_id` - (Optional) Private DNS zone resource ID.
    - `enable_diagnostic_settings` - (Optional) Whether diagnostic settings are enabled. Default is true.
    - `sku` - (Optional) Vault SKU. Default is "standard".
    - `tenant_id` - (Optional) Tenant ID for the Key Vault.
    - `role_assignments` - (Optional) Map of role assignments on the vault.
      - `role_definition_id_or_name` - Role definition ID or name to assign.
      - `principal_id` - Principal ID for the assignment.
      - `description` - (Optional) Description of the role assignment.
      - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principals. Default is false.
      - `condition` - (Optional) Condition for the role assignment.
      - `condition_version` - (Optional) Version of the condition.
      - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
      - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
    - `tags` - (Optional) Map of tags for the vault.

  - `law_definition` - (Optional) Map defining one or more Log Analytics Workspaces.
    - `existing_resource_id` - (Optional) Resource ID of an existing workspace to reuse.
    - `name` - (Optional) Name of the workspace if creating new.
    - `retention` - (Optional) Data retention in days. Default is 30.
    - `sku` - (Optional) Workspace SKU. Default is "PerGB2018".
    - `tags` - (Optional) Map of tags for the workspace.

  - `storage_account_definition` - (Optional) Map defining one or more Storage Accounts.
    - `existing_resource_id` - (Optional) Resource ID of an existing account to reuse.
    - `enable_diagnostic_settings` - (Optional) Whether diagnostic settings are enabled. Default is true.
    - `name` - (Optional) Name of the account if creating new.
    - `account_kind` - (Optional) Storage account kind. Default is "StorageV2".
    - `account_tier` - (Optional) Storage account tier. Default is "Standard".
    - `account_replication_type` - (Optional) Replication type. Default is "ZRS".
    - `endpoints` - (Optional) Map of subservice endpoints to enable. Defaults to enabling the `blob` endpoint.
      - map key - Endpoint name (e.g., `blob`).
      - `type` - Endpoint type (e.g., "blob").
      - `private_dns_zone_resource_id` - (Optional) Private DNS zone resource ID for the endpoint.
    - `access_tier` - (Optional) Access tier for the account. Default is "Hot".
    - `shared_access_key_enabled` - (Optional) Whether shared access keys are enabled. Default is false.
    - `role_assignments` - (Optional) Map of role assignments on the storage account.
      - `role_definition_id_or_name` - Role definition ID or name to assign.
      - `principal_id` - Principal ID for the assignment.
      - `description` - (Optional) Description of the role assignment.
      - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principals. Default is false.
      - `condition` - (Optional) Condition for the role assignment.
      - `condition_version` - (Optional) Version of the condition.
      - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
      - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
    - `tags` - (Optional) Map of tags for the storage account.

This object supports both creating new resources and connecting to existing ones, enabling flexible deployment scenarios across the hub, projects, and dependent services.
DESCRIPTION
}
