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
    condition     = azapi_resource.application_platform_app_configuration_key_value["CUSTOM_SETTING$custom-label"].name == "CUSTOM_SETTING$custom-label"
    error_message = "App Configuration key-value resource names must include the configured label."
  }

  assert {
    condition = (
      length(time_sleep.application_platform_app_config_rbac) == 1 &&
      time_sleep.application_platform_app_config_rbac[0].create_duration == "60s" &&
      contains(keys(time_sleep.application_platform_app_config_rbac[0].triggers), "role_assignment")
    )
    error_message = "App Configuration key-value writes must have a bounded barrier triggered by the deployment principal's Data Owner assignment."
  }
}

run "preserves_same_app_configuration_key_with_distinct_labels" {
  command = plan

  variables {
    application_platform = {
      populate_app_configuration = true
      additional_app_configuration_settings = {
        APP_CONFIG_NAME = {
          value = "custom-name"
          label = "custom-label"
        }
      }
    }
  }

  assert {
    condition = (
      contains(keys(azapi_resource.application_platform_app_configuration_key_value), "APP_CONFIG_NAME$ai-lz") &&
      contains(keys(azapi_resource.application_platform_app_configuration_key_value), "APP_CONFIG_NAME$custom-label") &&
      azapi_resource.application_platform_app_configuration_key_value["APP_CONFIG_NAME$ai-lz"].name == "APP_CONFIG_NAME$ai-lz" &&
      azapi_resource.application_platform_app_configuration_key_value["APP_CONFIG_NAME$custom-label"].name == "APP_CONFIG_NAME$custom-label"
    )
    error_message = "App Configuration settings with the same key and distinct labels must create distinct key-value resources."
  }
}

run "handles_exact_app_configuration_identity_duplicates_deterministically" {
  command = plan

  variables {
    application_platform = {
      app_config_label           = ""
      populate_app_configuration = true
      additional_app_configuration_settings = {
        APP_CONFIG_NAME = {
          value = "consumer-override"
          label = null
        }
      }
    }
  }

  assert {
    condition = (
      length([for identity in keys(azapi_resource.application_platform_app_configuration_key_value) : identity if identity == "APP_CONFIG_NAME"]) == 1 &&
      azapi_resource.application_platform_app_configuration_key_value["APP_CONFIG_NAME"].name == "APP_CONFIG_NAME" &&
      azapi_resource.application_platform_app_configuration_key_value["APP_CONFIG_NAME"].body.properties.value == "consumer-override"
    )
    error_message = "An exact key and empty-label duplicate must resolve to one bare-key resource with the additional setting taking precedence."
  }
}

run "preserves_omitted_container_app_workload_profile" {
  command = plan

  variables {
    application_platform = {
      app_runtime_configuration_mode = "containerEnv"
      container_apps = {
        api = {
          image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
        }
      }
    }
  }

  assert {
    condition     = !contains(keys(azapi_resource.application_platform_container_app["api"].body.properties), "workloadProfileName")
    error_message = "Omitting workload_profile_name must omit workloadProfileName from the Container App body."
  }

  assert {
    condition     = output.application_platform_container_apps["api"].workload_profile_name == null
    error_message = "The Container App output must preserve an omitted workload profile as null."
  }

  assert {
    condition     = azapi_resource.application_platform_container_app["api"].retry == null
    error_message = "Omitting retry must preserve the provider's default retry behavior."
  }
}

run "targets_explicit_dedicated_workload_profile" {
  command = plan

  variables {
    application_platform = {
      app_runtime_configuration_mode = "containerEnv"
      container_apps = {
        api = {
          image                 = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
          workload_profile_name = "dedicated-d4"
        }
      }
    }
    container_app_environment_definition = {
      workload_profile = [{
        name                  = "dedicated-d4"
        workload_profile_type = "D4"
      }]
    }
  }

  assert {
    condition     = azapi_resource.application_platform_container_app["api"].body.properties.workloadProfileName == "dedicated-d4"
    error_message = "An explicit dedicated workload profile must be sent in the Container App body."
  }

  assert {
    condition     = output.application_platform_container_apps["api"].workload_profile_name == "dedicated-d4"
    error_message = "The Container App output must expose the selected dedicated workload profile."
  }
}

run "waits_for_acr_pull_rbac_before_private_container_app" {
  command = plan

  variables {
    application_platform = {
      app_runtime_configuration_mode = "containerEnv"
      container_apps = {
        api = {
          image                = "example.azurecr.io/api:latest"
          use_private_registry = true
        }
      }
    }
  }

  assert {
    condition = (
      length(time_sleep.application_platform_acr_pull_rbac) == 1 &&
      time_sleep.application_platform_acr_pull_rbac["api"].create_duration == "60s" &&
      contains(keys(time_sleep.application_platform_acr_pull_rbac["api"].triggers), "role_assignment")
    )
    error_message = "Private-registry Container App creation must have a bounded barrier triggered by its AcrPull assignment."
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

run "rejects_empty_retry_error_patterns" {
  command = plan

  variables {
    retry = {
      error_message_regex = []
    }
  }

  expect_failures = [var.retry]
}

run "rejects_missing_retry_error_patterns" {
  command = plan

  variables {
    retry = {}
  }

  expect_failures = [var.retry]
}

run "rejects_invalid_workload_profile_name" {
  command = plan

  variables {
    application_platform = {
      container_apps = {
        api = {
          image                 = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
          workload_profile_name = "invalid profile"
        }
      }
    }
  }

  expect_failures = [var.application_platform]
}

run "rejects_unknown_workload_profile_name" {
  command = plan

  variables {
    application_platform = {
      app_runtime_configuration_mode = "containerEnv"
      container_apps = {
        api = {
          image                 = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
          workload_profile_name = "dedicated-d4"
        }
      }
    }
  }

  expect_failures = [output.application_platform]
}
