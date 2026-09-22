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

run "data_services_defaults_are_upgrade_safe" {
  command = plan

  assert {
    condition     = output.data_ai_services.cosmos_sql_databases == {}
    error_message = "Cosmos DB SQL databases must default to empty so upgrades do not create child resources."
  }

  assert {
    condition     = output.data_ai_services.storage_containers == {}
    error_message = "Storage containers must default to empty so upgrades do not create child resources."
  }
}

run "data_services_children_are_explicitly_opted_in" {
  command = plan

  variables {
    genai_cosmosdb_definition = {
      sql_databases = {
        application = {
          name = "cosmosdb"
          containers = {
            conversations = {
              name                = "conversations"
              partition_key_paths = ["/principal_id"]
              default_ttl         = -1
            }
          }
        }
      }
    }
    genai_storage_account_definition = {
      containers = {
        documents = {
          name          = "documents"
          public_access = "None"
        }
      }
    }
  }

  assert {
    condition     = output.data_ai_services.cosmos_sql_databases.application.name == "cosmosdb"
    error_message = "The explicit Cosmos DB parity preset must create the application database."
  }

  assert {
    condition     = output.data_ai_services.cosmos_sql_databases.application.containers.conversations.partition_key_paths == tolist(["/principal_id"])
    error_message = "The explicit conversations container must retain the /principal_id partition key."
  }

  assert {
    condition     = output.data_ai_services.storage_containers.documents == "documents"
    error_message = "The explicit private documents container must be present."
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
    law_definition = {
      deploy      = false
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/central-observability/providers/Microsoft.OperationalInsights/workspaces/workspace-a"
    }
    private_dns_zones = {
      azure_policy_pe_zone_linking_enabled = false
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

  assert {
    condition = (
      azapi_resource.application_insights[0].body.properties.WorkspaceResourceId == "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/central-observability/providers/Microsoft.OperationalInsights/workspaces/workspace-a" &&
      azapi_resource.application_insights[0].body.properties.DisableLocalAuth &&
      azapi_resource_action.application_insights_daily_cap[0].body.DataVolumeCap.Cap == 100
    )
    error_message = "Application Insights must remain workspace-associated, local-auth disabled, and daily-cap managed."
  }

  assert {
    condition = (
      azapi_resource.speech_service[0].body.properties.publicNetworkAccess == "Disabled" &&
      azapi_resource.speech_service[0].body.properties.networkAcls.defaultAction == "Deny" &&
      azapi_resource.speech_service[0].body.properties.disableLocalAuth &&
      azapi_resource.speech_service[0].identity[0].type == "SystemAssigned"
    )
    error_message = "Network-isolated Speech must disable public/local access, deny by default, and use a system identity."
  }

  assert {
    condition = (
      length(azapi_resource.speech_private_endpoint) == 1 &&
      azapi_resource.speech_private_endpoint[0].body.properties.privateLinkServiceConnections[0].properties.groupIds == ["account"] &&
      length(azapi_resource.speech_private_dns_zone_group) == 1 &&
      azapi_resource.speech_private_dns_zone_group[0].body.properties.privateDnsZoneConfigs[0].name == "cognitive-services"
    )
    error_message = "Network-isolated Speech must create the account private endpoint and Cognitive Services DNS zone group."
  }

  assert {
    condition     = length(azapi_resource.speech_diagnostic_setting) == 1 && values(azapi_resource.speech_diagnostic_setting)[0].body.properties.workspaceId == "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/central-observability/providers/Microsoft.OperationalInsights/workspaces/workspace-a"
    error_message = "Speech diagnostics must target the effective Log Analytics workspace."
  }

  assert {
    condition     = length(azapi_resource.speech_role_assignment) == 0
    error_message = "Deployment-principal Speech RBAC must remain opt-in."
  }
}

run "speech_standard_access_has_no_private_endpoint" {
  command = plan

  variables {
    ks_speech_service_definition = {
      deploy                           = true
      enable_diagnostic_settings       = false
      public_network_access_enabled    = true
      assign_deployment_principal_rbac = false
    }
  }

  assert {
    condition = (
      azapi_resource.speech_service[0].body.properties.publicNetworkAccess == "Enabled" &&
      azapi_resource.speech_service[0].body.properties.networkAcls.defaultAction == "Allow" &&
      length(azapi_resource.speech_private_endpoint) == 0 &&
      length(azapi_resource.speech_private_dns_zone_group) == 0
    )
    error_message = "Standard Speech must enable public access and omit private endpoint/DNS resources."
  }
}

run "speech_deployment_principal_rbac_is_explicit" {
  command = plan

  variables {
    ks_speech_service_definition = {
      deploy                           = true
      enable_diagnostic_settings       = false
      public_network_access_enabled    = true
      assign_deployment_principal_rbac = true
    }
  }

  assert {
    condition = toset([for assignment in values(azapi_resource.speech_role_assignment) : assignment.body.properties.roleDefinitionId]) == toset([
      "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68",
      "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/a97b65f3-24c7-4388-baec-2e87135dc908",
    ])
    error_message = "Explicit deployment-principal RBAC must assign only Cognitive Services Contributor and User."
  }
}

run "application_insights_diagnostics_are_explicit" {
  command = plan

  variables {
    app_insights_definition = {
      deploy                     = true
      enable_diagnostic_settings = true
    }
    law_definition = {
      deploy      = false
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/central-observability/providers/Microsoft.OperationalInsights/workspaces/workspace-a"
    }
  }

  assert {
    condition = (
      length(azapi_resource.application_insights_diagnostic_setting) == 1 &&
      values(azapi_resource.application_insights_diagnostic_setting)[0].body.properties.workspaceId == "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/central-observability/providers/Microsoft.OperationalInsights/workspaces/workspace-a" &&
      values(azapi_resource.application_insights_diagnostic_setting)[0].body.properties.logs == [{
        categoryGroup = "allLogs"
        enabled       = true
        retentionPolicy = {
          days    = 0
          enabled = false
        }
      }] &&
      values(azapi_resource.application_insights_diagnostic_setting)[0].body.properties.metrics == [{
        category = "AllMetrics"
        enabled  = true
        retentionPolicy = {
          days    = 0
          enabled = false
        }
      }]
    )
    error_message = "Automatic Application Insights diagnostics must target the effective workspace and collect allLogs and AllMetrics."
  }
}

run "application_insights_explicit_diagnostics_are_preserved" {
  command = plan

  variables {
    app_insights_definition = {
      deploy                     = true
      enable_diagnostic_settings = true
      diagnostic_settings = {
        requests_only = {
          workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/central-observability/providers/Microsoft.OperationalInsights/workspaces/workspace-a"
          logs = [{
            category = "AppRequests"
          }]
          metrics = [{
            category = "AllMetrics"
            enabled  = false
          }]
        }
      }
    }
    law_definition = {
      deploy      = false
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/central-observability/providers/Microsoft.OperationalInsights/workspaces/workspace-a"
    }
  }

  assert {
    condition = (
      length(azapi_resource.application_insights_diagnostic_setting) == 1 &&
      values(azapi_resource.application_insights_diagnostic_setting)[0].body.properties.logs == [{
        category = "AppRequests"
        enabled  = true
        retentionPolicy = {
          days    = 0
          enabled = false
        }
      }] &&
      values(azapi_resource.application_insights_diagnostic_setting)[0].body.properties.metrics == [{
        category = "AllMetrics"
        enabled  = false
        retentionPolicy = {
          days    = 0
          enabled = false
        }
      }]
    )
    error_message = "Explicit Application Insights diagnostic categories and enabled states must remain unchanged."
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
