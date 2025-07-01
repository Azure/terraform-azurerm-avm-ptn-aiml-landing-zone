<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-ptn-aiml-landing-zone

This pattern module creates the full AI/ML landing zone which supports multiple ai project scenarios.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azapi_resource.bing_grounding](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_integer.zone_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_string.name_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azapi_client_config.telemetry](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_private_dns_zone.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/private_dns_zone) (data source)
- [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)
- [azurerm_subscription.dns_zones](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_vnet_definition"></a> [vnet\_definition](#input\_vnet\_definition)

Description: n/a

Type:

```hcl
object({
    name                             = optional(string)
    address_space                    = string
    ddos_protection_plan_resource_id = optional(string)
    dns_servers                      = optional(set(string))
    subnets = optional(map(object({
      enabled        = optional(bool, true)
      name           = optional(string)
      address_prefix = optional(string)
      }
    )), {})
    peer_vnet_resource_id = optional(string)
  })
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_app_gateway_definition"></a> [app\_gateway\_definition](#input\_app\_gateway\_definition)

Description: n/a

Type:

```hcl
object({
    name         = optional(string)
    http2_enable = optional(bool, true)
    authentication_certificate = optional(map(object({
      name = string
      data = string
    })), null)
    sku = optional(object({
      name     = optional(string, "Standard_v2")
      tier     = optional(string, "Standard_v2")
      capacity = optional(number, 2)
    }), {})

    autoscale_configuration = optional(object({
      max_capacity = optional(number, 2)
      min_capacity = optional(number, 2)
    }), {})

    backend_address_pools = map(object({
      name         = string
      fqdns        = optional(set(string))
      ip_addresses = optional(set(string))
    }))

    backend_http_settings = map(object({
      cookie_based_affinity               = optional(string, "Disabled")
      name                                = string
      port                                = number
      protocol                            = string
      affinity_cookie_name                = optional(string)
      host_name                           = optional(string)
      path                                = optional(string)
      pick_host_name_from_backend_address = optional(bool)
      probe_name                          = optional(string)
      request_timeout                     = optional(number)
      trusted_root_certificate_names      = optional(list(string))
      authentication_certificate          = optional(list(object({ name = string })))
      connection_draining = optional(object({
        drain_timeout_sec          = number
        enable_connection_draining = bool
      }))
    }))

    frontend_ports = map(object({
      name = string
      port = number
    }))

    http_listeners = map(object({
      name                           = string
      frontend_port_name             = string
      frontend_ip_configuration_name = optional(string)
      firewall_policy_id             = optional(string)
      require_sni                    = optional(bool)
      host_name                      = optional(string)
      host_names                     = optional(list(string))
      ssl_certificate_name           = optional(string)
      ssl_profile_name               = optional(string)
      custom_error_configuration = optional(list(object({
        status_code           = string
        custom_error_page_url = string
      })))
    }))

    probe_configurations = optional(map(object({
      name                                      = string
      host                                      = optional(string)
      interval                                  = number
      timeout                                   = number
      unhealthy_threshold                       = number
      protocol                                  = string
      port                                      = optional(number)
      path                                      = string
      pick_host_name_from_backend_http_settings = optional(bool)
      minimum_servers                           = optional(number)
      match = optional(object({
        body        = optional(string)
        status_code = optional(list(string))
      }))
    })), null)

    redirect_configuration = optional(map(object({
      include_path         = optional(bool)
      include_query_string = optional(bool)
      name                 = string
      redirect_type        = string
      target_listener_name = optional(string)
      target_url           = optional(string)
    })), null)

    request_routing_rules = map(object({
      name                        = string
      rule_type                   = string
      http_listener_name          = string
      backend_address_pool_name   = string
      priority                    = number
      url_path_map_name           = optional(string)
      backend_http_settings_name  = string
      redirect_configuration_name = optional(string)
      rewrite_rule_set_name       = optional(string)
    }))

    rewrite_rule_set = optional(map(object({
      name = string
      rewrite_rules = optional(map(object({
        name          = string
        rule_sequence = number
        conditions = optional(map(object({
          ignore_case = optional(bool)
          negate      = optional(bool)
          pattern     = string
          variable    = string
        })))
        request_header_configurations = optional(map(object({
          header_name  = string
          header_value = string
        })))
        response_header_configurations = optional(map(object({
          header_name  = string
          header_value = string
        })))
        url = optional(object({
          components   = optional(string)
          path         = optional(string)
          query_string = optional(string)
          reroute      = optional(bool)
        }))
      })))
    })), null)

    ssl_certificates = optional(map(object({
      name                = string
      data                = optional(string)
      password            = optional(string)
      key_vault_secret_id = optional(string)
    })), null)

    ssl_policy = optional(object({
      cipher_suites        = optional(list(string))
      disabled_protocols   = optional(list(string))
      min_protocol_version = optional(string, "TLSv1_2")
      policy_name          = optional(string)
      policy_type          = optional(string)
    }), null)

    ssl_profile = optional(map(object({
      name                                 = string
      trusted_client_certificate_names     = optional(list(string))
      verify_client_cert_issuer_dn         = optional(bool, false)
      verify_client_certificate_revocation = optional(string, "OCSP")
      ssl_policy = optional(object({
        cipher_suites        = optional(list(string))
        disabled_protocols   = optional(list(string))
        min_protocol_version = optional(string, "TLSv1_2")
        policy_name          = optional(string)
        policy_type          = optional(string)
      }))
    })), null)

    trusted_client_certificate = optional(map(object({
      data = string
      name = string
    })), null)

    trusted_root_certificate = optional(map(object({
      data                = optional(string)
      key_vault_secret_id = optional(string)
      name                = string
    })), null)

    url_path_map_configurations = optional(map(object({
      name                                = string
      default_redirect_configuration_name = optional(string)
      default_rewrite_rule_set_name       = optional(string)
      default_backend_http_settings_name  = optional(string)
      default_backend_address_pool_name   = optional(string)
      path_rules = map(object({
        name                        = string
        paths                       = list(string)
        backend_address_pool_name   = optional(string)
        backend_http_settings_name  = optional(string)
        redirect_configuration_name = optional(string)
        rewrite_rule_set_name       = optional(string)
        firewall_policy_id          = optional(string)
      }))
    })), null)

    tags = optional(map(string), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
  })
```

Default: `{}`

### <a name="input_bastion_definition"></a> [bastion\_definition](#input\_bastion\_definition)

Description: n/a

Type:

```hcl
object({
    name  = optional(string)
    sku   = optional(string, "Standard")
    tags  = optional(map(string), {})
    zones = optional(list(string), ["1", "2", "3"])
  })
```

Default: `{}`

### <a name="input_container_app_environment_definition"></a> [container\_app\_environment\_definition](#input\_container\_app\_environment\_definition)

Description: Definition of the Container App Environment to be created for GenAI services.

Type:

```hcl
object({
    name                                = optional(string)
    tags                                = optional(map(string), {})
    internal_load_balancer_enabled      = optional(bool, true)
    log_analytics_workspace_resource_id = optional(string)
    zone_redundancy_enabled             = optional(bool, true)
    user_assigned_managed_identity_ids  = optional(list(string), [])
    workload_profile = optional(list(object({
      name                  = string
      workload_profile_type = string
      })), [{
      name                  = "Consumption"
      workload_profile_type = "Consumption"
    }])
    app_logs_configuration = optional(object({
      destination = string
      log_analytics = optional(object({
        customer_id = string
        shared_key  = string
      }), null)
    }), null)

    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
  })
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_firewall_definition"></a> [firewall\_definition](#input\_firewall\_definition)

Description: n/a

Type:

```hcl
object({
    name  = optional(string)
    sku   = optional(string, "AZFW_VNet")
    tier  = optional(string, "Standard")
    zones = optional(list(string), ["1", "2", "3"])
    tags  = optional(map(string), {})
  })
```

Default: `{}`

### <a name="input_flag_platform_landing_zone"></a> [flag\_platform\_landing\_zone](#input\_flag\_platform\_landing\_zone)

Description: Flag to indicate if the platform landing zone is enabled. If true, the module will deploy resources and connect to a platform landing zone hub.

Type: `bool`

Default: `true`

### <a name="input_flag_split_deployment_persona"></a> [flag\_split\_deployment\_persona](#input\_flag\_split\_deployment\_persona)

Description: Flag to indicate which part to deploy in a split deployment. Valid values are build, or lza. If set to build, the module will deploy the initial vnet, bastion, and build machine resources. If set to platform, the module will deploy the remaining landing zone resources.

Type: `string`

Default: `"lza"`

### <a name="input_genai_app_configuration_definition"></a> [genai\_app\_configuration\_definition](#input\_genai\_app\_configuration\_definition)

Description: Definition of the App Configuration to be created for GenAI services.

Type:

```hcl
object({
    data_plan_proxy = optional(object({
      authentication_mode     = string
      private_link_delegation = string
    }), null)
    name                          = optional(string)
    local_auth_enabled            = optional(bool, false)
    purge_protection_enabled      = optional(bool, true)
    sku                           = optional(string, "standard")
    soft_delete_retention_in_days = optional(number, 7)
    tags                          = optional(map(string), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
  })
```

Default: `{}`

### <a name="input_genai_container_registry_definition"></a> [genai\_container\_registry\_definition](#input\_genai\_container\_registry\_definition)

Description: Definition of the Container Registry to be created for GenAI services.

Type:

```hcl
object({
    name                          = optional(string)
    sku                           = optional(string, "Premium")
    zone_redundancy_enabled       = optional(bool, true)
    public_network_access_enabled = optional(bool, false)
    tags                          = optional(map(string), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
  })
```

Default: `{}`

### <a name="input_genai_cosmosdb_definition"></a> [genai\_cosmosdb\_definition](#input\_genai\_cosmosdb\_definition)

Description: Definition of the Cosmos DB account to be created for GenAI services.

Type:

```hcl
object({
    name = optional(string)
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
```

Default: `{}`

### <a name="input_genai_key_vault_definition"></a> [genai\_key\_vault\_definition](#input\_genai\_key\_vault\_definition)

Description: Definition of the Key Vault to be created for GenAI services.

Type:

```hcl
object({
    name      = optional(string)
    sku       = optional(string, "standard")
    tenant_id = optional(string)
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
    tags = optional(map(string), {})
  })
```

Default: `{}`

### <a name="input_genai_storage_account_definition"></a> [genai\_storage\_account\_definition](#input\_genai\_storage\_account\_definition)

Description: Definition of the Storage Account to be created for GenAI services.

Type:

```hcl
object({
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
```

Default: `{}`

### <a name="input_hub_vnet_peering_definition"></a> [hub\_vnet\_peering\_definition](#input\_hub\_vnet\_peering\_definition)

Description: n/a

Type:

```hcl
object({
    peer_vnet_resource_id                = optional(string)
    firewall_ip_address                  = optional(string)
    name                                 = optional(string)
    allow_forwarded_traffic              = optional(bool, true)
    allow_gateway_transit                = optional(bool, true)
    allow_virtual_network_access         = optional(bool, true)
    create_reverse_peering               = optional(bool, true)
    reverse_allow_forwarded_traffic      = optional(bool, false)
    reverse_allow_gateway_transit        = optional(bool, false)
    reverse_allow_virtual_network_access = optional(bool, true)
    reverse_name                         = optional(string)
    reverse_use_remote_gateways          = optional(bool, false)
    use_remote_gateways                  = optional(bool, false)
  })
```

Default: `{}`

### <a name="input_jumpvm_definition"></a> [jumpvm\_definition](#input\_jumpvm\_definition)

Description: Definition of the Jump VM to be created for managing the implementation services.

Type:

```hcl
object({
    name             = optional(string)
    sku              = optional(string, "Standard_B2s")
    tags             = optional(map(string), {})
    enable_telemetry = optional(bool, true)
  })
```

Default: `{}`

### <a name="input_ks_ai_search_definition"></a> [ks\_ai\_search\_definition](#input\_ks\_ai\_search\_definition)

Description: Definition of the AI Search service to be created as part of the enterprise and public knowledge services.

Type:

```hcl
object({
    name                          = optional(string)
    sku                           = optional(string, "standard")
    local_authentication_enabled  = optional(bool, true)
    partition_count               = optional(number, 1)
    public_network_access_enabled = optional(bool, false)
    replica_count                 = optional(number, 2)
    semantic_search_sku           = optional(string, "standard")
    tags                          = optional(map(string), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
    enable_telemetry = optional(bool, true)
  })
```

Default: `{}`

### <a name="input_ks_bing_grounding_definition"></a> [ks\_bing\_grounding\_definition](#input\_ks\_bing\_grounding\_definition)

Description: Definition of the Bing Grounding service to be created as part of the enterprise and public knowledge services.

Type:

```hcl
object({
    name = optional(string)
    sku  = optional(string, "G1")
    tags = optional(map(string), {})
  })
```

Default: `{}`

### <a name="input_law_definition"></a> [law\_definition](#input\_law\_definition)

Description: Definition of the Log Analytics Workspace to be created. If `resource_id` is provided, the workspace will not be created and the other inputs will be ignored, and the workspace id provided will be used.

Type:

```hcl
object({
    resource_id = optional(string)
    name        = optional(string)
    retention   = optional(number, 30)
    sku         = optional(string, "PerGB2018")
    tags        = optional(map(string), {})
  })
```

Default: `{}`

### <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix)

Description: Optional Prefix to be used for naming resources. This is useful for ensuring standard naming without requiring a name input for each name.

Type: `string`

Default: `null`

### <a name="input_nsgs_definition"></a> [nsgs\_definition](#input\_nsgs\_definition)

Description: n/a

Type:

```hcl
object({
    name = optional(string)
    security_rules = optional(map(object({
      access                                     = string
      description                                = optional(string)
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(set(string))
      destination_application_security_group_ids = optional(set(string))
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(set(string))
      direction                                  = string
      name                                       = string
      priority                                   = number
      protocol                                   = string
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(set(string))
      source_application_security_group_ids      = optional(set(string))
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(set(string))
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    })))
  })
```

Default: `{}`

### <a name="input_private_dns_zones"></a> [private\_dns\_zones](#input\_private\_dns\_zones)

Description: n/a

Type:

```hcl
object({
    existing_zones_subscription_id     = optional(string)
    existing_zones_resource_group_name = optional(string)
    network_links = optional(map(object({
      vnetlinkname     = string
      vnetid           = string
      autoregistration = optional(bool, false)
    })), {})
  })
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Map of tags to be assigned to this resource

Type: `map(string)`

Default: `null`

### <a name="input_waf_policy_definition"></a> [waf\_policy\_definition](#input\_waf\_policy\_definition)

Description: n/a

Type:

```hcl
object({
    name = optional(string)
    policy_settings = optional(object({
      enabled                  = optional(bool, true)
      mode                     = optional(string, "Prevention")
      request_body_check       = optional(bool, true)
      max_request_body_size_kb = optional(number, 128)
      file_upload_limit_mb     = optional(number, 100)
    }), {})
    managed_rules = optional(object({
      exclusion = optional(map(object({
        match_variable          = string
        selector                = string
        selector_match_operator = string
        excluded_rule_set = optional(object({
          type    = optional(string)
          version = optional(string)
          rule_group = optional(list(object({
            excluded_rules  = optional(list(string))
            rule_group_name = string
          })))
        }))
      })), null)
      managed_rule_set = map(object({
        type    = optional(string)
        version = string
        rule_group_override = optional(map(object({
          rule_group_name = string
          rule = optional(list(object({
            action  = optional(string)
            enabled = optional(bool)
            id      = string
          })))
        })))
      }))
    }), null)

    tags = optional(map(string), {})
  })
```

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_subnets"></a> [subnets](#output\_subnets)

Description: n/a

## Modules

The following Modules are called:

### <a name="module_ai_lz_vnet"></a> [ai\_lz\_vnet](#module\_ai\_lz\_vnet)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: =0.7.1

### <a name="module_app_configuration"></a> [app\_configuration](#module\_app\_configuration)

Source: Azure/avm-res-appconfiguration-configurationstore/azure

Version: 0.1.0

### <a name="module_app_gateway_waf_policy"></a> [app\_gateway\_waf\_policy](#module\_app\_gateway\_waf\_policy)

Source: Azure/avm-res-network-applicationgatewaywebapplicationfirewallpolicy/azurerm

Version: 0.2.0

### <a name="module_application_gateway"></a> [application\_gateway](#module\_application\_gateway)

Source: Azure/avm-res-network-applicationgateway/azurerm

Version: 0.4.2

### <a name="module_avm-utl-regions"></a> [avm-utl-regions](#module\_avm-utl-regions)

Source: Azure/avm-utl-regions/azurerm

Version: 0.5.2

### <a name="module_avm_res_keyvault_vault"></a> [avm\_res\_keyvault\_vault](#module\_avm\_res\_keyvault\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: =0.10.0

### <a name="module_azure_bastion"></a> [azure\_bastion](#module\_azure\_bastion)

Source: Azure/avm-res-network-bastionhost/azurerm

Version: 0.7.2

### <a name="module_container_apps_managed_environment"></a> [container\_apps\_managed\_environment](#module\_container\_apps\_managed\_environment)

Source: Azure/avm-res-app-managedenvironment/azurerm

Version: 0.3.0

### <a name="module_containerregistry"></a> [containerregistry](#module\_containerregistry)

Source: Azure/avm-res-containerregistry-registry/azurerm

Version: 0.4.0

### <a name="module_cosmosdb"></a> [cosmosdb](#module\_cosmosdb)

Source: Azure/avm-res-documentdb-databaseaccount/azurerm

Version: 0.8.0

### <a name="module_firewall"></a> [firewall](#module\_firewall)

Source: Azure/avm-res-network-azurefirewall/azurerm

Version: 0.3.0

### <a name="module_firewall_policy"></a> [firewall\_policy](#module\_firewall\_policy)

Source: Azure/avm-res-network-firewallpolicy/azurerm

Version: 0.3.3

### <a name="module_firewall_route_table"></a> [firewall\_route\_table](#module\_firewall\_route\_table)

Source: Azure/avm-res-network-routetable/azurerm

Version: 0.4.1

### <a name="module_fw_pip"></a> [fw\_pip](#module\_fw\_pip)

Source: Azure/avm-res-network-publicipaddress/azurerm

Version: 0.2.0

### <a name="module_hub_vnet_peering"></a> [hub\_vnet\_peering](#module\_hub\_vnet\_peering)

Source: Azure/avm-res-network-virtualnetwork/azurerm//modules/peering

Version: 0.9.0

### <a name="module_jumpvm"></a> [jumpvm](#module\_jumpvm)

Source: Azure/avm-res-compute-virtualmachine/azurerm

Version: 0.19.3

### <a name="module_log_analytics_workspace"></a> [log\_analytics\_workspace](#module\_log\_analytics\_workspace)

Source: Azure/avm-res-operationalinsights-workspace/azurerm

Version: 0.4.2

### <a name="module_nsgs"></a> [nsgs](#module\_nsgs)

Source: Azure/avm-res-network-networksecuritygroup/azurerm

Version: 0.4.0

### <a name="module_private_dns_zones"></a> [private\_dns\_zones](#module\_private\_dns\_zones)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: 0.3.4

### <a name="module_search_service"></a> [search\_service](#module\_search\_service)

Source: Azure/avm-res-search-searchservice/azurerm

Version: 0.1.5

### <a name="module_storage_account"></a> [storage\_account](#module\_storage\_account)

Source: Azure/avm-res-storage-storageaccount/azurerm

Version: 0.6.3

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->