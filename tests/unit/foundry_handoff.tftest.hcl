mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "11111111-1111-1111-1111-111111111111"
      object_id       = "22222222-2222-2222-2222-222222222222"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "33333333-3333-3333-3333-333333333333"
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

override_module {
  target = module.foundry_ptn
  outputs = {
    ai_agent_account_capability_host_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-foundry-handoff-test/providers/Microsoft.CognitiveServices/accounts/test-foundry/capabilityHosts/account"
    ai_agent_service_id                             = { project_1 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-foundry-handoff-test/providers/Microsoft.CognitiveServices/accounts/test-foundry/projects/project-1/capabilityHosts/project" }
    ai_foundry_id                                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-foundry-handoff-test/providers/Microsoft.CognitiveServices/accounts/test-foundry"
    ai_foundry_name                                 = "test-foundry"
    ai_foundry_project_id                           = { project_1 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-foundry-handoff-test/providers/Microsoft.CognitiveServices/accounts/test-foundry/projects/project-1" }
    ai_foundry_project_name                         = { project_1 = "project-1" }
    ai_foundry_project_system_identity_principal_id = { project_1 = "44444444-4444-4444-4444-444444444444" }
    ai_model_deployment_ids                         = {}
    ai_search_id                                    = { this = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-foundry-handoff-test/providers/Microsoft.Search/searchServices/test-search" }
    cosmos_db_id                                    = { this = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-foundry-handoff-test/providers/Microsoft.DocumentDB/databaseAccounts/test-cosmos" }
    key_vault_id                                    = {}
    storage_account_id                              = { this = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-foundry-handoff-test/providers/Microsoft.Storage/storageAccounts/teststorage" }
  }
}

override_module {
  target = module.containerregistry
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-foundry-handoff-test/providers/Microsoft.ContainerRegistry/registries/managedacr"
    resource = {
      login_server = "managedacr.azurecr.io"
    }
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
  location                   = "eastus2"
  resource_group_name        = "rg-foundry-handoff-test"
  flag_platform_landing_zone = false
  enable_telemetry           = false
  vnet_definition            = {}
  container_app_environment_definition = {
    deploy = false
  }

  ai_foundry_definition = {
    ai_foundry = {
      create_ai_agent_service = true
    }
    ai_search_definition = {
      this = {}
    }
    cosmosdb_definition = {
      this = {}
    }
    ai_projects = {
      project_1 = {
        name                       = "project-1"
        display_name               = "Project 1"
        description                = "Hosted-agent handoff test project."
        create_project_connections = true
        ai_search_connection = {
          new_resource_map_key = "this"
        }
        cosmos_db_connection = {
          new_resource_map_key = "this"
        }
        storage_account_connection = {
          new_resource_map_key = "this"
        }
      }
    }
    storage_account_definition = {
      this = {}
    }
  }
}

run "prepares_only_with_managed_registry" {
  command = plan

  variables {
    hosted_agent_definition = {
      prepare     = true
      project_key = "project_1"
    }
  }

  assert {
    condition     = output.hosted_agent_prepared && !output.deploy_hosted_agent
    error_message = "Prepare-only mode must select prerequisites without requesting downstream deployment."
  }

  assert {
    condition     = output.hosted_agent_deployment.agent == null
    error_message = "Prepare-only mode must not emit an agent deployment contract."
  }

  assert {
    condition     = output.hosted_agent_deployment.container_registry.role_assignment_mode == "rbac"
    error_message = "The module-managed registry must use RBAC Registry Permissions."
  }

  assert {
    condition     = length(azapi_resource.hosted_agent_registry_pull) == 1 && length(azapi_resource.hosted_agent_project_manager) == 1
    error_message = "Preparation must create both registry pull and project-manager role assignments."
  }

  assert {
    condition     = azapi_resource.hosted_agent_registry_pull[0].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d"
    error_message = "The managed registry must grant AcrPull."
  }
}

run "emits_normalized_deploy_handoff" {
  command = plan

  variables {
    genai_container_registry_definition = {
      deploy = false
    }
    hosted_agent_definition = {
      deploy      = true
      project_key = " project_1 "
      agent = {
        name            = " test-agent "
        image           = " agents/test-agent "
        version         = " sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa "
        startup_command = " python -m agent "
      }
      container_registry = {
        existing_resource_id = " /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-acr/providers/Microsoft.ContainerRegistry/registries/testacr "
        existing_endpoint    = " testacr.azurecr.io "
        role_assignment_mode = " RBAC "
      }
    }
  }

  assert {
    condition     = output.hosted_agent_deployment.enabled && output.hosted_agent_deployment.agent.name == "test-agent"
    error_message = "Deploy mode must emit the normalized agent name."
  }

  assert {
    condition     = output.hosted_agent_deployment.agent.image == "testacr.azurecr.io/agents/test-agent@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    error_message = "The image reference must use normalized endpoint, image, and immutable digest values."
  }

  assert {
    condition     = output.hosted_agent_deployment.agent.image_version == "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" && output.hosted_agent_deployment.agent.startup_command == "python -m agent"
    error_message = "The digest and startup command must be normalized."
  }

  assert {
    condition     = output.hosted_agent_deployment.container_registry.resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-acr/providers/Microsoft.ContainerRegistry/registries/testacr" && output.hosted_agent_deployment.container_registry.endpoint == "testacr.azurecr.io"
    error_message = "Existing registry outputs must be normalized."
  }
}

run "prepares_existing_rbac_registry" {
  command = plan

  variables {
    genai_container_registry_definition = {
      deploy = false
    }
    hosted_agent_definition = {
      prepare     = true
      project_key = "project_1"
      container_registry = {
        existing_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-acr/providers/Microsoft.ContainerRegistry/registries/testacr"
        existing_endpoint    = "testacr.azurecr.io"
        role_assignment_mode = "rbac"
      }
    }
  }

  assert {
    condition     = azapi_resource.hosted_agent_registry_pull[0].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d"
    error_message = "An existing RBAC registry must grant AcrPull."
  }
}

run "prepares_existing_rbac_abac_registry" {
  command = plan

  variables {
    genai_container_registry_definition = {
      deploy = false
    }
    hosted_agent_definition = {
      prepare     = true
      project_key = "project_1"
      container_registry = {
        existing_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-acr/providers/Microsoft.ContainerRegistry/registries/testacr"
        existing_endpoint    = "testacr.azurecr.io"
        role_assignment_mode = " RBAC-ABAC "
      }
    }
  }

  assert {
    condition     = output.hosted_agent_deployment.container_registry.role_assignment_mode == "rbac-abac"
    error_message = "The handoff must normalize the existing registry permission mode."
  }

  assert {
    condition     = azapi_resource.hosted_agent_registry_pull[0].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/b93aa761-3e63-49ed-ac28-beffa264f7ac"
    error_message = "An existing RBAC+ABAC registry must grant Container Registry Repository Reader."
  }
}

run "grants_project_manager_to_deployment_principal" {
  command = plan

  variables {
    hosted_agent_definition = {
      prepare     = true
      project_key = "project_1"
    }
  }

  assert {
    condition     = azapi_resource.hosted_agent_project_manager[0].body.properties.principalId == "22222222-2222-2222-2222-222222222222"
    error_message = "Azure AI Project Manager must be granted to the active deployment principal."
  }

  assert {
    condition     = azapi_resource.hosted_agent_project_manager[0].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/eadc314b-1a2d-4efa-be10-5d325db5065e"
    error_message = "The project-scoped assignment must use Azure AI Project Manager."
  }
}

run "rejects_mutable_image_version" {
  command = plan

  variables {
    hosted_agent_definition = {
      deploy      = true
      project_key = "project_1"
      agent = {
        name    = "test-agent"
        image   = "agents/test-agent"
        version = "latest"
      }
    }
  }

  expect_failures = [
    var.hosted_agent_definition,
  ]
}

run "rejects_wrong_registry_resource_type" {
  command = plan

  variables {
    genai_container_registry_definition = {
      deploy = false
    }
    hosted_agent_definition = {
      prepare     = true
      project_key = "project_1"
      container_registry = {
        existing_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-acr/providers/Microsoft.Storage/storageAccounts/notacr"
        existing_endpoint    = "testacr.azurecr.io"
      }
    }
  }

  expect_failures = [
    var.hosted_agent_definition,
  ]
}

run "rejects_registry_endpoint_url" {
  command = plan

  variables {
    genai_container_registry_definition = {
      deploy = false
    }
    hosted_agent_definition = {
      prepare     = true
      project_key = "project_1"
      container_registry = {
        existing_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-acr/providers/Microsoft.ContainerRegistry/registries/testacr"
        existing_endpoint    = "https://testacr.azurecr.io/path"
      }
    }
  }

  expect_failures = [
    var.hosted_agent_definition,
  ]
}

run "rejects_whitespace_only_agent_name" {
  command = plan

  variables {
    hosted_agent_definition = {
      deploy      = true
      project_key = "project_1"
      agent = {
        name    = " "
        image   = "agents/test-agent"
        version = "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      }
    }
  }

  expect_failures = [
    var.hosted_agent_definition,
  ]
}

run "rejects_hub_spoke_handoff" {
  command = plan

  variables {
    flag_platform_landing_zone = true
    private_dns_zones = {
      existing_zones_resource_group_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns"
    }
    hosted_agent_definition = {
      prepare     = true
      project_key = "project_1"
    }
  }

  expect_failures = [
    var.hosted_agent_definition,
  ]
}

run "rejects_empty_registry_endpoint" {
  command = plan

  variables {
    genai_container_registry_definition = {
      deploy = false
    }
    hosted_agent_definition = {
      prepare     = true
      project_key = "project_1"
      container_registry = {
        existing_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-acr/providers/Microsoft.ContainerRegistry/registries/testacr"
        existing_endpoint    = " "
      }
    }
  }

  expect_failures = [
    var.hosted_agent_definition,
  ]
}
