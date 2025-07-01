variable "vnet_definition" {
  type = object({
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
}

variable "app_gateway_definition" {
  type = object({
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
  default = {}
}

variable "bastion_definition" {
  type = object({
    name  = optional(string)
    sku   = optional(string, "Standard")
    tags  = optional(map(string), {})
    zones = optional(list(string), ["1", "2", "3"])
  })
  default = {}
}

variable "firewall_definition" {
  type = object({
    name  = optional(string)
    sku   = optional(string, "AZFW_VNet")
    tier  = optional(string, "Standard")
    zones = optional(list(string), ["1", "2", "3"])
    tags  = optional(map(string), {})
  })
  default = {}
}

variable "hub_vnet_peering_definition" {
  type = object({
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
  default = {}
}

variable "nsgs_definition" {
  type = object({
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
  default = {}
}

variable "private_dns_zones" {
  type = object({
    existing_zones_subscription_id     = optional(string)
    existing_zones_resource_group_name = optional(string)
    network_links = optional(map(object({
      vnetlinkname     = string
      vnetid           = string
      autoregistration = optional(bool, false)
    })), {})
  })
  default = {}
}

variable "waf_policy_definition" {
  type = object({
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
  default = {}
}
