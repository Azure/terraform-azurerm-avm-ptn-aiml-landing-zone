variable "genai_app_configuration_definition" {
  #TODO: add functionality to the data plane proxy
  type = object({
    data_plane_proxy = optional(object({
      authentication_mode     = string
      private_link_delegation = string
    }), null)
    deploy                        = optional(bool, true)
    name                          = optional(string)
    local_auth_enabled            = optional(bool, false)
    public_network_access_enabled = optional(bool, false)
    purge_protection_enabled      = optional(bool, true)
    sku                           = optional(string, "standard")
    soft_delete_retention_in_days = optional(number, 7)
    tags                          = optional(map(string))
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
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure App Configuration service to be created for GenAI services.

- `data_plane_proxy` - (Optional) Data plane proxy configuration for private endpoints.
  - `authentication_mode` - The authentication mode for the data plane proxy.
  - `private_link_delegation` - The private link delegation setting.
- `deploy` - (Optional) Whether to deploy the App Configuration store. Default is true.
- `name` - (Optional) The name of the App Configuration store. If not provided, a name will be generated.
- `local_auth_enabled` - (Optional) Whether local authentication is enabled. Default is false.
- `public_network_access_enabled` - (Optional) Whether public network access is enabled. Default is false. Azure App Configuration exposes no IP-based network ACLs, so access is restricted through the private endpoint this module creates.
- `purge_protection_enabled` - (Optional) Whether purge protection is enabled. Default is true.
- `sku` - (Optional) The SKU of the App Configuration store. Default is "standard".
- `soft_delete_retention_in_days` - (Optional) The retention period in days for soft delete. Default is 7.
- `tags` - (Optional) Map of tags to assign to the App Configuration store.
- `role_assignments` - (Optional) Map of role assignments to create on the App Configuration store. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `role_definition_id_or_name` - The role definition ID or name to assign.
  - `principal_id` - The principal ID to assign the role to.
  - `description` - (Optional) Description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
  - `condition` - (Optional) Condition for the role assignment.
  - `condition_version` - (Optional) Version of the condition.
  - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
  - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
- `enable_diagnostic_settings` - (Optional) Whether diagnostic settings are enabled. Default is true.
- `diagnostic_settings` - (Optional) Map of diagnostic settings configurations for the App Configuration store. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - (Optional) The name of the diagnostic setting.
  - `log_categories` - (Optional) Set of log categories to enable. Default is an empty set.
  - `log_groups` - (Optional) Set of log groups to enable. Default is ["allLogs"].
  - `metric_categories` - (Optional) Set of metric categories to enable. Default is ["AllMetrics"].
  - `log_analytics_destination_type` - (Optional) The destination type for Log Analytics. Default is "Dedicated".
  - `workspace_resource_id` - (Optional) Resource ID of the Log Analytics workspace.
  - `storage_account_resource_id` - (Optional) Resource ID of the storage account for diagnostics.
  - `event_hub_authorization_rule_resource_id` - (Optional) Resource ID of the Event Hub authorization rule.
  - `event_hub_name` - (Optional) Name of the Event Hub.
  - `marketplace_partner_resource_id` - (Optional) Resource ID of the marketplace partner resource.
DESCRIPTION
}

#TODO:
# Add georeplication support for Container Registry?
variable "genai_container_registry_definition" {
  type = object({
    deploy                        = optional(bool, true)
    name                          = optional(string)
    sku                           = optional(string, "Premium")
    zone_redundancy_enabled       = optional(bool, true)
    public_network_access_enabled = optional(bool, false)
    network_rule_bypass_option    = optional(string, "None")
    network_rule_set = optional(object({
      default_action = optional(string, "Deny")
      ip_rule = optional(list(object({
        action   = optional(string, "Allow")
        ip_range = string
      })), [])
    }), null)
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
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure Container Registry to be created for GenAI services.

- `deploy` - (Optional) Whether to deploy the Container Registry. Default is true.
- `name` - (Optional) The name of the Container Registry. If not provided, a name will be generated.
- `sku` - (Optional) The SKU of the Container Registry. Default is "Premium".
- `zone_redundancy_enabled` - (Optional) Whether zone redundancy is enabled. Default is true.
- `public_network_access_enabled` - (Optional) Whether public network access is enabled. Default is false.
- `network_rule_bypass_option` - (Optional) Whether trusted Azure services can access a network restricted Container Registry. Possible values are "None" and "AzureServices". Default is "None".
- `network_rule_set` - (Optional) IP allowlist applied to the Container Registry. Requires the Premium SKU. Default is null, which leaves the registry firewall unconfigured.
  - `default_action` - (Optional) Action taken when no rule matches. Possible values are "Allow" and "Deny". Default is "Deny".
  - `ip_rule` - (Optional) List of allowed IP ranges. Default is [].
    - `action` - (Optional) The rule action. Azure only permits "Allow". Default is "Allow".
    - `ip_range` - The CIDR block allowed inbound access.
- `enable_diagnostic_settings` - (Optional) Whether diagnostic settings are enabled. Default is true.
- `diagnostic_settings` - (Optional) Map of diagnostic settings configurations for the Container Registry. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - (Optional) The name of the diagnostic setting.
  - `log_categories` - (Optional) Set of log categories to enable. Default is an empty set.
  - `log_groups` - (Optional) Set of log groups to enable. Default is ["allLogs"].
  - `metric_categories` - (Optional) Set of metric categories to enable. Default is ["AllMetrics"].
  - `log_analytics_destination_type` - (Optional) The destination type for Log Analytics. Default is "Dedicated".
  - `workspace_resource_id` - (Optional) Resource ID of the Log Analytics workspace.
  - `storage_account_resource_id` - (Optional) Resource ID of the storage account for diagnostics.
  - `event_hub_authorization_rule_resource_id` - (Optional) Resource ID of the Event Hub authorization rule.
  - `event_hub_name` - (Optional) Name of the Event Hub.
  - `marketplace_partner_resource_id` - (Optional) Resource ID of the marketplace partner resource.
- `tags` - (Optional) Map of tags to assign to the Container Registry.
- `role_assignments` - (Optional) Map of role assignments to create on the Container Registry. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `role_definition_id_or_name` - The role definition ID or name to assign.
  - `principal_id` - The principal ID to assign the role to.
  - `description` - (Optional) Description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
  - `condition` - (Optional) Condition for the role assignment.
  - `condition_version` - (Optional) Version of the condition.
  - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
  - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
DESCRIPTION

  validation {
    condition     = contains(["None", "AzureServices"], var.genai_container_registry_definition.network_rule_bypass_option)
    error_message = "The network_rule_bypass_option must be one of: 'None', 'AzureServices'."
  }
  validation {
    condition     = var.genai_container_registry_definition.network_rule_set == null ? true : contains(["Allow", "Deny"], var.genai_container_registry_definition.network_rule_set.default_action)
    error_message = "The network_rule_set.default_action must be one of: 'Allow', 'Deny'."
  }
}

variable "genai_cosmosdb_definition" {
  type = object({
    deploy                     = optional(bool, true)
    name                       = optional(string)
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
    tags = optional(map(string))
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure Cosmos DB account to be created for GenAI services.

- `deploy` - (Optional) Whether to deploy the Cosmos DB account. Default is true.
- `name` - (Optional) The name of the Cosmos DB account. If not provided, a name will be generated.
- `enable_diagnostic_settings` - (Optional) Whether diagnostic settings are enabled. Default is true.
- `diagnostic_settings` - (Optional) Map of diagnostic settings configurations for the Cosmos DB account. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - (Optional) The name of the diagnostic setting.
  - `log_categories` - (Optional) Set of log categories to enable. Default is an empty set.
  - `log_groups` - (Optional) Set of log groups to enable. Default is ["allLogs"].
  - `metric_categories` - (Optional) Set of metric categories to enable. Default is ["AllMetrics"].
  - `log_analytics_destination_type` - (Optional) The destination type for Log Analytics. Default is "Dedicated".
  - `workspace_resource_id` - (Optional) Resource ID of the Log Analytics workspace.
  - `storage_account_resource_id` - (Optional) Resource ID of the storage account for diagnostics.
  - `event_hub_authorization_rule_resource_id` - (Optional) Resource ID of the Event Hub authorization rule.
  - `event_hub_name` - (Optional) Name of the Event Hub.
  - `marketplace_partner_resource_id` - (Optional) Resource ID of the marketplace partner resource.
- `secondary_regions` - (Optional) List of secondary regions for geo-replication.
  - `location` - The Azure region for the secondary location.
  - `zone_redundant` - (Optional) Whether zone redundancy is enabled for the secondary region. Default is true.
  - `failover_priority` - (Optional) The failover priority for the secondary region. Default is 0.
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
- `analytical_storage_config` - (Optional) Analytical storage configuration.
  - `schema_type` - The schema type for analytical storage.
- `consistency_policy` - (Optional) Consistency policy configuration.
  - `max_interval_in_seconds` - (Optional) Maximum staleness interval in seconds. Default is 300.
  - `max_staleness_prefix` - (Optional) Maximum staleness prefix. Default is 100001.
  - `consistency_level` - (Optional) The consistency level. Default is "Session".
- `backup` - (Optional) Backup configuration.
  - `retention_in_hours` - (Optional) Backup retention in hours.
  - `interval_in_minutes` - (Optional) Backup interval in minutes.
  - `storage_redundancy` - (Optional) Storage redundancy for backups.
  - `type` - (Optional) The backup type.
  - `tier` - (Optional) The backup tier.
- `capabilities` - (Optional) Set of capabilities to enable on the Cosmos DB account.
  - `name` - The name of the capability.
- `capacity` - (Optional) Capacity configuration.
  - `total_throughput_limit` - (Optional) Total throughput limit. Default is -1 (unlimited).
- `cors_rule` - (Optional) CORS rule configuration.
  - `allowed_headers` - Set of allowed headers.
  - `allowed_methods` - Set of allowed HTTP methods.
  - `allowed_origins` - Set of allowed origins.
  - `exposed_headers` - Set of exposed headers.
  - `max_age_in_seconds` - (Optional) Maximum age in seconds for CORS.
- `tags` - (Optional) Map of tags to assign to the Cosmos DB account.
DESCRIPTION
}

variable "genai_key_vault_definition" {
  type = object({
    deploy = optional(bool, true)
    name   = optional(string)
    network_acls = optional(object({
      bypass                     = optional(string, "AzureServices")
      default_action             = optional(string, "Deny")
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
    }), null)
    public_network_access_enabled = optional(bool, false)
    sku                           = optional(string, "standard")
    tenant_id                     = optional(string)
    enable_diagnostic_settings    = optional(bool, true)
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
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure Key Vault to be created for GenAI services.

- `deploy` - (Optional) Whether to deploy the Key Vault. Default is true.
- `name` - (Optional) The name of the Key Vault. If not provided, a name will be generated.
- `network_acls` - (Optional) Network access control list configuration for the Key Vault.
  - `bypass` - (Optional) Services that can bypass the network ACLs. Default is "AzureServices".
  - `default_action` - (Optional) Default action when no rule matches. Default is "Deny".
  - `ip_rules` - (Optional) List of IP addresses or CIDR blocks to allow access.
  - `virtual_network_subnet_ids` - (Optional) List of subnet resource IDs to allow access.
- `public_network_access_enabled` - (Optional) Whether public network access is enabled. Default is false.
- `sku` - (Optional) The SKU of the Key Vault. Default is "standard".
- `tenant_id` - (Optional) The tenant ID for the Key Vault. If not provided, the current tenant will be used.
- `enable_diagnostic_settings` - (Optional) Whether diagnostic settings are enabled. Default is true.
- `diagnostic_settings` - (Optional) Map of diagnostic settings configurations for the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - (Optional) The name of the diagnostic setting.
  - `log_categories` - (Optional) Set of log categories to enable. Default is an empty set.
  - `log_groups` - (Optional) Set of log groups to enable. Default is ["allLogs"].
  - `metric_categories` - (Optional) Set of metric categories to enable. Default is ["AllMetrics"].
  - `log_analytics_destination_type` - (Optional) The destination type for Log Analytics. Default is "Dedicated".
  - `workspace_resource_id` - (Optional) Resource ID of the Log Analytics workspace.
  - `storage_account_resource_id` - (Optional) Resource ID of the storage account for diagnostics.
  - `event_hub_authorization_rule_resource_id` - (Optional) Resource ID of the Event Hub authorization rule.
  - `event_hub_name` - (Optional) Name of the Event Hub.
  - `marketplace_partner_resource_id` - (Optional) Resource ID of the marketplace partner resource.
- `role_assignments` - (Optional) Map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `role_definition_id_or_name` - The role definition ID or name to assign.
  - `principal_id` - The principal ID to assign the role to.
  - `description` - (Optional) Description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
  - `condition` - (Optional) Condition for the role assignment.
  - `condition_version` - (Optional) Version of the condition.
  - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
  - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
- `tags` - (Optional) Map of tags to assign to the Key Vault.
DESCRIPTION
}

variable "genai_storage_account_definition" {
  type = object({
    deploy                     = optional(bool, true)
    name                       = optional(string)
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
    account_kind                  = optional(string, "StorageV2")
    account_tier                  = optional(string, "Standard")
    account_replication_type      = optional(string, "GRS")
    endpoint_types                = optional(set(string), ["blob"])
    access_tier                   = optional(string, "Hot")
    public_network_access_enabled = optional(bool, false)
    shared_access_key_enabled     = optional(bool, true)
    network_rules = optional(object({
      bypass                     = optional(set(string), ["AzureServices"])
      default_action             = optional(string, "Deny")
      ip_rules                   = optional(set(string), [])
      virtual_network_subnet_ids = optional(set(string), [])
      private_link_access = optional(list(object({
        endpoint_resource_id = string
        endpoint_tenant_id   = optional(string)
      })), null)
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

    #TODO:
    # Implement subservice passthrough here
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure Storage Account to be created for GenAI services.

- `deploy` - (Optional) Whether to deploy the Storage Account. Default is true.
- `name` - (Optional) The name of the Storage Account. If not provided, a name will be generated.
- `enable_diagnostic_settings` - (Optional) Whether diagnostic settings are enabled. Default is true.
- `diagnostic_settings` - (Optional) Map of diagnostic settings configurations for the Storage Account. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - (Optional) The name of the diagnostic setting.
  - `log_categories` - (Optional) Set of log categories to enable. Default is an empty set.
  - `log_groups` - (Optional) Set of log groups to enable. Default is ["allLogs"].
  - `metric_categories` - (Optional) Set of metric categories to enable. Default is ["AllMetrics"].
  - `log_analytics_destination_type` - (Optional) The destination type for Log Analytics. Default is "Dedicated".
  - `workspace_resource_id` - (Optional) Resource ID of the Log Analytics workspace.
  - `storage_account_resource_id` - (Optional) Resource ID of the storage account for diagnostics.
  - `event_hub_authorization_rule_resource_id` - (Optional) Resource ID of the Event Hub authorization rule.
  - `event_hub_name` - (Optional) Name of the Event Hub.
  - `marketplace_partner_resource_id` - (Optional) Resource ID of the marketplace partner resource.
- `account_kind` - (Optional) The kind of storage account. Default is "StorageV2".
- `account_tier` - (Optional) The performance tier of the storage account. Default is "Standard".
- `account_replication_type` - (Optional) The replication type for the storage account. Default is "GRS".
- `endpoint_types` - (Optional) Set of endpoint types to enable. Default is ["blob"].
- `access_tier` - (Optional) The access tier for the storage account. Default is "Hot".
- `public_network_access_enabled` - (Optional) Whether public network access is enabled. Default is false.
- `shared_access_key_enabled` - (Optional) Whether shared access keys are enabled. Default is true.
- `network_rules` - (Optional) Storage account firewall configuration. Defaults to `{}`, which denies public traffic while still allowing trusted Azure services. Set to `null` to remove all network rules, which leaves the account reachable from any public network.
  - `bypass` - (Optional) Traffic permitted to bypass the rules. Any combination of "Logging", "Metrics", "AzureServices" or "None". Default is ["AzureServices"].
  - `default_action` - (Optional) Action taken when no rule matches. Possible values are "Allow" and "Deny". Default is "Deny".
  - `ip_rules` - (Optional) Set of public IPv4 addresses or CIDR ranges allowed access. RFC 1918 private ranges are not permitted by Azure. Default is [].
  - `virtual_network_subnet_ids` - (Optional) Set of subnet resource IDs allowed access. Default is [].
  - `private_link_access` - (Optional) List of resource access rules granting private link access. Default is null.
    - `endpoint_resource_id` - The resource ID granted access.
    - `endpoint_tenant_id` - (Optional) The tenant ID of the resource. Defaults to the current tenant.
- `role_assignments` - (Optional) Map of role assignments to create on the Storage Account. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `role_definition_id_or_name` - The role definition ID or name to assign.
  - `principal_id` - The principal ID to assign the role to.
  - `description` - (Optional) Description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
  - `condition` - (Optional) Condition for the role assignment.
  - `condition_version` - (Optional) Version of the condition.
  - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
  - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
- `tags` - (Optional) Map of tags to assign to the Storage Account.
DESCRIPTION

  validation {
    condition     = var.genai_storage_account_definition.network_rules == null ? true : contains(["Allow", "Deny"], var.genai_storage_account_definition.network_rules.default_action)
    error_message = "The network_rules.default_action must be one of: 'Allow', 'Deny'."
  }
  validation {
    condition     = var.genai_storage_account_definition.network_rules == null ? true : length(setsubtract(var.genai_storage_account_definition.network_rules.bypass, ["Logging", "Metrics", "AzureServices", "None"])) == 0
    error_message = "Each network_rules.bypass entry must be one of: 'Logging', 'Metrics', 'AzureServices', 'None'."
  }
}
