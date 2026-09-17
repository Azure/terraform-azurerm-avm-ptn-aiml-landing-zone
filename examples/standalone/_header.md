# Standalone example

This example demonstrates a configuration when the platform landing zone flag is set to false.  In this case, all supporting services are included as part of AI landing zone deployment.

The internal WAF policy includes a custom rule that blocks requests from `192.0.2.1/32`, a documentation-only address. This exercises custom-rule passthrough without changing the module's default rules.

This example enables `use_internet_routing` because Application Gateway v2 requires the default route to use `Internet`, not `VirtualAppliance`, in this configuration. The shared route table therefore sends internet-bound traffic from all associated subnets directly to the internet, bypassing Azure Firewall. This is an explicit example setting; the module's default remains firewall routing. See [Application Gateway routing requirements](https://learn.microsoft.com/azure/application-gateway/configuration-infrastructure#supported-user-defined-routes).
