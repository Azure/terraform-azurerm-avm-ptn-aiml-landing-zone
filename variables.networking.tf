variable "vnet_definition" {
  type = object({
    name = optional(string)
    existing_byo_vnet = optional(map(object({
      vnet_resource_id    = string
      firewall_ip_address = optional(string)
      }
    )), {})
    address_space = optional(string, "192.168.0.0/20")
    ipam_pools = optional(list(object({
      id            = string
      prefix_length = string
    })))
    ddos_protection_plan_resource_id = optional(string)
    dns_servers                      = optional(set(string), [])
    subnets = optional(map(object({
      enabled        = optional(bool, true)
      name           = optional(string)
      address_prefix = optional(string)
      ipam_pools = optional(list(object({
        pool_id       = string
        prefix_length = string
      })))
      }
    )), {})
    vnet_peering_configuration = optional(object({
      peer_vnet_resource_id                = optional(string)
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
    }), {})
    vwan_hub_peering_configuration = optional(object({
      peer_vwan_hub_resource_id = optional(string)
      #TODO: Add other connection properties here?
    }), {})
  })
  description = <<DESCRIPTION
Configuration object for the Virtual Network (VNet) to be deployed.

- `name` - (Optional) The name of the Virtual Network. If not provided, a name will be generated.
- `existing_byo_vnet` - (Optional) Map to configure use of an existing Virtual Network (BYO VNet). If provided, no new VNet will be created. The module will add subnets to the existing VNet during deployment, so ensure that the deployer account has sufficient permissions to create subnets. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `vnet_resource_id` - Resource ID of the existing Virtual Network to use.
  - `firewall_ip_address` - (Optional) IP address of the firewall if a firewall is deployed for use by the BYO vnet. This IP address wlll be used to configure the route table for the subnets when provided. If using a BYO Vnet, the firewall is assumed to be deployed and configured outside of this module.
- `address_space` - (Optional) The address space for the Virtual Network in CIDR notation. Defaults to 192.168.0.0/20 if none provided. Not used when `existing_byo_vnet` is configured.
- `ipam_pools` - (Optional) List of IPAM pools to associate with the VNet. If present, the address_space will be ignored and IPAM pools will be used for address allocation.
  - `id` - The ID of the IPAM pool.
  - `prefix_length` - The prefix length to request from the IPAM pool.
- `ddos_protection_plan_resource_id` - (Optional) Resource ID of the DDoS Protection Plan to associate with the VNet. This is not used for BYO VNet configurations as that is assumed to be handled outside the module.
- `dns_servers` - (Optional) Set of custom DNS server IP addresses for the VNet.
- `subnets` - (Optional) Map of subnet configurations that can be used to override the default subnet configurations. The map key must match the desired subnet usage to override the default configuration.
  - `enabled` - (Optional) Whether the subnet is enabled. Default is true.
  - `name` - (Optional) The name of the subnet. If not provided, a name will be generated.
  - `address_prefix` - (Optional) The address prefix for the subnet in CIDR notation.
  - `ipam_pools` - (Optional) List of IPAM pools to associate with the subnet. If present, the address_prefix will be ignored and IPAM pools will be used for address allocation.
    - `pool_id` - The ID of the IPAM pool.
    - `prefix_length` - The prefix length to request from the IPAM pool.
- `vnet_peering_configuration` - (Optional) Configuration for VNet peering. This is not used for BYO VNet configurations as that is assumed to be handled outside the module.
  - `peer_vnet_resource_id` - (Optional) Resource ID of the peer VNet.
  - `name` - (Optional) Name of the peering connection.
  - `allow_forwarded_traffic` - (Optional) Whether forwarded traffic is allowed. Default is true.
  - `allow_gateway_transit` - (Optional) Whether gateway transit is allowed. Default is true.
  - `allow_virtual_network_access` - (Optional) Whether virtual network access is allowed. Default is true.
  - `create_reverse_peering` - (Optional) Whether to create reverse peering. Default is true.
  - `reverse_allow_forwarded_traffic` - (Optional) Whether reverse forwarded traffic is allowed. Default is false.
  - `reverse_allow_gateway_transit` - (Optional) Whether reverse gateway transit is allowed. Default is false.
  - `reverse_allow_virtual_network_access` - (Optional) Whether reverse virtual network access is allowed. Default is true.
  - `reverse_name` - (Optional) Name of the reverse peering connection.
  - `reverse_use_remote_gateways` - (Optional) Whether to use remote gateways in reverse direction. Default is false.
  - `use_remote_gateways` - (Optional) Whether to use remote gateways. Default is false.
- `vwan_hub_peering_configuration` - (Optional) Configuration for Virtual WAN hub peering. This is not used for BYO VNet configurations as that is assumed to be handled outside the module.
  - `peer_vwan_hub_resource_id` - (Optional) Resource ID of the Virtual WAN hub to peer with.

DESCRIPTION
}

variable "app_gateway_definition" {
  type = object({
    deploy       = optional(bool, false)
    name         = optional(string)
    http2_enable = optional(bool, true)
    authentication_certificate = optional(map(object({
      name = string
      data = string
    })), null)
    sku = optional(object({
      name     = optional(string, "WAF_v2")
      tier     = optional(string, "WAF_v2")
      capacity = optional(number)
    }), {})

    autoscale_configuration = optional(object({
      max_capacity = optional(number, 10)
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
  default     = null
  description = <<DESCRIPTION
Configuration object for the Azure Application Gateway to be deployed.

- `deploy` - (Optional) Deploy the application gateway. Default is true.
- `name` - (Optional) The name of the Application Gateway. If not provided, a name will be generated.
- `http2_enable` - (Optional) Whether HTTP/2 is enabled. Default is true.
- `authentication_certificate` - (Optional) Map of authentication certificates for backend authentication.
  - `name` - The name of the authentication certificate.
  - `data` - The base64 encoded certificate data.
- `sku` - (Optional) SKU configuration for the Application Gateway.
  - `name` - (Optional) The SKU name. Default is "WAF_v2".
  - `tier` - (Optional) The SKU tier. Default is "WAF_v2".
  - `capacity` - (Optional) The instance capacity (fixed scale units).
- `autoscale_configuration` - (Optional) Autoscale configuration.
  - `max_capacity` - (Optional) Maximum number of scale units. Default is 10.
  - `min_capacity` - (Optional) Minimum number of scale units. Default is 2.
- `backend_address_pools` - (Required) Map of backend address pools. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - The name of the backend address pool.
  - `fqdns` - (Optional) Set of FQDNs for the backend pool.
  - `ip_addresses` - (Optional) Set of IP addresses for the backend pool.
- `backend_http_settings` - (Required) Map of backend HTTP settings. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `cookie_based_affinity` - (Optional) Cookie-based affinity setting. Default is "Disabled".
  - `name` - The name of the HTTP settings.
  - `port` - The port number for backend communication.
  - `protocol` - The protocol for backend communication (HTTP/HTTPS).
  - `affinity_cookie_name` - (Optional) Name of the affinity cookie.
  - `host_name` - (Optional) Host name for backend requests.
  - `path` - (Optional) Path for backend requests.
  - `pick_host_name_from_backend_address` - (Optional) Whether to pick host name from backend address.
  - `probe_name` - (Optional) Name of the health probe to use.
  - `request_timeout` - (Optional) Request timeout in seconds.
  - `trusted_root_certificate_names` - (Optional) List of trusted root certificate names.
  - `authentication_certificate` - (Optional) List of authentication certificates.
  - `connection_draining` - (Optional) Connection draining configuration.
- `frontend_ports` - (Required) Map of frontend port configurations. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - The name of the frontend port.
  - `port` - The port number.
- `http_listeners` - (Required) Map of HTTP listener configurations. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - The name of the HTTP listener.
  - `frontend_port_name` - The name of the frontend port to use.
  - `frontend_ip_configuration_name` - (Optional) Name of the frontend IP configuration.
  - `firewall_policy_id` - (Optional) Resource ID of the WAF policy.
  - `require_sni` - (Optional) Whether SNI is required.
  - `host_name` - (Optional) Host name for the listener.
  - `host_names` - (Optional) List of host names for the listener.
  - `ssl_certificate_name` - (Optional) Name of the SSL certificate.
  - `ssl_profile_name` - (Optional) Name of the SSL profile.
  - `custom_error_configuration` - (Optional) Custom error page configurations.
- `probe_configurations` - (Optional) Map of health probe configurations. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - The name of the probe.
  - `host` - (Optional) Host name for the probe.
  - `interval` - Probe interval in seconds.
  - `timeout` - Probe timeout in seconds.
  - `unhealthy_threshold` - Number of failed probes before marking unhealthy.
  - `protocol` - Protocol for the probe (HTTP/HTTPS).
  - `port` - (Optional) Port for the probe.
  - `path` - Path for the probe.
  - `pick_host_name_from_backend_http_settings` - (Optional) Whether to use backend HTTP settings host name.
  - `minimum_servers` - (Optional) Minimum number of servers always marked healthy.
  - `match` - (Optional) Response matching criteria.
- `redirect_configuration` - (Optional) Map of redirect configurations. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `include_path` - (Optional) Whether to include path in redirect.
  - `include_query_string` - (Optional) Whether to include query string in redirect.
  - `name` - The name of the redirect configuration.
  - `redirect_type` - The type of redirect.
  - `target_listener_name` - (Optional) Target listener for redirect.
  - `target_url` - (Optional) Target URL for redirect.
- `request_routing_rules` - (Required) Map of request routing rules. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - The name of the routing rule.
  - `rule_type` - The type of rule (Basic/PathBasedRouting).
  - `http_listener_name` - The name of the HTTP listener to use.
  - `backend_address_pool_name` - The name of the backend address pool.
  - `priority` - The priority of the rule.
  - `url_path_map_name` - (Optional) Name of the URL path map for path-based routing.
  - `backend_http_settings_name` - The name of the backend HTTP settings.
  - `redirect_configuration_name` - (Optional) Name of the redirect configuration.
  - `rewrite_rule_set_name` - (Optional) Name of the rewrite rule set.
- `rewrite_rule_set` - (Optional) Map of rewrite rule sets. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - The name of the rewrite rule set.
  - `rewrite_rules` - (Optional) Map of rewrite rules within the set.
- `ssl_certificates` - (Optional) Map of SSL certificates. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - The name of the SSL certificate.
  - `data` - (Optional) Base64 encoded certificate data.
  - `password` - (Optional) Password for the certificate.
  - `key_vault_secret_id` - (Optional) Key Vault secret ID containing the certificate.
- `ssl_policy` - (Optional) SSL policy configuration.
  - `cipher_suites` - (Optional) List of cipher suites to enable.
  - `disabled_protocols` - (Optional) List of protocols to disable.
  - `min_protocol_version` - (Optional) Minimum TLS protocol version. Default is "TLSv1_2".
  - `policy_name` - (Optional) Name of the predefined SSL policy.
  - `policy_type` - (Optional) Type of the SSL policy.
- `ssl_profile` - (Optional) Map of SSL profiles. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - The name of the SSL profile.
  - `trusted_client_certificate_names` - (Optional) List of trusted client certificate names.
  - `verify_client_cert_issuer_dn` - (Optional) Whether to verify client certificate issuer DN.
  - `verify_client_certificate_revocation` - (Optional) Client certificate revocation verification method.
  - `ssl_policy` - (Optional) SSL policy for the profile.
- `trusted_client_certificate` - (Optional) Map of trusted client certificates. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `data` - The base64 encoded certificate data.
  - `name` - The name of the certificate.
- `trusted_root_certificate` - (Optional) Map of trusted root certificates. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `data` - (Optional) Base64 encoded certificate data.
  - `key_vault_secret_id` - (Optional) Key Vault secret ID containing the certificate.
  - `name` - The name of the certificate.
- `url_path_map_configurations` - (Optional) Map of URL path map configurations. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `name` - The name of the URL path map.
  - `default_redirect_configuration_name` - (Optional) Default redirect configuration name.
  - `default_rewrite_rule_set_name` - (Optional) Default rewrite rule set name.
  - `default_backend_http_settings_name` - (Optional) Default backend HTTP settings name.
  - `default_backend_address_pool_name` - (Optional) Default backend address pool name.
  - `path_rules` - Map of path-based routing rules.
- `tags` - (Optional) Map of tags to assign to the Application Gateway.
- `role_assignments` - (Optional) Map of role assignments to create on the Application Gateway. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `role_definition_id_or_name` - The role definition ID or name to assign.
  - `principal_id` - The principal ID to assign the role to.
  - `description` - (Optional) Description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
  - `condition` - (Optional) Condition for the role assignment.
  - `condition_version` - (Optional) Version of the condition.
  - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
  - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
DESCRIPTION
}

variable "bastion_definition" {
  type = object({
    deploy              = optional(bool, true)
    name                = optional(string)
    sku                 = optional(string, "Standard")
    tags                = optional(map(string), {})
    zones               = optional(list(string), ["1", "2", "3"])
    resource_group_name = optional(string)
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure Bastion service to be deployed.

- `deploy` - (Optional) Deploy the bastion service? Default is true.
- `name` - (Optional) The name of the Bastion service. If not provided, a name will be generated.
- `sku` - (Optional) The SKU of the Bastion service. Default is "Standard".
- `tags` - (Optional) Map of tags to assign to the Bastion service.
- `zones` - (Optional) List of availability zones for the Bastion service. Default is ["1", "2", "3"].
- `resource_group_name` - (Optional) The name of the resource group to deploy the Bastion service into. If not provided, the module's resource group will be used.
DESCRIPTION
}

variable "firewall_definition" {
  type = object({
    deploy              = optional(bool, true)
    name                = optional(string)
    sku                 = optional(string, "AZFW_VNet")
    tier                = optional(string, "Standard")
    zones               = optional(list(string), ["1", "2", "3"])
    tags                = optional(map(string), {})
    resource_group_name = optional(string)
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure Firewall to be deployed.

- `deploy` - (Optional) Deploy the Azure Firewall? Default is true.
- `name` - (Optional) The name of the Azure Firewall. If not provided, a name will be generated.
- `sku` - (Optional) The SKU of the Azure Firewall. Default is "AZFW_VNet".
- `tier` - (Optional) The tier of the Azure Firewall. Default is "Standard".
- `zones` - (Optional) List of availability zones for the Azure Firewall. Default is ["1", "2", "3"].
- `tags` - (Optional) Map of tags to assign to the Azure Firewall.
- `resource_group_name` - (Optional) The name of the resource group to deploy the Azure Firewall into. If not provided, the module's resource group will be used.
DESCRIPTION
}

#TODO: Add a variable for the firewall policy definition.
variable "firewall_policy_definition" {
  type = object({
    network_policy_rule_collection_group_name     = optional(string)
    network_policy_rule_collection_group_priority = optional(number, null)
    network_rules = optional(list(object({
      name                  = string
      description           = string
      destination_addresses = list(string)
      destination_ports     = list(string)
      source_addresses      = list(string)
      protocols             = list(string)
    })), null)
    resource_group_name = optional(string)
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Azure Firewall Policy to be deployed.

- `network_policy_rule_collection_group_name` - (Optional) The name of the network policy rule collection group.
- `network_policy_rule_collection_group_priority` - (Optional) The priority of the network policy rule collection group.
- `network_rules` - (Optional) List of network rules for the firewall policy.
  - `name` - The name of the network rule.
  - `description` - Description of the network rule.
  - `destination_addresses` - List of destination addresses for the rule.
  - `destination_ports` - List of destination ports for the rule.
  - `source_addresses` - List of source addresses for the rule.
  - `protocols` - List of protocols for the rule (TCP/UDP/ICMP/Any).
- `resource_group_name` - (Optional) The name of the resource group to deploy the Firewall Policy into. If not provided, the module's resource group will be used.
DESCRIPTION
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
    resource_group_name = optional(string)
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for Network Security Groups (NSGs) to be deployed.

- `name` - (Optional) The name of the Network Security Group. If not provided, a name will be generated.
- `security_rules` - (Optional) Map of security rules for the NSG. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `access` - Whether to allow or deny traffic (Allow/Deny).
  - `description` - (Optional) Description of the security rule.
  - `destination_address_prefix` - (Optional) Destination address prefix (CIDR or service tag).
  - `destination_address_prefixes` - (Optional) Set of destination address prefixes.
  - `destination_application_security_group_ids` - (Optional) Set of destination Application Security Group resource IDs.
  - `destination_port_range` - (Optional) Destination port or port range.
  - `destination_port_ranges` - (Optional) Set of destination ports or port ranges.
  - `direction` - Direction of traffic (Inbound/Outbound).
  - `name` - The name of the security rule.
  - `priority` - Priority of the rule (100-4096).
  - `protocol` - Protocol for the rule (TCP/UDP/ICMP/ESP/AH/*).
  - `source_address_prefix` - (Optional) Source address prefix (CIDR or service tag).
  - `source_address_prefixes` - (Optional) Set of source address prefixes.
  - `source_application_security_group_ids` - (Optional) Set of source Application Security Group resource IDs.
  - `source_port_range` - (Optional) Source port or port range.
  - `source_port_ranges` - (Optional) Set of source ports or port ranges.
  - `timeouts` - (Optional) Timeout configuration for resource operations.
    - `create` - (Optional) Create timeout.
    - `delete` - (Optional) Delete timeout.
    - `read` - (Optional) Read timeout.
    - `update` - (Optional) Update timeout.
  - `resource_group_name` - (Optional) The name of the resource group to deploy the NSG into. If not provided, the module's resource group will be used.
DESCRIPTION
}

variable "private_dns_zones" {
  type = object({
    existing_zones_resource_group_resource_id = optional(string)
    allow_internet_resolution_fallback        = optional(bool, false)
    network_links = optional(map(object({
      vnetlinkname     = string
      vnetid           = string
      resolutionPolicy = optional(string, "Default")
    })), {})
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for Private DNS Zones and their network links.

- `existing_zones_resource_group_resource_id` - (Optional) Resource group resource id where existing Private DNS Zones are located.
- `allow_internet_resolution_fallback` - (Optional) Whether to allow fallback to internet resolution for Private DNS Zone network links. Default is false.
- `network_links` - (Optional) Map of network links to create for Private DNS Zones. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `vnetlinkname` - The name of the virtual network link.
  - `vnetid` - The resource ID of the virtual network to link.
  - `resolutionPolicy` - (Optional) The resolution policy for the virtual network link. Default is "Default".
DESCRIPTION
}

variable "use_internet_routing" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
Use direct internet routing instead of firewall routing for subnets when platform landing zone is enabled.

When set to true and `flag_platform_landing_zone` is true, route tables will use NextHopType = "Internet"
for 0.0.0.0/0 traffic instead of NextHopType = "VirtualAppliance" routing through the Azure Firewall.

This setting is particularly useful for Azure Application Gateway v2 deployments that require direct
internet connectivity and cannot use virtual appliance routing.

**Security Considerations**: Enabling this setting bypasses the Azure Firewall for internet-bound traffic
from associated subnets, which may impact security posture. Ensure proper network security group rules
are in place when using this option.

**Compatibility**: This setting only applies when `flag_platform_landing_zone = true`. When
`flag_platform_landing_zone = false`, no route tables are created regardless of this setting.
DESCRIPTION
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
        })), null)
      }))
      }), {
      managed_rule_set = {
        owasp = {
          version = "3.2"
          type    = "OWASP"
        }
      }
    })

    tags = optional(map(string), {})
  })
  default     = {}
  description = <<DESCRIPTION
Configuration object for the Web Application Firewall (WAF) Policy to be deployed.

- `name` - (Optional) The name of the WAF Policy. If not provided, a name will be generated.
- `policy_settings` - (Optional) Policy settings configuration.
  - `enabled` - (Optional) Whether the WAF policy is enabled. Default is true.
  - `mode` - (Optional) The mode of the WAF policy (Detection/Prevention). Default is "Prevention".
  - `request_body_check` - (Optional) Whether request body inspection is enabled. Default is true.
  - `max_request_body_size_kb` - (Optional) Maximum request body size in KB. Default is 128.
  - `file_upload_limit_mb` - (Optional) File upload limit in MB. Default is 100.
- `managed_rules` - (Optional) Managed rules configuration.
  - `exclusion` - (Optional) Map of rule exclusions. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
    - `match_variable` - The variable to match for exclusion.
    - `selector` - The selector for the match variable.
    - `selector_match_operator` - The operator for matching the selector.
    - `excluded_rule_set` - (Optional) Specific rule set exclusions.
      - `type` - (Optional) The type of rule set.
      - `version` - (Optional) The version of rule set.
      - `rule_group` - (Optional) List of rule groups to exclude.
  - `managed_rule_set` - Map of managed rule sets to apply. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
    - `type` - (Optional) The type of managed rule set.
    - `version` - The version of the managed rule set.
    - `rule_group_override` - (Optional) Map of rule group overrides.
      - `rule_group_name` - The name of the rule group to override.
      - `rule` - (Optional) List of specific rules to override.
        - `action` - (Optional) The action to take for the rule.
        - `enabled` - (Optional) Whether the rule is enabled.
        - `id` - The ID of the rule.
- `tags` - (Optional) Map of tags to assign to the WAF Policy.
DESCRIPTION
}
