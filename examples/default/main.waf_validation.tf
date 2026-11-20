# This read is used only for its postcondition, which verifies the deployed gateway.
# tflint-ignore: terraform_unused_declarations
data "azapi_resource" "application_gateway" {
  name                   = "ai-alz-appgw"
  parent_id              = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/ai-lz-rg-default-${substr(module.naming.unique-seed, 0, 5)}"
  type                   = "Microsoft.Network/applicationGateways@2024-05-01"
  response_export_values = ["properties.firewallPolicy"]

  lifecycle {
    postcondition {
      condition     = lower(self.output.properties.firewallPolicy.id) == lower(module.external_waf_policy.resource_id)
      error_message = "Application Gateway must attach the external WAF policy at gateway scope."
    }
  }
  depends_on = [module.test]
}
