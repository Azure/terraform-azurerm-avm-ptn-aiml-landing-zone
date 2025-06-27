#TODO:
# Add georeplication support for Container Registry?
variable "genai_container_registry_definition" {
  type = object({
    name                          = optional(string)
    private_dns_zone_resource_id  = optional(string)
    sku                           = optional(string, "Premium")
    zone_redundancy_enabled       = optional(bool, true)
    public_network_access_enabled = optional(bool, false)
    tags                          = optional(map(string), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
  })
  default     = {}
  description = "Definition of the Container Registry to be created for GenAI services."
}

variable "genai_cosmosdb_definition" {
  type = object({
    name                         = optional(string)
    private_dns_zone_resource_id = optional(string)
    secondary_regions = optional(list(object({
      location          = string
      zone_redundant    = optional(bool, true)
      failover_priority = optional(number, 0)
    })), [])
    public_network_access_enabled    = optional(bool, false)
    analytical_storage_enabled       = optional(bool, true)
    automatic_failover_enabled       = optional(bool, false)
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



  })
  default     = {}
  description = "Definition of the Cosmos DB account to be created for GenAI services."
}

variable "genai_key_vault_definition" {
  type = object({
    name                         = optional(string)
    private_dns_zone_resource_id = optional(string)
    sku                          = optional(string, "standard")
    tenant_id                    = optional(string)
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
    tags = optional(map(string), {})
  })
  default     = {}
  description = "Definition of the Key Vault to be created for GenAI services."
}

variable "genai_storage_account_definition" {
  type = object({
    name                          = optional(string)
    account_kind                  = optional(string, "StorageV2")
    account_tier                  = optional(string, "Standard")
    account_replication_type      = optional(string, "GRS")
    endpoint_types                = optional(set(string), ["blob"])
    access_tier                   = optional(string, "Hot")
    public_network_access_enabled = optional(bool, false)
    shared_access_key_enabled     = optional(bool, true)
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
    tags = optional(map(string), {})

    #TODO:
    # Implement subservice passthrough here
  })
  default     = {}
  description = "Definition of the Storage Account to be created for GenAI services."
}
