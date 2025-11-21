terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  # Backend configuration is expected to be passed via CLI or environment variables in CI/CD
  # e.g., terraform init -backend-config="resource_group_name=..." ...
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

module "ai_landing_zone" {
  source = "../"

  location            = "swedencentral"
  resource_group_name = "rg-ai-foundry-minimal-${random_string.suffix.result}"

  vnet_definition = {
    address_space = ["10.0.0.0/16", "192.168.0.0/16"]
    subnets = {
      "PrivateEndpointSubnet" = {
        address_prefix = "10.0.0.0/24"
      }
      "AIFoundrySubnet" = {
        address_prefix = "192.168.0.0/24"
      }
    }
  }

  ai_foundry_definition = {
    ai_foundry = {
      name                    = "aifoundry-${random_string.suffix.result}"
      sku                     = "S0"
      create_ai_agent_service = true
    }
    ai_projects = {
      "default-project" = {
        name         = "proj-default-${random_string.suffix.result}"
        display_name = "Default Project"
        description  = "Minimal AI Foundry Project"
      }
    }
  }

  # Disable optional components for a minimal setup
  apim_definition                      = { deploy = false }
  app_gateway_definition               = { deploy = false }
  bastion_definition                   = { deploy = false }
  buildvm_definition                   = { deploy = false }
  container_app_environment_definition = { deploy = false }
  firewall_definition                  = { deploy = false }
  jumpvm_definition                    = { deploy = false }
  flag_platform_landing_zone           = false # Standalone deployment
}
