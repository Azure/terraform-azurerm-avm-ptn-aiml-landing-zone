## Passing most of the Foundry Pattern module's inputs in here to allow for flexibility.
#TODO: remove DNS zone ID's injection for everything.  This comes in as an RG id where the
variable "ai_foundry_definition" {
  type = object({
    # AI Foundry Hub Configuration
    create_byor      = optional(bool, true)
    purge_on_destroy = optional(bool, false)
    ai_foundry = optional(object({
      name                       = optional(string, null)
      disable_local_auth         = optional(bool, false)
      enable_diagnostic_settings = optional(bool, true)
      diagnostic_settings = optional(map(object({
        name                                     = optional(string, null)
        log_categories                           = optional(set(string), [])
        log_groups                               = optional(set(string), ["allLogs"])
        metric_categories                        = optional(set(string), ["AllMetrics"])
        log_analytics_destination_type           = optional(string, "Dedicated")
        workspace_resource_id                    = optional(string, null)
        storage_account_resource_id              = optional(string, null)
        event_hub_authorization_rule_resource_id = optional(string, null)
        event_hub_name                           = optional(string, null)
        marketplace_partner_resource_id          = optional(string, null)
      })), {})
      allow_project_management = optional(bool, true)
      create_ai_agent_service  = optional(bool, false)
      #network_injections is statically set to vnet/subnet created in the module.
      private_dns_zone_resource_ids           = optional(list(string), [])
      private_endpoints_manage_dns_zone_group = optional(bool, true)
      public_network_access_enabled           = optional(bool, null)
      network_acls = optional(object({
        default_action = optional(string, "Allow")
        bypass         = optional(string, null)
        ip_rules       = optional(list(string), [])
        virtual_network_rules = optional(list(object({
          subnet_resource_id                   = string
          ignore_missing_vnet_service_endpoint = optional(bool, false)
        })), [])
      }), null)
      sku  = optional(string, "S0")
      tags = optional(map(string))
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
      rai_policy_name        = optional(string, "Microsoft.DefaultV2")
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
      existing_resource_id                    = optional(string, null)
      name                                    = optional(string)
      private_dns_zone_resource_id            = optional(string, null)
      private_endpoints_manage_dns_zone_group = optional(bool, true)
      diagnostic_settings = optional(map(object({
        name                                     = optional(string, null)
        log_categories                           = optional(set(string), [])
        log_groups                               = optional(set(string), ["allLogs"])
        metric_categories                        = optional(set(string), ["AllMetrics"])
        log_analytics_destination_type           = optional(string, "Dedicated")
        workspace_resource_id                    = optional(string, null)
        storage_account_resource_id              = optional(string, null)
        event_hub_authorization_rule_resource_id = optional(string, null)
        event_hub_name                           = optional(string, null)
        marketplace_partner_resource_id          = optional(string, null)
      })), {})
      sku                           = optional(string, "standard")
      local_authentication_enabled  = optional(bool, true)
      partition_count               = optional(number, 1)
      replica_count                 = optional(number, 2)
      semantic_search_sku           = optional(string, "standard")
      semantic_search_enabled       = optional(bool, false)
      hosting_mode                  = optional(string, "default")
      public_network_access_enabled = optional(bool, null)
      network_rule_set = optional(object({
        bypass   = optional(string, "None")
        ip_rules = optional(list(string), [])
      }), {})
      tags = optional(map(string))
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
      existing_resource_id                    = optional(string, null)
      private_dns_zone_resource_id            = optional(string, null)
      private_endpoints_manage_dns_zone_group = optional(bool, true)
      diagnostic_settings = optional(map(object({
        name                                     = optional(string, null)
        log_categories                           = optional(set(string), [])
        log_groups                               = optional(set(string), ["allLogs"])
        metric_categories                        = optional(set(string), ["AllMetrics"])
        log_analytics_destination_type           = optional(string, "Dedicated")
        workspace_resource_id                    = optional(string, null)
        storage_account_resource_id              = optional(string, null)
        event_hub_authorization_rule_resource_id = optional(string, null)
        event_hub_name                           = optional(string, null)
        marketplace_partner_resource_id          = optional(string, null)
      })), {})
      name = optional(string)
      secondary_regions = optional(list(object({
        location          = string
        zone_redundant    = optional(bool, true)
        failover_priority = optional(number, 0)
      })), [])
      public_network_access_enabled    = optional(bool, false)
      analytical_storage_enabled       = optional(bool, false)
      automatic_failover_enabled       = optional(bool, true)
      local_authentication_disabled    = optional(bool, true)
      partition_merge_enabled          = optional(bool, false)
      multiple_write_locations_enabled = optional(bool, false)
      # Default allowlist is the Azure portal plus global Azure datacenter source IPs: https://learn.microsoft.com/azure/cosmos-db/how-to-configure-firewall
      ip_range_filter = optional(set(string), [
        "168.125.123.255",
        "170.0.0.0/24",
        "0.0.0.0",
        "104.42.195.92", "40.76.54.131", "52.176.6.30", "52.169.50.45", "52.187.184.26"
      ])
      network_acl_bypass_for_azure_services = optional(bool, true)
      network_acl_bypass_resource_ids       = optional(set(string), [])
      virtual_network_rules = optional(set(object({
        subnet_id = string
      })), [])
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
      existing_resource_id                    = optional(string, null)
      name                                    = optional(string)
      private_dns_zone_resource_id            = optional(string, null)
      private_endpoints_manage_dns_zone_group = optional(bool, true)
      diagnostic_settings = optional(map(object({
        name                                     = optional(string, null)
        log_categories                           = optional(set(string), [])
        log_groups                               = optional(set(string), ["allLogs"])
        metric_categories                        = optional(set(string), ["AllMetrics"])
        log_analytics_destination_type           = optional(string, "Dedicated")
        workspace_resource_id                    = optional(string, null)
        storage_account_resource_id              = optional(string, null)
        event_hub_authorization_rule_resource_id = optional(string, null)
        event_hub_name                           = optional(string, null)
        marketplace_partner_resource_id          = optional(string, null)
      })), {})
      sku                           = optional(string, "standard")
      tenant_id                     = optional(string)
      public_network_access_enabled = optional(bool, null)
      network_acls = optional(object({
        bypass                     = optional(string, "AzureServices")
        default_action             = optional(string, "Allow")
        ip_rules                   = optional(list(string), [])
        virtual_network_subnet_ids = optional(list(string), [])
      }), {})
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

    storage_account_definition = optional(map(object({
      existing_resource_id = optional(string, null)
      diagnostic_settings = optional(map(object({
        name                                     = optional(string, null)
        log_categories                           = optional(set(string), [])
        log_groups                               = optional(set(string), ["allLogs"])
        metric_categories                        = optional(set(string), ["AllMetrics"])
        log_analytics_destination_type           = optional(string, "Dedicated")
        workspace_resource_id                    = optional(string, null)
        storage_account_resource_id              = optional(string, null)
        event_hub_authorization_rule_resource_id = optional(string, null)
        event_hub_name                           = optional(string, null)
        marketplace_partner_resource_id          = optional(string, null)
      })), {})
      name                     = optional(string, null)
      account_kind             = optional(string, "StorageV2")
      account_tier             = optional(string, "Standard")
      account_replication_type = optional(string, "ZRS")
      endpoints = optional(map(object({
        type                                    = string
        private_dns_zone_resource_id            = optional(string, null)
        private_endpoints_manage_dns_zone_group = optional(bool, true)
        })), {
        blob = {
          type = "blob"
        }
      })
      access_tier                   = optional(string, "Hot")
      shared_access_key_enabled     = optional(bool, false)
      public_network_access_enabled = optional(bool, null)
      network_rules = optional(object({
        bypass                     = optional(set(string), ["AzureServices"])
        default_action             = optional(string, "Deny")
        ip_rules                   = optional(set(string), [])
        virtual_network_subnet_ids = optional(set(string), [])
        private_link_access = optional(list(object({
          endpoint_resource_id = string
          endpoint_tenant_id   = optional(string)
        })), null)
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
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure AI Foundry deployment (hub, projects, and Bring Your Own Resources).

- `create_byor` - (Optional) Whether to create BYOR resources managed by this module. Default is true.
- `purge_on_destroy` - (Optional) Whether to purge soft-delete–capable resources on destroy. Default is false.
- `ai_foundry` - (Optional) Azure AI Foundry hub settings.
  - `name` - (Optional) Name of the hub. If not provided, a name will be generated.
  - `disable_local_auth` - (Optional) Whether to disable local authentication. Default is false.
  - `enable_diagnostic_settings` - (Optional) Whether diagnostic settings are enabled. Default is true.
  - `diagnostic_settings` - (Optional) - map of diagnostic settings for the main foundry module and resource
    - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
    - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
    - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
    - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
    - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
    - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
    - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
    - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
    - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
    - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.
  - `allow_project_management` - (Optional) Whether project management is allowed from the hub. Default is true.
  - `create_ai_agent_service` - (Optional) Whether to create the AI Agent service in the hub. Default is false.
  - `private_dns_zone_resource_ids` - (Optional) List of private DNS zone resource IDs for hub endpoints. Default is [].
  - `public_network_access_enabled` - (Optional) Overrides public network access on the hub account. Default is null, which lets the upstream module derive the value from the private endpoint configuration (public access disabled).
  - `network_acls` - (Optional) Network access control list applied to the hub account. Default is null, which allows traffic from all networks. The rules only take effect when `public_network_access_enabled` is true.
    - `default_action` - (Optional) Action taken when no rule matches. Possible values are "Allow" and "Deny". Default is "Allow".
    - `bypass` - (Optional) Set to "AzureServices" to let trusted Azure services bypass the rules. Default is null.
    - `ip_rules` - (Optional) List of IPv4 addresses or CIDR ranges allowed inbound access. Default is [].
    - `virtual_network_rules` - (Optional) List of subnets allowed inbound access. Default is [].
      - `subnet_resource_id` - The resource ID of the subnet to allow.
      - `ignore_missing_vnet_service_endpoint` - (Optional) Whether to ignore a missing virtual network service endpoint on the subnet. Default is false.
  - `sku` - (Optional) The SKU for the hub. Default is "S0".
  - `tags` - (Optional) Map of tags to assign to the AI Foundry hub.
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
  - `rai_policy_name` - (Optional) Responsible AI policy name applied to the deployment. Default is "Microsoft.DefaultV2".
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
    - `private_endpoints_manage_dns_zone_group` - (Optional) Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy. Default is true.
    - `diagnostic_settings` - (Optional) - map of diagnostic settings for the main foundry module's byor ai_search resource
        - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
        - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
        - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
        - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
        - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
        - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
        - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
        - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
        - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
        - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.
    - `sku` - (Optional) Service SKU. Default is "standard".
    - `local_authentication_enabled` - (Optional) Whether local auth is enabled. Default is true.
    - `partition_count` - (Optional) Number of partitions. Default is 1.
    - `replica_count` - (Optional) Number of replicas. Default is 2.
    - `semantic_search_sku` - (Optional) Semantic search SKU. Default is "standard".
    - `semantic_search_enabled` - (Optional) Whether semantic search is enabled. Default is false.
    - `hosting_mode` - (Optional) Hosting mode. Default is "default".
    - `public_network_access_enabled` - (Optional) Overrides public network access on the search service. Default is null, which lets the upstream module derive the value from the private endpoint configuration (public access disabled).
    - `network_rule_set` - (Optional) Inbound network rules applied to the search service. Only takes effect when public network access is enabled.
      - `bypass` - (Optional) Whether trusted Azure services may bypass the rules. Possible values are "None" and "AzureServices". Default is "None".
      - `ip_rules` - (Optional) List of IPv4 addresses or CIDR ranges allowed inbound access. Default is [].
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
    - `private_endpoints_manage_dns_zone_group` - (Optional) Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy. Default is true.
    - `diagnostic_settings` - (Optional) - map of diagnostic settings for the foundry module's byor cosmos resource
        - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
        - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
        - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
        - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
        - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
        - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
        - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
        - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
        - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
        - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.
    - `name` - (Optional) Name of the account if creating new.
    - `secondary_regions` - (Optional) List of secondary regions for geo-replication. Default is [].
      - `location` - Azure region name for the secondary location.
      - `zone_redundant` - (Optional) Whether zone redundancy is enabled. Default is true.
      - `failover_priority` - (Optional) Failover priority. Default is 0.
    - `public_network_access_enabled` - (Optional) Whether public network access is enabled. Default is false.
    - `analytical_storage_enabled` - (Optional) Whether analytical storage is enabled. Default is false.
    - `automatic_failover_enabled` - (Optional) Whether automatic failover is enabled. Default is true.
    - `local_authentication_disabled` - (Optional) Whether local authentication is disabled. Default is true.
    - `partition_merge_enabled` - (Optional) Whether partition merge is enabled. Default is false.
    - `multiple_write_locations_enabled` - (Optional) Whether multiple write locations are enabled. Default is false.
    - `ip_range_filter` - (Optional) Set of IP addresses or CIDR ranges allowed to reach the Cosmos DB account. Defaults to the Azure portal and global Azure datacenter source IPs documented at https://learn.microsoft.com/azure/cosmos-db/how-to-configure-firewall. Set to `[]` to remove the allowlist.
    - `network_acl_bypass_for_azure_services` - (Optional) Whether Azure services can bypass the network ACLs. Default is true.
    - `network_acl_bypass_resource_ids` - (Optional) Set of resource IDs allowed to bypass the network ACLs. Default is [].
    - `virtual_network_rules` - (Optional) Set of subnets allowed to reach the Cosmos DB account. Default is [].
      - `subnet_id` - The resource ID of the subnet to allow.
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
    - `private_endpoints_manage_dns_zone_group` - (Optional) Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy. Default is true.
    - `diagnostic_settings` - (Optional) - map of diagnostic settings for the foundry module's byor key vault resource
        - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
        - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
        - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
        - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
        - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
        - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
        - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
        - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
        - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
        - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.
    - `sku` - (Optional) Vault SKU. Default is "standard".
    - `tenant_id` - (Optional) Tenant ID for the Key Vault.
    - `public_network_access_enabled` - (Optional) Overrides public network access on the Key Vault. Default is null, which lets the upstream module derive the value from the private endpoint configuration (public access disabled).
    - `network_acls` - (Optional) Network access control list applied to the Key Vault. Defaults to allowing all networks with an `AzureServices` bypass.
      - `bypass` - (Optional) Traffic permitted to bypass the rules. Possible values are "AzureServices" and "None". Default is "AzureServices".
      - `default_action` - (Optional) Action taken when no rule matches. Possible values are "Allow" and "Deny". Default is "Allow".
      - `ip_rules` - (Optional) List of IPv4 addresses or CIDR ranges allowed access. Default is [].
      - `virtual_network_subnet_ids` - (Optional) List of subnet resource IDs allowed access. Default is [].
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

  - `storage_account_definition` - (Optional) Map defining one or more Storage Accounts.
    - `existing_resource_id` - (Optional) Resource ID of an existing account to reuse.
    - `diagnostic_settings` - (Optional) - map of diagnostic settings for the foundry module's byor storage account resource
      - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
      - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
      - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
      - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
      - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
      - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
      - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
      - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
      - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
      - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.
    - `name` - (Optional) Name of the account if creating new.
    - `account_kind` - (Optional) Storage account kind. Default is "StorageV2".
    - `account_tier` - (Optional) Storage account tier. Default is "Standard".
    - `account_replication_type` - (Optional) Replication type. Default is "ZRS".
    - `endpoints` - (Optional) Map of subservice endpoints to enable. Defaults to enabling the `blob` endpoint.
      - map key - Endpoint name (e.g., `blob`).
      - `type` - Endpoint type (e.g., "blob").
      - `private_dns_zone_resource_id` - (Optional) Private DNS zone resource ID for the endpoint.
      - `private_endpoints_manage_dns_zone_group` - (Optional) Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy. Default is true.
    - `access_tier` - (Optional) Access tier for the account. Default is "Hot".
    - `shared_access_key_enabled` - (Optional) Whether shared access keys are enabled. Default is false.
    - `public_network_access_enabled` - (Optional) Overrides public network access on the storage account. Default is null, which lets the upstream module derive the value from the private endpoint configuration (public access disabled).
    - `network_rules` - (Optional) Storage account firewall configuration. Default is null, in which case the upstream module applies deny-by-default with an `AzureServices` bypass, matching the private endpoint topology this module deploys.
      - `bypass` - (Optional) Traffic permitted to bypass the rules. Any combination of "Logging", "Metrics", "AzureServices" or "None". Default is ["AzureServices"].
      - `default_action` - (Optional) Action taken when no rule matches. Possible values are "Allow" and "Deny". Default is "Deny".
      - `ip_rules` - (Optional) Set of public IPv4 addresses or CIDR ranges allowed access. RFC 1918 private ranges are not permitted by Azure. Default is [].
      - `virtual_network_subnet_ids` - (Optional) Set of subnet resource IDs allowed access. Default is [].
      - `private_link_access` - (Optional) List of resource access rules granting private link access. Default is null.
        - `endpoint_resource_id` - The resource ID granted access.
        - `endpoint_tenant_id` - (Optional) The tenant ID of the resource. Defaults to the current tenant.
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

  validation {
    condition     = try(var.ai_foundry_definition.ai_foundry.network_acls, null) == null ? true : contains(["Allow", "Deny"], var.ai_foundry_definition.ai_foundry.network_acls.default_action)
    error_message = "The ai_foundry.network_acls.default_action must be one of: 'Allow', 'Deny'."
  }
  validation {
    condition     = try(var.ai_foundry_definition.ai_foundry.network_acls.bypass, null) == null ? true : var.ai_foundry_definition.ai_foundry.network_acls.bypass == "AzureServices"
    error_message = "The ai_foundry.network_acls.bypass must be 'AzureServices' or null."
  }
}
