locals {
  security_deployment_principal_id = coalesce(
    var.security_definition.deployment_principal_id,
    data.azurerm_client_config.current.object_id
  )
  security_genai_app_configuration_role_assignments = merge(
    var.security_definition.grant_deployment_principal_app_configuration_data_owner ? {
      security_deployment_principal_data_owner = {
        role_definition_id_or_name = "App Configuration Data Owner"
        principal_id               = local.security_deployment_principal_id
        principal_type             = var.security_definition.deployment_principal_type
      }
    } : {},
    {
      for key, identity in var.security_definition.workload_managed_identities :
      "security_workload_${key}_data_reader" => {
        role_definition_id_or_name = "App Configuration Data Reader"
        principal_id               = identity.principal_id
        principal_type             = "ServicePrincipal"
      }
      if identity.app_configuration_data_reader
    }
  )
  security_genai_container_registry_role_assignments = {
    for key, identity in var.security_definition.workload_managed_identities :
    "security_workload_${key}_acr_pull" => {
      role_definition_id_or_name = "AcrPull"
      principal_id               = identity.principal_id
      principal_type             = "ServicePrincipal"
    }
    if identity.container_registry_pull
  }
  security_genai_key_vault_role_assignments = merge(
    {
      deployment_user_kv_admin = {
        role_definition_id_or_name = "Key Vault Administrator"
        principal_id               = local.security_deployment_principal_id
        principal_type             = var.security_definition.deployment_principal_type
      }
    },
    {
      for key, identity in var.security_definition.workload_managed_identities :
      "security_workload_${key}_secrets_user" => {
        role_definition_id_or_name = "Key Vault Secrets User"
        principal_id               = identity.principal_id
        principal_type             = "ServicePrincipal"
      }
      if identity.key_vault_secrets_user
    }
  )
}
