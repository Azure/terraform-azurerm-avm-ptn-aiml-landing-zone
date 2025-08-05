locals {
  default_outbound_network_ruleset = [
    {
      name                  = "OutboundToInternet"
      description           = "Allow traffic outbound to the Internet"
      destination_addresses = ["0.0.0.0/0"]
      destination_ports     = ["443", "80"]
      source_addresses      = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      protocols             = ["TCP", "UDP"]
    }
  ]
  firewall_policy_network_ruleset            = concat(local.default_outbound_network_ruleset, try(var.firewall_policy_definition.network_ruleset, []))
  firewall_policy_rule_collection_group_name = var.firewall_policy_definition.network_policy_rule_collection_group_name != null ? var.firewall_policy_definition.network_policy_rule_collection_group_name : "NetworkRuleCollectionGroup"
  firewall_policy_rule_collection_group_network_rule_collection = [
    {
      action   = "Allow"
      name     = local.firewall_policy_rule_collection_group_name
      priority = local.firewall_policy_rule_collection_group_priority
      rule     = local.firewall_policy_network_ruleset
    }
  ]
  firewall_policy_rule_collection_group_priority = var.firewall_policy_definition.network_policy_rule_collection_group_priority != null ? var.firewall_policy_definition.network_policy_rule_collection_group_priority : 400
}
