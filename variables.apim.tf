variable "apim_definition" {
  type = object({
    deploy          = optional(bool, true)
    name            = optional(string)
    publisher_email = string
    publisher_name  = string
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
    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
    }))
    min_api_version           = optional(string)
    notification_sender_email = optional(string, null)
    protocols = optional(object({
      enable_http2 = optional(bool, false)
    }))
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
    sku_capacity = optional(number, 3)
    tags         = optional(map(string), {})
    tenant_access = optional(object({
      enabled = bool
    }), null)
  })
  default = {
    publisher_email = "DoNotReply@exampleEmail.com"
    publisher_name  = "Azure API Management"
  }
  description = <<DESCRIPTION
Configuration object for the Azure API Management service to be deployed.

- `deploy` - (Optional) Whether to deploy the API Management service. Default is true.
- `name` - (Optional) The name of the API Management service. If not provided, a name will be generated.
- `publisher_email` - (Required) The email address of the publisher of the API Management service.
- `publisher_name` - (Required) The name of the publisher of the API Management service.
- `additional_locations` - (Optional) List of additional locations where the API Management service will be deployed.
  - `location` - The Azure region for the additional location.
  - `capacity` - (Optional) The number of units for the additional location.
  - `zones` - (Optional) List of availability zones for the additional location.
  - `public_ip_address_id` - (Optional) Resource ID of the public IP address for the additional location.
  - `gateway_disabled` - (Optional) Whether the gateway is disabled in the additional location.
  - `virtual_network_configuration` - (Optional) Virtual network configuration for the additional location.
    - `subnet_id` - The resource ID of the subnet for virtual network integration.
- `certificate` - (Optional) List of certificates to be uploaded to the API Management service.
  - `encoded_certificate` - The base64 encoded certificate data.
  - `store_name` - The certificate store name (e.g., "CertificateAuthority", "Root").
  - `certificate_password` - (Optional) The password for the certificate.
- `client_certificate_enabled` - (Optional) Whether client certificate authentication is enabled. Default is false.
- `hostname_configuration` - (Optional) Hostname configuration for different endpoints.
  - `management` - (Optional) List of custom hostnames for the management endpoint.
  - `portal` - (Optional) List of custom hostnames for the developer portal endpoint.
  - `developer_portal` - (Optional) List of custom hostnames for the new developer portal endpoint.
  - `proxy` - (Optional) List of custom hostnames for the proxy endpoint.
  - `scm` - (Optional) List of custom hostnames for the SCM endpoint.
    Each hostname configuration includes:
    - `host_name` - The custom hostname.
    - `key_vault_id` - (Optional) Resource ID of the Key Vault containing the certificate.
    - `certificate` - (Optional) Base64 encoded certificate data.
    - `certificate_password` - (Optional) Password for the certificate.
    - `negotiate_client_certificate` - (Optional) Whether to negotiate client certificates.
    - `ssl_keyvault_identity_client_id` - (Optional) Client ID of the user-assigned managed identity for Key Vault access.
    - `default_ssl_binding` - (Optional, proxy only) Whether this is the default SSL binding.
- `managed_identities` - (Optional) Managed identities configuration.
  - `system_assigned` - (Optional) Whether to enable system-assigned managed identity. Default is false.
  - `user_assigned_resource_ids` - (Optional) Set of user-assigned managed identity resource IDs.
- `min_api_version` - (Optional) The minimum API version that the API Management service will accept.
- `notification_sender_email` - (Optional) Email address from which notifications will be sent.
- `protocols` - (Optional) Protocol configuration.
  - `enable_http2` - (Optional) Whether HTTP/2 protocol is enabled. Default is false.
- `role_assignments` - (Optional) Map of role assignments to create on the API Management service. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
  - `role_definition_id_or_name` - The role definition ID or name to assign.
  - `principal_id` - The principal ID to assign the role to.
  - `description` - (Optional) Description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Whether to skip AAD check for service principal.
  - `condition` - (Optional) Condition for the role assignment.
  - `condition_version` - (Optional) Version of the condition.
  - `delegated_managed_identity_resource_id` - (Optional) Resource ID of the delegated managed identity.
  - `principal_type` - (Optional) Type of the principal (User, Group, ServicePrincipal).
- `sign_in` - (Optional) Sign-in configuration for the developer portal.
  - `enabled` - Whether sign-in is enabled.
- `sign_up` - (Optional) Sign-up configuration for the developer portal.
  - `enabled` - Whether sign-up is enabled.
  - `terms_of_service` - Terms of service configuration.
    - `consent_required` - Whether consent to terms of service is required.
    - `enabled` - Whether terms of service are enabled.
    - `text` - (Optional) The terms of service text.
- `sku_root` - (Optional) The SKU of the API Management service. Default is "Premium".
- `sku_capacity` - (Optional) The capacity/scale units of the API Management service. Default is 3.
- `tags` - (Optional) Map of tags to assign to the API Management service.
- `tenant_access` - (Optional) Tenant access configuration.
  - `enabled` - Whether tenant access is enabled.
DESCRIPTION
}
