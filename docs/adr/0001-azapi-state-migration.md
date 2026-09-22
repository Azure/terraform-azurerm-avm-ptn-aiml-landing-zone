# ADR 0001: Preserve state while migrating direct resources to AzAPI

- Status: Accepted
- Date: 2026-08-25

## Context

The module directly managed several Azure control-plane resources with AzureRM. Current AVM guidance requires AzAPI for supported direct control-plane operations, but an in-place provider migration must not recreate existing infrastructure.

AzAPI 2.12 implements generic `MoveResourceState` conversion from AzureRM resources to `azapi_resource`. Earlier AzAPI 2.8-2.10 releases had identity migration regressions; the fixes are available in 2.11 and 2.12. AzureRM does not support the reverse conversion.

The existing Key Vault deployment-principal role assignment did not set an explicit name, so AzureRM generated a GUID that varies between deployments. Replacing it with a newly calculated GUID during upgrade would recreate the assignment.

`data.azapi_client_config` also has an unresolved provider-authentication issue that can return the Azure CLI identity instead of the identity configured on a service principal, managed identity, or aliased provider.

## Decision

1. Require AzAPI `~> 2.12`.
2. Migrate each direct control-plane resource in place and retain its current module/cardinality boundary.
3. Declare explicit `moved` blocks from each AzureRM address to its AzAPI address.
4. Retain the moved blocks for at least the next major compatibility window.
5. Preserve the historical Key Vault role-assignment GUID through provider state conversion and ignore changes to the AzAPI `name` attribute. Use a deterministic UUID only for new deployments.
6. Keep `data.azurerm_client_config.current` as the only direct AzureRM data source, with block-specific lint exclusions and documentation linking [Azure/terraform-provider-azapi#981](https://github.com/Azure/terraform-provider-azapi/issues/981). Remove the exception when that issue is fixed.
7. Require consumers to back up state and verify that the upgrade plan contains no unintended destroy or replacement actions.

## Consequences

- Existing Azure resource IDs and state ownership are retained without imperative state commands.
- Provider migration is declarative and applies to collection instances without enumerating consumer keys.
- Downgrading after state conversion is unsupported because AzureRM cannot reverse the provider state move.
- The module retains an AzureRM provider dependency solely for reliable configured-identity discovery until AzAPI issue #981 is resolved.
- A live upgrade test requires an Azure subscription: deploy v0.5.1, switch to v0.6.0, require a no-destroy/no-replace plan, apply, require a no-change second plan, and destroy through v0.6.0.
