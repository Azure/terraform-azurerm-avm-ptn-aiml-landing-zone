# terraform-azurerm-avm-ptn-aiml-landing-zone

This pattern module creates the full AI landing zone for foundry. For more details on AI Landing Zones please see the [AI Landing Zone documentation](https://aka.ms/ailz/website) including the deployment guide for terraform deployments: [AI Landing Zone Terraform Deployment Guide](https://azure.github.io/AI-Landing-Zones/terraform/).

## Getting started

Start from one of the deployable examples in this repository:

- [default](./examples/default) - Platform landing zone deployment.
- [default-byo-vnet](./examples/default-byo-vnet) - Platform landing zone with an existing VNet.
- [standalone](./examples/standalone) - Standalone deployment without platform landing zone dependencies.
- [standalone-byo-vnet](./examples/standalone-byo-vnet) - Standalone deployment with an existing VNet.

Copy the example that best matches your environment, then replace `source = "../../"` with the registry source when deploying from your own configuration.

## Application Gateway WAF policies

By default, deploying Application Gateway creates and attaches an internal Web Application Firewall (WAF) policy. Use `waf_policy_definition.custom_rules` to add custom rules alongside its managed rules. The [standalone example](./examples/standalone) blocks requests from the documentation-only address `192.0.2.1/32` using `RemoteAddr`, `IPMatch`, and `Block`.

To use a policy managed outside this pattern module, set `waf_policy_definition.existing_policy.resource_id` to its ARM resource ID. This attaches the supplied policy at gateway scope and skips internal policy creation. The `existing_policy` object selects this behavior even when another resource computes its ID during deployment. The [default example](./examples/default) demonstrates this with a separate WAF policy module.

The caller owns the external policy's rules and lifecycle. Internal policy settings, managed rules, name, and tags do not modify it. Do not combine `custom_rules` with `existing_policy`; configure those rules on the external policy instead. Listener and path-specific policies remain supported and override the gateway policy rather than combining their rules with it.

Switching an existing deployment to an external policy removes the internal policy from Terraform's desired resources. Review the plan and copy any required protections into the external policy before switching. Existing callers who omit both new options retain the current behavior.

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
