mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
      tenant_id       = "00000000-0000-0000-0000-000000000004"
    }
  }
}

# Terraform cannot mock provider types that expose ephemeral resources yet.
# The targeted plan does not call Azure through AzAPI.
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

override_module {
  target = module.foundry_ptn
  outputs = {
    ai_foundry_name = "mock-foundry"
  }
}

override_module {
  target  = module.container_apps_managed_environment
  outputs = {}
}

run "default_security_preserves_key_vault_administrator" {
  command = plan

  plan_options {
    target = [
      module.app_configuration,
      module.avm_res_keyvault_vault,
      module.containerregistry,
    ]
  }

  variables {
    location            = "eastus"
    resource_group_name = "rg-security-default"
    vnet_definition     = {}
  }

  assert {
    condition     = length(local.genai_key_vault_role_assignments) == 1
    error_message = "The default security configuration must create only the preserved deployment-principal Key Vault assignment."
  }

  assert {
    condition     = local.genai_key_vault_role_assignments["deployment_user_kv_admin"].role_definition_id_or_name == "Key Vault Administrator"
    error_message = "The default deployment-principal role must remain Key Vault Administrator."
  }

  assert {
    condition     = local.genai_key_vault_role_assignments["deployment_user_kv_admin"].principal_id == "00000000-0000-0000-0000-000000000002"
    error_message = "The default Key Vault assignment must use the current deployment principal."
  }

  assert {
    condition     = length(local.genai_app_configuration_role_assignments) == 0 && length(local.genai_container_registry_role_assignments) == 0
    error_message = "New App Configuration and Container Registry grants must remain opt-in."
  }
}

run "managed_identity_roles_are_opt_in_and_consumer_maps_are_preserved" {
  command = plan

  plan_options {
    target = [
      module.app_configuration,
      module.avm_res_keyvault_vault,
      module.containerregistry,
    ]
  }

  variables {
    location            = "eastus"
    resource_group_name = "rg-security-opt-in"
    vnet_definition     = {}
    security_definition = {
      deployment_principal_id                                 = "10000000-0000-0000-0000-000000000001"
      deployment_principal_type                               = "ServicePrincipal"
      grant_deployment_principal_app_configuration_data_owner = true
      workload_managed_identities = {
        api = {
          principal_id                  = "20000000-0000-0000-0000-000000000001"
          app_configuration_data_reader = true
          container_registry_pull       = true
          key_vault_secrets_user        = true
        }
      }

    }
    genai_app_configuration_definition = {
      deploy = false
      role_assignments = {
        consumer = {
          role_definition_id_or_name = "Reader"
          principal_id               = "30000000-0000-0000-0000-000000000001"
        }
      }
    }
    genai_container_registry_definition = {
      deploy = false
      role_assignments = {
        consumer = {
          role_definition_id_or_name = "Reader"
          principal_id               = "30000000-0000-0000-0000-000000000002"
        }
      }
    }
    genai_key_vault_definition = {
      deploy = false
      role_assignments = {
        consumer = {
          role_definition_id_or_name = "Reader"
          principal_id               = "30000000-0000-0000-0000-000000000003"
        }
      }
    }
  }

  assert {
    condition     = local.genai_app_configuration_role_assignments["security_deployment_principal_data_owner"].role_definition_id_or_name == "App Configuration Data Owner"
    error_message = "The explicit deployment principal must receive App Configuration Data Owner."
  }

  assert {
    condition     = local.genai_app_configuration_role_assignments["security_workload_api_data_reader"].role_definition_id_or_name == "App Configuration Data Reader"
    error_message = "The managed identity must receive the opted-in App Configuration Data Reader role."
  }

  assert {
    condition     = local.genai_container_registry_role_assignments["security_workload_api_acr_pull"].role_definition_id_or_name == "AcrPull"
    error_message = "The managed identity must receive the opted-in AcrPull role."
  }

  assert {
    condition     = local.genai_key_vault_role_assignments["security_workload_api_secrets_user"].role_definition_id_or_name == "Key Vault Secrets User"
    error_message = "The managed identity must receive the opted-in Key Vault Secrets User role."
  }

  assert {
    condition = (
      contains(keys(local.genai_app_configuration_role_assignments), "consumer") &&
      contains(keys(local.genai_container_registry_role_assignments), "consumer") &&
      contains(keys(local.genai_key_vault_role_assignments), "consumer")
    )
    error_message = "Consumer-supplied role assignment maps must be retained alongside generated assignments."
  }

  assert {
    condition     = local.genai_key_vault_role_assignments["deployment_user_kv_admin"].principal_id == "10000000-0000-0000-0000-000000000001"
    error_message = "An explicit deployment principal must replace the current-client default for the preserved Key Vault grant."
  }
}

run "managed_identity_without_a_role_is_rejected" {
  command = plan

  plan_options {
    target = [
      module.app_configuration,
      module.avm_res_keyvault_vault,
      module.containerregistry,
    ]
  }

  variables {
    location            = "eastus"
    resource_group_name = "rg-security-invalid"
    vnet_definition     = {}
    security_definition = {
      workload_managed_identities = {
        api = {
          principal_id = "40000000-0000-0000-0000-000000000001"
        }
      }
    }
  }

  expect_failures = [var.security_definition]
}
