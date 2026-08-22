# terraform-azurerm-avm-ptn-aiml-landing-zone

This pattern module creates the full AI landing zone for foundry. For more details on AI Landing Zones please see the [AI Landing Zone documentation](https://aka.ms/ailz/website) including the deployment guide for terraform deployments: [AI Landing Zone Terraform Deployment Guide](https://azure.github.io/AI-Landing-Zones/terraform/).

## Getting started

Start from one of the deployable examples in this repository:

- [default](./examples/default) - Platform landing zone deployment.
- [default-byo-vnet](./examples/default-byo-vnet) - Platform landing zone with an existing VNet.
- [standalone](./examples/standalone) - Standalone deployment without platform landing zone dependencies.
- [standalone-byo-vnet](./examples/standalone-byo-vnet) - Standalone deployment with an existing VNet.

Copy the example that best matches your environment, then replace `source = "../../"` with the registry source when deploying from your own configuration.

## Networking controls

Standalone deployments (`flag_platform_landing_zone = false`) can create or reuse a NAT Gateway and select the workload subnets that receive it. They can also reuse an existing route table, supply an external firewall next hop, add custom routes, enable Bastion native-client tunneling, restrict Application Gateway ingress source prefixes, and supply individual existing Private DNS zone IDs.

Platform landing zone behavior remains unchanged: the module does not create or associate the standalone NAT Gateway or route table when `flag_platform_landing_zone = true`. Reverse hub peering remains configurable through `vnet_definition.vnet_peering_configuration`; set `create_reverse_peering = false` when the hub-to-spoke peering is platform-owned.

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
