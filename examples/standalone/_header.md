# Standalone example

This example demonstrates a configuration when the platform landing zone flag is set to false.  In this case, all supporting services are included as part of AI landing zone deployment.

The internal WAF policy includes a custom rule that blocks requests from `192.0.2.1/32`, a documentation-only address. This exercises custom-rule passthrough without changing the module's default rules.
