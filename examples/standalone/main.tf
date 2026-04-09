terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi" 
      version = ">= 1.10.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116, < 5.0"
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
  subscription_id = var.subscription_id

}

variable "regions" {
  type    = list(string)
  default = ["eastus", "westus", "centralindia"]
}
# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  min = 0
  max = length(var.regions) - 1
}

## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

locals {
  location = "australiaeast"
}

variable "resource_group_name" {
  type        = string
  default     = "ailz-rg-tf-standalone-vpds11"
}

variable "subscription_id" {
  type = string
  default = "9ad6f7f4-b0d6-4d88-a6d1-3fc2257d5583"
}

module "vm_sku" {
  source  = "Azure/avm-utl-sku-finder/azapi"
  version = "0.3.0"

  location      = local.location
  cache_results = true
  vm_filters = {
    cpu_architecture_type          = "x64"
    min_vcpus                      = 2
    max_vcpus                      = 2
    encryption_at_host_supported   = true
    accelerated_networking_enabled = true
    premium_io_supported           = true
  }
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}


# Create resource group before anything else
module "test" {
  source = "../../"

  openAiUris                 = {}

  resource_group_name = var.resource_group_name
  location            = local.location
  openai_resource_name = "aoai-${random_string.suffix.result}"

  ############################################
  # Core Naming (FIXED)
  ############################################
  name            = "apim-${random_string.suffix.result}"
  publisherEmail  = "admin@example.com"
  publisherName   = "apim-user"
  sku             = "Developer_1"
  skuCount        = 1

  ############################################
  # Application Insights
  ############################################
  applicationInsightsName = "appi-${random_string.suffix.result}"

  ############################################
  # Managed Identity
  ############################################
  managedIdentityName = "mi-${random_string.suffix.result}"


  aiSearchInstances          = []

  namespace_name   = "ehns-${random_string.suffix.result}"
  eventHubName     = "eh-${random_string.suffix.result}"
  eventHubEndpoint = ""
  eventHubPIIName  = "ehpii-${random_string.suffix.result}"
  eventHubPIIEndpoint = ""

  clientAppId = "11111111-1111-1111-1111-111111111111"
  tenantId    = "0e478cd4-3e52-496d-ac3a-419ca58ba7ac"
  audience    = "api://default"

  contentSafetyServiceUrl = "https://example.com/content-safety"
  aiLanguageServiceUrl    = "https://example.com/language"

  entraAuth                  = false
  enableAzureAISearch        = true
  enableAIModelInference     = true
  enableOpenAIRealtime       = true
  enableDocumentIntelligence = true
  enablePIIAnonymization     = true

  ############################################
  # Named Values
  ############################################
  openAiApiUamiNamedValue     = "mi-${random_string.suffix.result}"
  openAiApiClientNamedValue   = "11111111-1111-1111-1111-111111111111"
  openAiApiEntraNamedValue    = "entra-auth"
  entraAuthUrl                = "https://login.microsoftonline.com/"
  openAiApiAudienceNamedValue = "audience"
  openAiApiTenantNamedValue   = "0e478cd4-3e52-496d-ac3a-419ca58ba7ac"
  openApiSpecification = "https://petstore3.swagger.io/api/v3/openapi.json"


  privateEndpointSubnetId   = ""
  apimSubnetId              = ""
  apimV2PrivateEndpointName = ""

  vnet_definition = {
    name          = "vnet-${random_string.suffix.result}"
    address_space = ["192.168.0.0/20"]
  }

  ai_foundry_definition = {
    purge_on_destroy = true
    ai_foundry = {
      create_ai_agent_service    = true
      enable_diagnostic_settings = false
    }
    ai_model_deployments = {
      "gpt-4.1" = {
        name = "gpt-4.1"
        model = {
          format  = "OpenAI"
          name    = "gpt-4.1"
          version = "2025-04-14"
        }
        scale = {
          type     = "GlobalStandard"
          capacity = 1
        }
      }
    }

    ai_projects = {
      project_1 = {
        name         = "proj-${random_string.suffix.result}"
        description  = "Test project"
        display_name = "Test Project"

        create_project_connections = true

        cosmos_db_connection = {
          new_resource_map_key = "this"
        }

        ai_search_connection = {
          new_resource_map_key = "this"
        }

        storage_account_connection = {
          new_resource_map_key = "this"
        }
      }
    }

    ai_search_definition = {
      this = {
      }
    }

    buildvm_definition = {
      sku = module.vm_sku.sku
    }

    cosmosdb_definition = {
      this = {
        name                = "cosmos-foundry-${random_string.suffix.result}"
        consistency_level   = "Session"
        kind                = "GlobalDocumentDB"
        offer_type          = "Standard"
        geo_location        = [{ location = local.location, failover_priority = 0 }]
      }
    }

    key_vault_definition = {
      this = {
        network_acls = {
          default_action = "Allow"
        }
      }
    }

    storage_account_definition = {
      this = {
        shared_access_key_enabled = true
        endpoints = {
          blob = {
            type = "blob"
          }
        }
      }
    }
  }

  apim_definition = {
    publisher_email = "admin@example.com"
    publisher_name  = "apim-user"
  }

  app_gateway_definition = {
    backend_address_pools = {
      example_pool = {
        name = "example-backend-pool"
      }
    }

    backend_http_settings = {
      example_http_settings = {
        name     = "example-http-settings"
        port     = 80
        protocol = "Http"
      }
    }

    frontend_ports = {
      example_frontend_port = {
        name = "example-frontend-port"
        port = 80
      }
    }

    http_listeners = {
      example_listener = {
        name               = "example-listener"
        frontend_port_name = "example-frontend-port"
      }
    }

    request_routing_rules = {
      example_rule = {
        name                       = "example-rule"
        rule_type                  = "Basic"
        http_listener_name         = "example-listener"
        backend_address_pool_name  = "example-backend-pool"
        backend_http_settings_name = "example-http-settings"
        priority                   = 100
      }
    }
  }
  bastion_definition = {
  }
  container_app_environment_definition = {
    enable_diagnostic_settings = false
  }

  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = true

  genai_app_configuration_definition = {
    enable_diagnostic_settings = false
  }
  genai_container_registry_definition = {
    enable_diagnostic_settings = false
  }
  genai_cosmosdb_definition = {
    consistency_level = "Session"
  }
  genai_key_vault_definition = {
    #this is for AVM testing purposes only. Doing this as we don't have an easy for the test runner to be privately connected for testing.
    public_network_access_enabled = true
    network_acls = {
      bypass   = "AzureServices"
      ip_rules = ["${trimspace(data.http.ip.response_body)}/32"]
    }
  }
  genai_storage_account_definition = {
  }
  ks_ai_search_definition = {
    enable_diagnostic_settings = false
  }
}
