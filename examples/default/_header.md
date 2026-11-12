# Default example

This example deploys the version of the module with the platform landing zone flag set to true. In this configuration, the assumption is that a hub Vnet hosting DNS has been provided and that the landing zone will attach to a hub Vnet for all the standard network services. (DNS, Hybrid Connectivity, Firewalls, and etc.)

Application Gateway uses a WAF policy created separately in the example hub resource group. The pattern module receives its computed resource ID through `waf_policy_definition.existing_policy` and does not create an internal WAF policy.
