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

## Data and AI services proposal

This branch contains a human-reviewable, additive proposal for the authorized Data & AI Services parity handoff. It does not claim parity and must not be treated as deployment, release, or publication approval.

### Provenance

- Source implementation: [`Azure/bicep-ptn-aiml-landing-zone@66a0d76f034b8c1003fd63bcdcf58e3255f3d030`](https://github.com/Azure/bicep-ptn-aiml-landing-zone/tree/66a0d76f034b8c1003fd63bcdcf58e3255f3d030).
- Source contracts: `parity/handoffs/data-and-ai-services/data-and-ai-services-baseline.json` and `parity/inventory.json` at the same commit.
- Terraform baseline: v0.5.1 commit `abe337894f93de3ddda525ea44898b33e1484070`.
- Authorization: [Azure/bicep-ptn-aiml-landing-zone#147 comment 5375280499](https://github.com/Azure/bicep-ptn-aiml-landing-zone/pull/147#issuecomment-5375280499).
- Expected release impact if accepted: pre-1.0 minor version (for example, `0.6.0`); this proposal does not perform a release.

The baseline Terraform files for these capability groups are unchanged between v0.5.1 and the upstream main used for this proposal.

### Additive service contract

- Standalone GenAI Cosmos DB now composes a `cosmosdb` SQL database with a `conversations` container, `/principal_id` partition key, infinite default TTL, and the two source composite indexes.
- Standalone GenAI Storage now composes a private `documents` blob container. Its existing defaults remain GRS replication with shared access keys enabled.
- Foundry BYOR Storage remains distinct: ZRS replication with shared access keys disabled by default.
- Application Insights can be created or referenced by resource ID. Existing-component reuse requires an explicitly reused Log Analytics workspace unless `allow_mixed_workspaces` records an intentional exception.
- Azure AI Speech is opt-in and defaults to `S0`, system-assigned managed identity, disabled local authentication, disabled public network access, a private endpoint using `privatelink.cognitiveservices.azure.com`, and deployment-principal `Cognitive Services Contributor` plus `Cognitive Services User` roles.
- Root outputs contain only non-secret IDs, names, endpoints, regions, managed identity principal IDs, and data-container names. Connection strings, instrumentation keys, and access keys are never exposed.

### Scenario status

| Scenario | Data services | Observability | Search, Bing, Speech |
| --- | --- | --- | --- |
| `standalone-network-isolated` | Implemented statically through existing private endpoint, DNS, and peering ordering. | Partial: Log Analytics and Application Insights create/reuse are implemented; AMPLS remains deferred. | Search/Bing are preserved and opt-in Speech uses the existing Cognitive Services private DNS zone and private endpoint subnet. |
| `standalone-standard` | Blocked by the root module's mandatory VNet/private-endpoint architecture. | Blocked by the same architecture. | Blocked by the same architecture. |
| `hub-spoke` | Excluded by the authorized handoff. | Excluded by the authorized handoff. | Excluded by the authorized handoff. |

### Exact deferrals and dependencies

- AMPLS, its `azuremonitor` private endpoint, scoped-resource links, and the Azure Monitor/OMS/ODS/Automation private DNS zone set are deferred as one coherent networking change. Application Insights keeps internet ingestion/query enabled by default until that dependency is implemented.
- Secure runtime propagation of an existing Application Insights connection string is deferred. The module intentionally accepts and outputs only the component resource ID.
- Cosmos DB SQL data-plane role assignments are deferred pending an AzAPI/AVM implementation decision; ARM role assignments are not a substitute.
- Default Search, Storage, Key Vault, and workload-identity data-plane role changes are deferred because silently changing existing defaults would violate the migration-free handoff. Speech executor roles are safe because Speech is a new opt-in resource.
- Bing-to-Foundry connection wiring remains dependent on the separately scoped Foundry connection capability groups.
- Approved Azure deployment evidence, DNS resolution, endpoint reachability, RBAC behavior, and isolation comparison remain required before any parity claim.
