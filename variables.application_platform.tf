variable "application_platform" {
  type = object({
    environment_name               = optional(string)
    cosmos_location                = optional(string)
    deployment_mode                = optional(string)
    deployment_tags                = optional(map(string), {})
    release                        = optional(string, "unreleased")
    resource_token                 = optional(string)
    app_config_label               = optional(string, "ai-lz")
    app_runtime_configuration_mode = optional(string, "appConfig")
    populate_app_configuration     = optional(bool, false)
    deploy_software                = optional(bool, true)
    use_zone_redundancy            = optional(bool)
    additional_app_configuration_settings = optional(map(object({
      value        = string
      label        = optional(string)
      content_type = optional(string, "text/plain")
    })), {})
    acr_task_agent_pool = optional(object({
      enabled = optional(bool, false)
      name    = optional(string, "build-pool")
      tier    = optional(string, "S1")
      count   = optional(number, 1)
    }), {})
    container_apps = optional(map(object({
      name                         = optional(string)
      image                        = string
      target_port                  = optional(number, 80)
      external_ingress_enabled     = optional(bool, false)
      transport                    = optional(string, "auto")
      min_replicas                 = optional(number, 0)
      max_replicas                 = optional(number, 1)
      cpu                          = optional(number, 0.5)
      memory                       = optional(string, "1Gi")
      env                          = optional(map(string), {})
      use_private_registry         = optional(bool, false)
      grant_key_vault_secrets_user = optional(bool, false)
      dapr = optional(object({
        enabled      = optional(bool, true)
        app_id       = optional(string)
        app_port     = optional(number)
        app_protocol = optional(string, "http")
      }))
    })), {})
    foundry_iq = optional(object({
      enable_agentic_retrieval         = optional(bool, false)
      retrieval_backend                = optional(string, "foundry_iq")
      pattern                          = optional(string, "azureBlob")
      api_version                      = optional(string, "2026-05-01-preview")
      knowledge_retrieval_billing_plan = optional(string, "free")
      knowledge_base_name              = optional(string)
      knowledge_base_connection_name   = optional(string)
      knowledge_base_connection_id     = optional(string, "")
      knowledge_base_endpoint          = optional(string, "")
      knowledge_source_name            = optional(string)
      knowledge_source_kind            = optional(string, "")
      storage_container_name           = optional(string, "documents")
      storage_folder_path              = optional(string, "")
      is_adls_gen2                     = optional(bool, false)
      content_extraction_mode          = optional(string, "standard")
      ai_services_endpoint             = optional(string, "")
      ingestion_permission_options     = optional(list(string), ["rbacScope"])
      search_index_name                = optional(string, "gpt-rag-index")
      semantic_configuration_name      = optional(string, "default")
      source_data_fields               = optional(list(string), ["id", "title", "filepath", "url", "content"])
      search_fields                    = optional(list(string), ["content"])
      base_filter                      = optional(string, "")
      filter_add_on_enabled            = optional(bool, true)
      security_field_name              = optional(string, "metadata_security_id")
      max_output_documents             = optional(string, "")
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Additive Application Platform configuration aligned to the authorized Bicep parity handoff. Existing module behavior remains the default: the private topology, `name_prefix`, Container Apps Environment settings, and App Configuration deployment are unchanged.

- `environment_name` - Deployment environment identifier. Defaults to `resource_group_name`.
- `cosmos_location` - Runtime metadata for the Cosmos DB location. Defaults to `location`; it does not move existing resources.
- `deployment_mode` - Optional deployment intent: `standalone` or `ailz-integrated`. When unset it is derived from `flag_platform_landing_zone`.
- `deployment_tags` - Additional deployment metadata tags included in runtime configuration.
- `release` - Release metadata surfaced to workloads. Defaults to `unreleased` and does not claim a published release.
- `resource_token` - Stable consumer token. Defaults to the module's existing persisted random suffix.
- `app_config_label` - Label for optional App Configuration key-values.
- `app_runtime_configuration_mode` - Runtime configuration mode: `appConfig`, `containerEnv`, or `none`. The default preserves the existing App Configuration mode.
- `populate_app_configuration` - Opts into deploying non-secret runtime key-values. Defaults to false because this module's network-isolated topology normally requires post-provision population from a connected runner.
- `deploy_software` - Compatibility handoff flag surfaced in outputs. It does not install software.
- `use_zone_redundancy` - Optional override for the existing Container Apps Environment and Container Registry zone-redundancy settings. Null preserves their current defaults.
- `additional_app_configuration_settings` - Non-secret passthrough settings. Map keys are App Configuration keys.
- `acr_task_agent_pool` - Optional private ACR Task agent pool configuration. Disabled by default.
- `container_apps` - Optional workload map. Each workload receives a user-assigned managed identity. Private-registry workloads receive AcrPull before the app is created; appConfig workloads receive App Configuration Data Reader; Key Vault access is opt-in.
- `foundry_iq` - Runtime-only Foundry IQ handoff values. This change does not create Foundry IQ data-plane knowledge bases or sources.
DESCRIPTION
  nullable    = false

  validation {
    condition     = var.application_platform.deployment_mode == null || contains(["standalone", "ailz-integrated"], var.application_platform.deployment_mode)
    error_message = "application_platform.deployment_mode must be null, \"standalone\", or \"ailz-integrated\"."
  }
  validation {
    condition     = contains(["appConfig", "containerEnv", "none"], var.application_platform.app_runtime_configuration_mode)
    error_message = "application_platform.app_runtime_configuration_mode must be \"appConfig\", \"containerEnv\", or \"none\"."
  }
  validation {
    condition     = !var.application_platform.populate_app_configuration || var.application_platform.app_runtime_configuration_mode == "appConfig"
    error_message = "application_platform.populate_app_configuration can be true only when app_runtime_configuration_mode is \"appConfig\"."
  }
  validation {
    condition = (
      contains(["S1", "S2", "S3"], var.application_platform.acr_task_agent_pool.tier) &&
      var.application_platform.acr_task_agent_pool.count >= 0 &&
      length(var.application_platform.acr_task_agent_pool.name) <= 20
    )
    error_message = "The ACR Task agent pool tier must be S1, S2, or S3; count must be non-negative; and name must be at most 20 characters."
  }
  validation {
    condition = alltrue([
      for app in values(var.application_platform.container_apps) :
      app.min_replicas >= 0 && app.max_replicas >= app.min_replicas && app.target_port >= 1 && app.target_port <= 65535
    ])
    error_message = "Each container app must use a target_port from 1 to 65535 and max_replicas must be greater than or equal to min_replicas."
  }
  validation {
    condition     = contains(["ai_search", "foundry_iq"], var.application_platform.foundry_iq.retrieval_backend)
    error_message = "application_platform.foundry_iq.retrieval_backend must be \"ai_search\" or \"foundry_iq\"."
  }
  validation {
    condition     = contains(["azureBlob", "managed", "searchIndex"], var.application_platform.foundry_iq.pattern)
    error_message = "application_platform.foundry_iq.pattern must be \"azureBlob\", \"managed\", or \"searchIndex\"."
  }
}

variable "ignore_body_changes" {
  type = object({
    app_container_apps                               = optional(list(string), [])
    appconfiguration_configuration_stores_key_values = optional(list(string), [])
    authorization_role_assignments                   = optional(list(string), [])
    containerregistry_registries_agent_pools         = optional(list(string), [])
    managedidentity_user_assigned_identities         = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths ignored on Application Platform AzAPI resources. Paths use dot notation; changes take effect only after apply, and configuration for an ignored path is not sent to Azure until the path is removed.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    app_container_apps                               = optional(string, "Microsoft.App/containerApps@2025-01-01")
    appconfiguration_configuration_stores_key_values = optional(string, "Microsoft.AppConfiguration/configurationStores/keyValues@2024-05-01")
    authorization_role_assignments                   = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    containerregistry_registries_agent_pools         = optional(string, "Microsoft.ContainerRegistry/registries/agentPools@2025-03-01-preview")
    managedidentity_user_assigned_identities         = optional(string, "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31")
  })
  default     = {}
  description = "AzAPI resource types and API versions used by the additive Application Platform resources."
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
    multiplier           = optional(number)
    randomization_factor = optional(number)
  })
  default     = null
  description = "Retry configuration applied to Application Platform AzAPI resources."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Timeout configuration applied to Application Platform AzAPI resources."
}
