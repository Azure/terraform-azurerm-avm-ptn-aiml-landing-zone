# terraform-azurerm-avm-ptn-aiml-landing-zone

This pattern module creates the full AI landing zone for foundry. For more details on AI Landing Zones please see the [AI Landing Zone documentation](https://aka.ms/ailz/website) including the deployment guide for terraform deployments: [AI Landing Zone Terraform Deployment Guide](https://azure.github.io/AI-Landing-Zones/terraform/).

## Getting started

Start from one of the deployable examples in this repository:

- [default](./examples/default) - Platform landing zone deployment.
- [default-byo-vnet](./examples/default-byo-vnet) - Platform landing zone with an existing VNet.
- [standalone](./examples/standalone) - Standalone deployment without platform landing zone dependencies.
- [standalone-byo-vnet](./examples/standalone-byo-vnet) - Standalone deployment with an existing VNet.

Copy the example that best matches your environment, then replace `source = "../../"` with the registry source when deploying from your own configuration.

## Provider authentication

The module uses AzAPI for its direct Azure control-plane operations. It retains one narrowly scoped `azurerm_client_config` data source so the deployment-principal object ID, tenant ID, and subscription ID come from the configured AzureRM provider identity. AzAPI [issue #981](https://github.com/Azure/terraform-provider-azapi/issues/981) can otherwise return the Azure CLI identity instead of the configured service principal, managed identity, or provider alias.

Configure both providers with the same authentication context:

```hcl
provider "azurerm" {
  features {}
}
```

No direct AzureRM resource is created by this module. The client-config exception will be removed after issue #981 is fixed.

## Upgrading from v0.5.1

Version 0.6.0 migrates direct AzureRM control-plane resources to AzAPI. Declarative `moved` blocks preserve the existing resource group, network security rules, virtual hub connection, Key Vault deployment-principal role assignment, and example networking resources.

Read the [v0.6.0 migration guide](./docs/migrations/v0.6.0.md) before upgrading. Back up state and review the upgrade plan before applying because AzAPI provider state migration is one-way.
