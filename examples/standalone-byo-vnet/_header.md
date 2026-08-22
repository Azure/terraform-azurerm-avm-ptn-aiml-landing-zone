# Standalone BYO VNet example

This example demonstrates a configuration when the platform landing zone flag is set to false and when an existing vnet is referenced.  In this case, all supporting services are included as part of AI landing zone deployment.

The example also prepares the network-isolated Microsoft Foundry hosted-agent handoff for `project_1`. It grants the project's managed identity `AcrPull` on the module-managed registry and returns the project, registry, agent subnet, build subnet, and jumpbox values needed by a downstream `azure.ai.agent` deployment. It does not create the data-plane agent identity or agent version.
