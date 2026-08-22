# AzAPI remains real because Terraform mock providers cannot expose ephemeral
# resource types used by existing module dependencies:
# https://github.com/hashicorp/terraform/issues/38608
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
      tenant_id       = "00000000-0000-0000-0000-000000000004"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

override_module {
  target = module.container_apps_managed_environment
}

override_module {
  target = module.foundry_ptn

  outputs = {
    ai_foundry_name = "mock-foundry"
  }
}

variables {
  app_gateway_definition = {
    backend_address_pools = {}
    backend_http_settings = {}
    frontend_ports        = {}
    http_listeners        = {}
    request_routing_rules = {}
  }
  enable_telemetry           = false
  flag_platform_landing_zone = false
  location                   = "eastus"
  name_prefix                = "parity"
  resource_group_name        = "rg-data-ai-parity-test"
  vnet_definition            = {}
}

run "data_services_defaults" {
  command = plan

  assert {
    condition     = output.data_ai_services.cosmos_sql_databases.application.name == "cosmosdb"
    error_message = "The default Cosmos DB SQL database contract must be present."
  }

  assert {
    condition     = length(output.data_ai_services.cosmos_sql_databases.application.containers.conversations.partition_key_paths) == 1 && output.data_ai_services.cosmos_sql_databases.application.containers.conversations.partition_key_paths[0] == "/principal_id"
    error_message = "The conversations container must retain the /principal_id partition key."
  }

  assert {
    condition     = output.data_ai_services.storage_containers.documents == "documents"
    error_message = "The default private documents container must be present."
  }
}

run "application_insights_and_speech_opt_in" {
  command = plan

  variables {
    app_insights_definition = {
      deploy = true
    }
    ks_speech_service_definition = {
      deploy = true
    }
  }

  assert {
    condition     = output.application_insights_name == "parity-app-insights"
    error_message = "Application Insights must use the deterministic prefixed name."
  }

  assert {
    condition     = output.data_ai_services.speech_service_location == "eastus"
    error_message = "Speech must inherit the landing-zone location by default."
  }
}

run "speech_f0_is_rejected_for_private_networking" {
  command = plan

  variables {
    ks_speech_service_definition = {
      deploy = true
      sku    = "F0"
    }
  }

  expect_failures = [
    var.ks_speech_service_definition,
  ]
}

run "speech_invalid_sku_is_rejected" {
  command = plan

  variables {
    ks_speech_service_definition = {
      sku = "S1"
    }
  }

  expect_failures = [
    var.ks_speech_service_definition,
  ]
}

run "mixed_observability_requires_opt_in" {
  command = plan

  variables {
    app_insights_definition = {
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/central-observability/providers/Microsoft.Insights/components/existing-app-insights"
    }
  }

  expect_failures = [
    terraform_data.observability_contract,
  ]
}

run "existing_application_insights_workspace_must_match" {
  command = plan

  override_data {
    target = data.azapi_resource.existing_application_insights[0]

    values = {
      output = {
        properties = {
          WorkspaceResourceId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/central-observability/providers/Microsoft.OperationalInsights/workspaces/workspace-a"
        }
      }
    }
  }

  variables {
    app_insights_definition = {
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/central-observability/providers/Microsoft.Insights/components/existing-app-insights"
    }
    law_definition = {
      deploy      = false
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/central-observability/providers/Microsoft.OperationalInsights/workspaces/workspace-b"
    }
  }

  expect_failures = [
    terraform_data.observability_contract,
  ]
}
