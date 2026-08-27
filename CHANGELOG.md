# Changelog

## 0.6.0

### Changed

- Migrated direct control-plane resources from AzureRM to AzAPI 2.12.
- Added declarative cross-provider state moves for the resource group, network security rules, virtual hub connection, Key Vault deployment-principal role assignment, local example hub resources, and BYO-VNet example resource groups.
- Added configurable AzAPI resource types, retries, timeouts, response exports, and ignored body paths.
- Retained `azurerm_client_config` as a documented provider-authentication exception until [Azure/terraform-provider-azapi#981](https://github.com/Azure/terraform-provider-azapi/issues/981) is fixed.

### Upgrade notes

- Back up Terraform state before upgrading from v0.5.1.
- Run `terraform init -upgrade`, then inspect `terraform plan` for the expected provider/address moves and no resource destruction or replacement.
- The historical Key Vault role-assignment GUID is retained through provider state migration. New deployments use a deterministic GUID.
- Read [the v0.6.0 migration guide](./docs/migrations/v0.6.0.md) for the complete procedure and rollback limitation.
