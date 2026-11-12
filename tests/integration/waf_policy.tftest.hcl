provider "azurerm" {
  features {}
}

variables {
  location            = "australiaeast"
  resource_group_name = "waf-policy-test-${substr(uuid(), 0, 8)}"
  enable_telemetry    = false
  vnet_definition     = {}
  app_gateway_definition = {
    deploy                = true
    backend_address_pools = {}
    backend_http_settings = {}
    frontend_ports        = {}
    http_listeners        = {}
    request_routing_rules = {}
  }
}

run "default_internal_policy" {
  command = apply

  plan_options {
    target = [module.app_gateway_waf_policy]
  }

  assert {
    condition     = length(module.app_gateway_waf_policy) == 1
    error_message = "Deploying the gateway must still create one internal WAF policy by default."
  }

  assert {
    condition     = var.waf_policy_definition.custom_rules == null && var.waf_policy_definition.existing_policy == null
    error_message = "Both new options must be omitted by default."
  }
}

run "custom_ip_block_rule" {
  command = apply

  plan_options {
    target = [module.app_gateway_waf_policy]
  }

  variables {
    waf_policy_definition = {
      custom_rules = {
        block_example_ip = {
          name      = "BlockExampleIP"
          priority  = 10
          rule_type = "MatchRule"
          action    = "Block"
          match_conditions = {
            client_ip = {
              match_values = ["192.0.2.1/32"]
              operator     = "IPMatch"
              match_variables = [{
                variable_name = "RemoteAddr"
              }]
            }
          }
        }
      }
    }
  }

  assert {
    condition     = length(module.app_gateway_waf_policy) == 1
    error_message = "Custom rules must use the internal policy, not create an additional policy."
  }

  assert {
    condition = (
      var.waf_policy_definition.custom_rules.block_example_ip.action == "Block" &&
      var.waf_policy_definition.custom_rules.block_example_ip.match_conditions.client_ip.operator == "IPMatch" &&
      var.waf_policy_definition.custom_rules.block_example_ip.match_conditions.client_ip.match_variables[0].variable_name == "RemoteAddr" &&
      var.waf_policy_definition.custom_rules.block_example_ip.match_conditions.client_ip.match_values[0] == "192.0.2.1/32"
    )
    error_message = "The input schema must retain the complete custom IP block rule."
  }
}

run "external_policy_skips_internal_policy" {
  command = apply

  plan_options {
    target = [module.app_gateway_waf_policy]
  }

  variables {
    waf_policy_definition = {
      existing_policy = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/waf-policy-test/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/external"
      }
    }
  }

  assert {
    condition     = length(module.app_gateway_waf_policy) == 0
    error_message = "Selecting an external policy must remove the internally managed policy."
  }
}

run "disabled_gateway_skips_internal_policy" {
  command = apply

  plan_options {
    target = [module.app_gateway_waf_policy]
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
  }

  assert {
    condition     = length(module.app_gateway_waf_policy) == 0
    error_message = "Disabling the gateway must not create a WAF policy."
  }
}

run "reject_wrong_resource_type" {
  command = plan

  plan_options {
    target = [module.app_gateway_waf_policy]
  }

  variables {
    waf_policy_definition = {
      existing_policy = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/waf-policy-test/providers/Microsoft.Network/virtualNetworks/not-a-policy"
      }
    }
  }

  expect_failures = [var.waf_policy_definition]
}

run "reject_custom_rules_with_external_policy" {
  command = plan

  plan_options {
    target = [module.app_gateway_waf_policy]
  }

  variables {
    waf_policy_definition = {
      existing_policy = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/waf-policy-test/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/external"
      }
      custom_rules = {}
    }
  }

  expect_failures = [var.waf_policy_definition]
}
