mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
      tenant_id       = "00000000-0000-0000-0000-000000000004"
    }
  }

  mock_resource "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-application-platform-test"
      location = "eastus2"
      name     = "rg-application-platform-test"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

override_module {
  target = module.foundry_ptn[0]
  outputs = {
    ai_foundry_name = "mock-foundry"
  }
}

override_module {
  target = module.container_apps_managed_environment[0]
  outputs = {
    name        = "mock-container-environment"
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock/providers/Microsoft.App/managedEnvironments/mock"
  }
}

variables {
  app_gateway_definition = {
    deploy                = false
    backend_address_pools = {}
    backend_http_settings = {}
    frontend_ports        = {}
    http_listeners        = {}
    request_routing_rules = {}
  }
  location = "eastus2"
  private_dns_zones = {
    existing_zones_resource_group_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/mock-private-dns"
  }
  resource_group_name = "rg-application-platform-test"
  vnet_definition     = {}
}

run "preserves_application_platform_defaults" {
  command = plan

  assert {
    condition     = output.resource_id == "tbd"
    error_message = "The compatibility-sensitive resource_id output must remain the literal value \"tbd\"."
  }

  assert {
    condition     = output.application_platform.APP_RUNTIME_CONFIGURATION_MODE == "appConfig"
    error_message = "The Application Platform runtime mode must default to appConfig."
  }

  assert {
    condition     = output.application_platform.DEPLOY_CONTAINER_APPS == false
    error_message = "Application Platform workloads must remain opt-in."
  }

  assert {
    condition     = length(azapi_resource.application_platform_app_config_data_owner) == 0
    error_message = "The default configuration must not grant App Configuration Data Owner to the deployment principal."
  }
}

run "uses_configured_app_configuration_labels" {
  command = plan

  variables {
    application_platform = {
      populate_app_configuration = true
      additional_app_configuration_settings = {
        CUSTOM_SETTING = {
          value = "non-secret-value"
          label = "custom-label"
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.application_platform_app_configuration_key_value["CUSTOM_SETTING"].name == "CUSTOM_SETTING$custom-label"
    error_message = "App Configuration key-value resource names must include the configured label."
  }
}

run "rejects_workloads_without_container_environment" {
  command = plan

  variables {
    application_platform = {
      container_apps = {
        api = {
          image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
        }
      }
    }
    container_app_environment_definition = {
      deploy = false
    }
  }

  expect_failures = [output.application_platform]
}

run "rejects_invalid_runtime_mode" {
  command = plan

  variables {
    application_platform = {
      app_runtime_configuration_mode = "invalid"
    }
  }

  expect_failures = [var.application_platform]
}

run "rejects_invalid_agent_pool" {
  command = plan

  variables {
    application_platform = {
      acr_task_agent_pool = {
        tier  = "P1"
        count = -1
      }
    }
  }

  expect_failures = [var.application_platform]
}
