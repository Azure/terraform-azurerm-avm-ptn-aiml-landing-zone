variable "apim_definition" {
  type = object({
    name                = optional(string)
    location            = string
    resource_group_name = string
    publisher_email     = string
    additional_locations = optional(list(object({
      location             = string
      capacity             = optional(number, null)
      zones                = optional(list(string), null)
      public_ip_address_id = optional(string, null)
      gateway_disabled     = optional(bool, null)
      virtual_network_configuration = optional(object({
        subnet_id = string
      }), null)
    })), [])
    certificate = optional(list(object({
      encoded_certificate  = string
      store_name           = string
      certificate_password = optional(string, null)
    })), [])
    client_certificate_enabled = optional(bool, false)
    hostname_configuration = optional(object({
      management = optional(list(object({
        host_name                       = string
        key_vault_id                    = optional(string, null)
        certificate                     = optional(string, null)
        certificate_password            = optional(string, null)
        negotiate_client_certificate    = optional(bool, false)
        ssl_keyvault_identity_client_id = optional(string, null)
      })), [])
      portal = optional(list(object({
        host_name                       = string
        key_vault_id                    = optional(string, null)
        certificate                     = optional(string, null)
        certificate_password            = optional(string, null)
        negotiate_client_certificate    = optional(bool, false)
        ssl_keyvault_identity_client_id = optional(string, null)
      })), [])
      developer_portal = optional(list(object({
        host_name                       = string
        key_vault_id                    = optional(string, null)
        certificate                     = optional(string, null)
        certificate_password            = optional(string, null)
        negotiate_client_certificate    = optional(bool, false)
        ssl_keyvault_identity_client_id = optional(string, null)
      })), [])
      proxy = optional(list(object({
        host_name                       = string
        default_ssl_binding             = optional(bool, false)
        key_vault_id                    = optional(string, null)
        certificate                     = optional(string, null)
        certificate_password            = optional(string, null)
        negotiate_client_certificate    = optional(bool, false)
        ssl_keyvault_identity_client_id = optional(string, null)
      })), [])
      scm = optional(list(object({
        host_name                       = string
        key_vault_id                    = optional(string, null)
        certificate                     = optional(string, null)
        certificate_password            = optional(string, null)
        negotiate_client_certificate    = optional(bool, false)
        ssl_keyvault_identity_client_id = optional(string, null)
      })), [])
    }), null)
    min_api_version           = optional(string)
    notification_sender_email = optional(string, null)
    protocols = optional(object({
      enable_http2 = optional(bool, false)
    }))
    publisher_name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string
    })), {})
    sign_in = optional(object({
      enabled = bool
    }), null)
    sign_up = optional(object({
      enabled = bool
      terms_of_service = object({
        consent_required = bool
        enabled          = bool
        text             = optional(string, null)
      })
    }), null)
    sku_root     = optional(string, "Premium")
    sku_capacity = optional(number, 1)
    tenant_access = optional(object({
      enabled = bool
    }), null)
  })
  default     = {}
  description = "Definition of the API Management service."
}
