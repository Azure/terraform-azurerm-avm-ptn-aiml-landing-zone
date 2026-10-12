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

## Microsoft Foundry contracts

The module exposes account, project, model deployment, and Bring Your Own Resource IDs through `ai_foundry_account`, `ai_foundry_projects`, `ai_foundry_model_deployment_ids`, and `ai_foundry_byor_resource_ids`. Existing `ai_foundry_definition` defaults remain unchanged: local authentication is not disabled by default and AI Agent Service creation remains opt-in.

`hosted_agent_definition` adds an opt-in infrastructure handoff for downstream `azure.ai.agent` deployment. The module validates immutable image digests, selects a configured Foundry project, grants the deployment principal Azure AI Project Manager at the project scope, and grants the project managed identity registry pull access. Module-managed registries and existing registries in `rbac` mode use AcrPull; existing registries in `rbac-abac` mode use Container Registry Repository Reader. Registry IDs, endpoints, and downstream agent strings are trimmed before they are used or returned.

This handoff currently supports only the standalone network-isolated topology. Public standalone Foundry, hub-spoke, Bing connections, automatic Cosmos DB data-plane role assignments, and ACR Task agent-pool deployment are not implemented. Consumers remain responsible for private endpoint, DNS, and VNet-internal build connectivity when supplying an existing registry. The landing zone does not create the downstream data-plane agent identity or agent version.

For an existing registry, provide its ARM resource ID and login hostname. Set `role_assignment_mode = "rbac-abac"` only when the registry uses RBAC Registry + ABAC Repository Permissions; otherwise retain the `rbac` default.
