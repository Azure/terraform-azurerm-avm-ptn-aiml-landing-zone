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

## Application Platform handoff

The optional `application_platform` input adds managed-identity Container App workloads, runtime configuration modes, non-secret App Configuration population, a private ACR Task agent pool, and Foundry IQ runtime handoff values without changing the existing landing-zone topology or defaults. Existing consumers do not need to migrate.

The default runtime mode remains `appConfig`, while `populate_app_configuration` defaults to `false`. The module's existing topology is network isolated, so consumers normally populate the exported `application_platform_runtime_configuration` map from a post-provision runner with private connectivity. No secret values are accepted by this interface.

`containerEnv` injects non-secret bootstrap configuration directly into each workload. `none` injects only the workload identity client ID. Every workload gets a user-assigned managed identity; private-registry and optional Key Vault permissions are assigned before the Container App resource is created.

The `application_platform` output preserves the authorized handoff names inside one Terraform object. It records configured intent and resource handoffs only; it is not evidence of effective network isolation or cross-language scenario parity. Full CAF/legacy renaming of existing resources and Foundry IQ data-plane knowledge-base/source creation remain outside this additive change because either would require a separately reviewed migration or data-plane implementation.
