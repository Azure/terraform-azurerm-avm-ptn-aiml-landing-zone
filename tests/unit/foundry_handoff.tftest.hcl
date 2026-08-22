provider "azurerm" {
  features {}
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
  vnet_definition            = {}

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
