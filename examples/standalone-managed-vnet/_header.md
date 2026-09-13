# Standalone managed virtual network example

This example demonstrates a standalone deployment (platform landing zone flag set to false) where the AI Foundry agent service uses a Microsoft-managed virtual network instead of being injected into the landing zone's `AIFoundrySubnet`.

When `ai_foundry_definition.ai_foundry.agent_managed_network_enabled` is set to `true`:

- No subnet network injection is configured for the agent service.
- The delegated `AIFoundrySubnet` is not deployed.
- The agent service runs in a Microsoft-managed network.

For more information see the [Azure AI Foundry managed virtual network documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/configure-managed-network).
