data "azapi_resource" "waf_policy" {
  name                   = "custom-rules-waf-policy"
  parent_id              = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/ai-lz-rg-standalone-${substr(module.naming.unique-seed, 0, 5)}"
  type                   = "Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies@2024-05-01"
  response_export_values = ["properties.customRules", "properties.managedRules"]

  lifecycle {
    postcondition {
      condition = anytrue([
        for rule in self.output.properties.customRules :
        rule.name == "BlockExampleIP" && rule.action == "Block" && rule.priority == 10 && rule.ruleType == "MatchRule" && anytrue([
          for condition in rule.matchConditions :
          condition.operator == "IPMatch" && contains(condition.matchValues, "192.0.2.1/32") && anytrue([
            for variable in condition.matchVariables : variable.variableName == "RemoteAddr"
          ])
        ])
      ])
      error_message = "Azure must retain the custom RemoteAddr/IPMatch rule that blocks 192.0.2.1/32."
    }

    postcondition {
      condition     = length(self.output.properties.managedRules.managedRuleSets) == 2
      error_message = "Adding a custom rule must preserve both default managed rule sets."
    }
  }
  depends_on = [module.test]
}
