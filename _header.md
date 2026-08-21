# terraform-azurerm-avm-ptn-aiml-landing-zone

This pattern module creates the full AI landing zone for foundry. For more details on AI Landing Zones please see the [AI Landing Zone documentation](https://aka.ms/ailz/website) including the deployment guide for terraform deployments: [AI Landing Zone Terraform Deployment Guide](https://azure.github.io/AI-Landing-Zones/terraform/).

## Getting started

Start from one of the deployable examples in this repository:

- [default](./examples/default) - Platform landing zone deployment.
- [default-byo-vnet](./examples/default-byo-vnet) - Platform landing zone with an existing VNet.
- [standalone](./examples/standalone) - Standalone deployment without platform landing zone dependencies.
- [standalone-byo-vnet](./examples/standalone-byo-vnet) - Standalone deployment with an existing VNet.

Copy the example that best matches your environment, then replace `source = "../../"` with the registry source when deploying from your own configuration.

## Policy-restricted environments

If your tenant policies enforce restrictions (for example, storage account key access controls), use the same `azurerm` provider settings as the examples:

```hcl
provider "azurerm" {
  storage_use_azuread = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}
```

These settings are used across the examples to help deployments succeed in policy-restricted environments.

## Identity and RBAC automation

The module preserves the existing Key Vault Administrator grant for the deployment principal and now creates that assignment through the Key Vault module's `role_assignments` interface. By default, the current AzureRM client object ID remains the deployment principal.

Use `security_definition` to opt into additional data-plane roles for the deployment principal or for existing workload managed identities:

```hcl
security_definition = {
  grant_deployment_principal_app_configuration_data_owner = true

  workload_managed_identities = {
    api = {
      principal_id                  = var.api_managed_identity_principal_id
      app_configuration_data_reader = true
      container_registry_pull       = true
      key_vault_secrets_user        = true
    }
  }
}
```

The workload map accepts managed identity principal IDs only; identity creation and attachment to individual workloads remain the caller's responsibility. `key_vault_secrets_user` grants access to existing secrets but does not create, read, or output secret values. Consumer-supplied `role_assignments` maps are merged after generated assignments and remain available for additional resource-specific RBAC.

AI Foundry project and cross-service role assignments remain owned by the nested AI Foundry pattern module when project connections are enabled. This root automation does not duplicate those assignments. Cosmos DB SQL data-plane RBAC and per-container-app identity creation are not automated by this interface.

### Upgrade behavior

The deployment-principal Key Vault assignment moved from the root module into the Key Vault module. A declarative `moved` block preserves the existing Terraform state address, so no manual state command is expected for the default upgrade path. Defaults, including the broad Key Vault Administrator grant and Foundry authentication settings, are unchanged.
