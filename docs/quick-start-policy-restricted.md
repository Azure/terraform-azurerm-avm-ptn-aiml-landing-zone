# Quick Start Guide for Policy-Restricted Environments

Get your AI/ML Landing Zone deployed in policy-restricted environments. This guide is specifically designed for organizations with strict Azure policies requiring disabled local authentication, zone-redundant storage, and enhanced security configurations.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Policy Requirements Overview](#policy-requirements-overview)
- [Quick Deployment Steps](#quick-deployment-steps)
- [Policy-Compliant Configuration](#policy-compliant-configuration)
- [Deployment and Verification](#deployment-and-verification)
- [Common Policy Issues and Solutions](#common-policy-issues-and-solutions)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

## Prerequisites

Before you begin, ensure you have:

- **Azure Subscription** with appropriate permissions
- **Terraform** >= 1.9 installed
- **Azure CLI** logged in to your subscription
- **Owner** role on the target subscription/resource group
- Understanding of your organization's specific Azure policies

### Required Terraform Providers

The module automatically handles these provider versions:
- `azurerm` ~> 4.0
- `azapi` ~> 2.4
- `random` ~> 3.5
- `http` ~> 3.4

## Policy Requirements Overview

This guide addresses the following common enterprise Azure policies:

- ✅ **Local Authentication Disabled**: AI Foundry, AI Search, Cosmos DB, Storage Account
- ✅ **Storage Account Security**: Shared access keys disabled, zone-redundant replication
- ✅ **Key-based Authentication**: Disabled for Search, OpenAI, and AI Foundry
- ✅ **Resource Group Restrictions**: Handle deletion policies
- ✅ **Cognitive Services**: Proper soft-delete handling
- ✅ **Network Security**: Secure configurations for Key Vault and other services

## Quick Deployment Steps

### 1. Clone and Navigate to Workspace

```bash
git clone https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone.git
cd terraform-azurerm-avm-ptn-aiml-landing-zone
```

### 2. Create Policy-Compliant Configuration

Create a new directory for your policy-compliant deployment:

```bash
mkdir examples/policy-compliant
cd examples/policy-compliant
```

### 3. Create the Policy-Compliant Terraform Configuration

Create `main.tf` with the following policy-compliant configuration:

```hcl
terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
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

## Section to provide a random Azure region for the resource group
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.3.0"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# Get the deployer IP address for Key Vault access during deployment
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

locals {
  # Update with your organization's required tags
  common_tags = {
    Environment = "policy-compliant"
    CostProfile = "enterprise"
    Project     = "AI-ML-LandingZone"
    Owner       = "your-email@company.com"
    # Add additional required tags here:
    # Department  = "IT"
    # CostCenter  = "12345"
  }
}

# POLICY-COMPLIANT AI/ML LANDING ZONE DEPLOYMENT
module "ai_landing_zone" {
  source = "../../"

  # Basic configuration
  location            = var.location
  resource_group_name = "rg-ailz-policy-${substr(module.naming.unique-seed, 0, 5)}"

  # VNet configuration - required for AI Foundry
  vnet_definition = {
    name          = "vnet-ailz-policy"
    address_space = ["192.168.0.0/23"] # Required for AI Foundry capability host injection
  }

  # AI FOUNDRY CONFIGURATION (Policy Compliant)
  ai_foundry_definition = {
    purge_on_destroy = true # Allows cleanup in testing
    ai_foundry = {
      create_ai_agent_service = true
      disable_local_auth      = true # ✅ POLICY REQUIRED: Disable local authentication
    }

    # AI model deployment
    ai_model_deployments = {
      "gpt-4o" = {
        name = "gpt-4o-deployment"
        model = {
          format  = "OpenAI"
          name    = "gpt-4o"
          version = "2024-08-06"
        }
        scale = {
          type     = "GlobalStandard"
          capacity = 1
        }
      }
    }

    # AI project configuration
    ai_projects = {
      project_1 = {
        name                       = "policy-compliant-project"
        description                = "Policy-compliant AI project"
        display_name               = "Enterprise AI Project"
        create_project_connections = true
        cosmos_db_connection = {
          new_resource_map_key = "primary"
        }
        ai_search_connection = {
          new_resource_map_key = "primary"
        }
        storage_account_connection = {
          new_resource_map_key = "primary"
        }
      }
    }

    # AI SEARCH CONFIGURATION (Policy Compliant)
    ai_search_definition = {
      primary = {
        enable_diagnostic_settings   = true
        sku                          = "standard"
        local_authentication_enabled = false # ✅ POLICY REQUIRED: Disable local auth
      }
    }

    # COSMOS DB CONFIGURATION (Policy Compliant)
    cosmosdb_definition = {
      primary = {
        enable_diagnostic_settings    = true
        consistency_level             = "Session"
        local_authentication_disabled = true # ✅ POLICY REQUIRED: Disable local auth
        automatic_failover_enabled    = false
        multiple_write_locations_enabled = false
      }
    }

    # KEY VAULT CONFIGURATION (Policy Compliant)
    key_vault_definition = {
      primary = {
        enable_diagnostic_settings = true
        sku                        = "standard"
      }
    }

    # STORAGE ACCOUNT CONFIGURATION (Policy Compliant)
    storage_account_definition = {
      primary = {
        enable_diagnostic_settings = true
        shared_access_key_enabled  = false # ✅ POLICY REQUIRED: Disable shared access keys
        account_tier               = "Standard"
        account_replication_type   = "ZRS" # ✅ POLICY REQUIRED: Zone-redundant storage
        endpoints = {
          blob = {
            type = "blob"
          }
        }
      }
    }
  }

  # APPLICATION GATEWAY CONFIGURATION
  app_gateway_definition = {
    backend_address_pools = {
      example_pool = {
        name = "policy-backend-pool"
      }
    }
    backend_http_settings = {
      example_http_settings = {
        name     = "policy-http-settings"
        port     = 80
        protocol = "Http"
      }
    }
    frontend_ports = {
      example_frontend_port = {
        name = "policy-frontend-port"
        port = 80
      }
    }
    http_listeners = {
      example_listener = {
        name               = "policy-listener"
        frontend_port_name = "policy-frontend-port"
      }
    }
    request_routing_rules = {
      example_rule = {
        name                       = "policy-rule"
        rule_type                  = "Basic"
        http_listener_name         = "policy-listener"
        backend_address_pool_name  = "policy-backend-pool"
        backend_http_settings_name = "policy-http-settings"
        priority                   = 100
      }
    }
  }

  # BASTION CONFIGURATION
  bastion_definition = {
    sku = "Standard"
  }

  # CONTAINER APP ENVIRONMENT CONFIGURATION
  container_app_environment_definition = {
    enable_diagnostic_settings = true
  }

  # GENERAL CONFIGURATIONS
  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = true

  # GENAI SERVICES CONFIGURATION (Policy Compliant)
  genai_container_registry_definition = {
    enable_diagnostic_settings = true
    sku                        = "Premium"
    zone_redundancy_enabled    = true
  }

  genai_cosmosdb_definition = {
    enable_diagnostic_settings    = true
    local_authentication_disabled = true # ✅ POLICY REQUIRED: Disable local auth
  }

  genai_key_vault_definition = {
    enable_diagnostic_settings    = true
    public_network_access_enabled = true # For deployment access
    network_acls = {
      bypass   = "AzureServices"
      ip_rules = ["${data.http.ip.response_body}/32"]
    }
  }

  genai_storage_account_definition = {
    enable_diagnostic_settings = true
    shared_access_key_enabled  = false # ✅ POLICY REQUIRED: Disable shared access keys
    account_replication_type   = "ZRS" # ✅ POLICY REQUIRED: Zone-redundant storage
  }

  # KNOWLEDGE SOURCES CONFIGURATION (Policy Compliant)
  ks_ai_search_definition = {
    enable_diagnostic_settings   = true
    sku                          = "standard"
    local_authentication_enabled = false # ✅ POLICY REQUIRED: Disable local auth
  }

  # Apply common tags to all resources
  tags = local.common_tags
}
```

### 4. Create Variables and Outputs Files

Create `variables.tf` and update location value:

```hcl
variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "location" {
  type        = string
  default     = "UPDATE_TO_YOUR_PREFERRED_LOCATION"
  description = <<DESCRIPTION
Azure region where all resources should be deployed.

This specifies the primary Azure region for deploying the AI/ML landing zone infrastructure.
Update the default value to your preferred Azure region (e.g., "eastus2", "westus3", "centralus").
Ensure the selected region has sufficient quotas and supports all required services.
DESCRIPTION
}
```

Create `outputs.tf` for verification commands:

```hcl
output "resource_group_name" {
  description = "The name of the resource group"
  value       = "rg-ailz-policy-${substr(module.naming.unique-seed, 0, 5)}"
}

output "location" {
  description = "The deployment location"
  value       = var.location
}
```

### 5. Initialize Terraform

```bash
# Initialize Terraform to download all required modules
terraform init
```

This will download all the necessary Terraform modules to the `.terraform` directory.

### 6. Apply Required Patches

**Important:** Due to pending updates in upstream modules, you need to apply two patches for policy-compliant configurations to work properly.

> **Note:** This patch step will **not be required** once the upstream pull requests are merged and new module versions are released. This is a temporary workaround that will be removed in future versions of this guide.

#### Patch 1: Cosmos DB Module Fix (Both Locations)

There are **two separate Cosmos DB modules** that need to be patched for policy compliance:

**AI Foundry's Cosmos DB && Standalone Cosmos DB (GenAI Services)**
```bash
# Find the AI Foundry's Cosmos DB module
find .terraform -name "*cosmosdb*" -type d

# Navigate to the AI Foundry Cosmos DB modules (two directories) to update
cd .terraform/modules/~~~/XXX.cosmodb

# Create a backup
cp main.tf main.tf.backup

# Edit main.tf and update the local_authentication_disabled line in the azurerm_cosmosdb_account resource to:
# local_authentication_disabled = length(var.mongo_databases) > 0 ? false : var.local_authentication_disabled
```

**Note:** Both Cosmos DB modules need this patch to properly support the `local_authentication_disabled` parameter.
This addresses the fix from: https://github.com/Azure/terraform-azurerm-avm-res-documentdb-databaseaccount/pull/125

#### Patch 2: AI Foundry Module Fix

Navigate to the AI Foundry module and apply the disable_local_auth fix:

```bash
# Return to your project root
cd /path/to/your/examples/policy-compliant

# Navigate directly to the AI Foundry pattern module
cd .terraform/modules/ai_landing_zone.ai_foundry

# Create a backup of the original file
cp main.ai_search.tf main.ai_search.tf.backup

# Apply the patch
# Edit main.ai_search.tf to ensure omitting AuthOptions when local_authentication_enabled = false
# This addresses the fix from: https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-ai-foundry/pull/34
```

Edit the `main.ai_search.tf` file in the AI Foundry module to ensure  omitting AuthOptions when local_authentication_enabled = false.

**Note:** These patches are temporary workarounds while the upstream pull requests are being reviewed and merged:
- [Cosmos DB PR #125](https://github.com/Azure/terraform-azurerm-avm-res-documentdb-databaseaccount/pull/125)
- [AI Foundry PR #34](https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-ai-foundry/pull/34)

Return to your project directory before proceeding:
```bash
cd /path/to/your/examples/policy-compliant
```

### 7. Configure Azure Authentication and Environment

Before deploying, ensure you're properly authenticated and have the required environment variables set:

```bash
# Login to Azure (use device code for secure authentication)
az login --use-device-code

# Set required environment variables
export ARM_ENVIRONMENT=public # Set to 'usgovernment' or 'china' if not using commercial Azure
export ARM_SUBSCRIPTION_ID="xxxx-xxxx-xxxx-xxxx" # Replace with your actual subscription ID
export ARM_STORAGE_USE_AZUREAD=true
#export ARM_USE_MSI=true # Set this if you are using Managed Service Identity (MSI) for authentication

# Verify your login and subscription
az account show --query "{subscriptionId:id, name:name, tenantId:tenantId}"
```

**Important:**
- Replace `"xxxx-xxxx-xxxx-xxxx"` with your actual Azure subscription ID
- For government or sovereign clouds, update `ARM_ENVIRONMENT` accordingly:
  - US Government: `export ARM_ENVIRONMENT=usgovernment`
  - China: `export ARM_ENVIRONMENT=china`
- The `ARM_STORAGE_USE_AZUREAD=true` setting ensures policy-compliant authentication for storage operations

### 8. Deploy the Infrastructure

```bash
# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

## Policy-Compliant Configuration

### Key Policy Compliance Features

| Policy Requirement | Configuration | Location in Code |
|-------------------|---------------|------------------|
| **Disable Local Authentication** | `local_authentication_enabled = false` | AI Search, Knowledge Sources |
| **Disable Local Authentication** | `local_authentication_disabled = true` | Cosmos DB |
| **Disable Local Authentication** | `disable_local_auth = true` | AI Foundry |
| **Disable Shared Access Keys** | `shared_access_key_enabled = false` | Storage Accounts |
| **Zone Redundant Storage** | `account_replication_type = "ZRS"` | Storage Accounts |
| **Enhanced Security** | Multiple network and access controls | Various services |

### Security Enhancements

- **Network Isolation**: Private endpoints for all services
- **RBAC Authentication**: Azure AD-based authentication only
- **Diagnostic Settings**: Enabled for all services
- **Zone Redundancy**: Where supported by policies
- **IP Restrictions**: Deployment IP whitelisting for Key Vault

## Deployment and Verification

### 1. Monitor Deployment Progress

```bash
# Watch deployment progress
terraform apply -auto-approve 2>&1 | tee deployment.log

```

### 2. Verify Policy Compliance

After successful deployment, verify compliance:

```bash
# Verify AI Search authentication settings
az search service list --resource-group $(terraform output -raw resource_group_name) --query "[].{name:name,disableLocalAuth:disableLocalAuth}" --output table

# Verify Storage Account settings
az storage account list --resource-group $(terraform output -raw resource_group_name) --query "[].{name:name,allowSharedKeyAccess:allowSharedKeyAccess,replication:sku.name}" --output table

# Verify Cosmos DB authentication settings (replace <cosmosdb-name> with actual name)
az cosmosdb list --resource-group $(terraform output -raw resource_group_name) --query "[].{name:name,disableLocalAuth:disableLocalAuth}" --output table

# Verify AI Foundry authentication settings
az cognitiveservices account list --resource-group $(terraform output -raw resource_group_name) --query "[?kind=='AIServices'].{name:name,disableLocalAuth:properties.disableLocalAuth}" --output table

```

### 3. Access Your AI Foundry Hub

1. Navigate to the Azure Portal
2. Find your resource group (starts with `rg-ailz-policy-`)
3. Open the AI Foundry Hub resource
4. Verify all services are connected and functioning


## Troubleshooting

### Deployment Failures

**Issue:** Terraform times out during deployment
```bash
# Solution: Increase timeout and retry
export TF_VAR_timeout="240m"
terraform apply -refresh=false
```

**Issue:** Resource naming conflicts
```bash
# Solution: Force new naming suffix
terraform taint random_integer.region_index
terraform apply
```

**Issue:** Unable to List Write keys for XXX
```bash
# Solution: refresh your token
az logout
az login --use-device-code
```

**Issue:** Database account was created successfully, but the following regions failed to be added to account

**Solution:** This commonly occurs due to Azure regional capacity constraints or policy restrictions. You may escalate to Azure support for a permanent solution. For a short-term workaround, configure Cosmos DB to use a single region by adding this local variable to your `main.tf`:

```hcl
locals {
  # Add to your existing locals block
  secondary_region = {
    location          = var.location  # Use same region as primary
    zone_redundant    = false
    failover_priority = 0
  }
}
```

Then update your Cosmos DB configuration to explicitly set the secondary regions:

```hcl
# Inside ai_foundry_definition
cosmosdb_definition = {
  this = {
    # Add to your existing locals block
    local_authentication_disabled = true
    secondary_regions = [                # Explicit single region to prevent automatic pairing
      local.secondary_region
    ]
    automatic_failover_enabled       = false # No automatic failover
  }
}

# Also update genai_cosmosdb_definition if using GenAI services
genai_cosmosdb_definition = {
  enable_diagnostic_settings    = true
  local_authentication_disabled = true
  secondary_regions = [
    local.secondary_region
  ]
  automatic_failover_enabled       = false
}
```

### Post-Deployment Issues

**Issue:** Services can't authenticate
- Verify RBAC permissions are properly assigned
- Check that Managed Identity assignments are complete
- Ensure private DNS zones are properly configured

**Issue:** Network connectivity problems
- Verify private endpoints are in "Succeeded" state
- Check NSG rules allow required traffic
- Confirm DNS resolution for private endpoints


---

**🎉 Congratulations!** You now have a fully functional, policy-compliant AI/ML Landing Zone ready for enterprise use or evaluation.

For additional customization options, see the [main module documentation](../README.md) or explore other [examples](../examples).
