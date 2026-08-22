variable "hosted_agent_definition" {
  type = object({
    prepare     = optional(bool, false)
    deploy      = optional(bool, false)
    project_key = optional(string)
    agent = optional(object({
      name            = optional(string, "")
      image           = optional(string, "")
      version         = optional(string, "")
      startup_command = optional(string, "")
      runtime = optional(object({
        cpu    = optional(string, "1")
        memory = optional(string, "1Gi")
      }), {})
      protocols = optional(list(object({
        protocol = string
        version  = optional(string)
        })), [{
        protocol = "responses"
        version  = "2.0.0"
      }])
    }), {})
    container_registry = optional(object({
      existing_resource_id = optional(string)
      existing_endpoint    = optional(string)
      role_assignment_mode = optional(string, "rbac")
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Configuration for the Microsoft Foundry hosted-agent deployment handoff. This module prepares infrastructure and returns a typed handoff; it does not create the downstream data-plane agent identity or agent version.

- `prepare` - (Optional) Prepare hosted-agent prerequisites without requesting downstream deployment. Default is false.
- `deploy` - (Optional) Request downstream hosted-agent deployment in the returned handoff. Implies `prepare`. Default is false.
- `project_key` - (Optional) Key of the project in `ai_foundry_definition.ai_projects`. Required when prerequisites are enabled and more than one project is configured.
- `agent` - (Optional) Downstream `azure.ai.agent` service contract.
  - `name` - Stable agent name.
  - `image` - Repository path inside the selected registry, without a tag or digest.
  - `version` - Immutable OCI digest in `sha256:<64 lowercase hexadecimal characters>` form.
  - `startup_command` - Optional command that starts the agent server.
  - `runtime` - Container CPU and memory settings.
    - `cpu` - CPU allocation from 0.25 through 4. Default is "1".
    - `memory` - Memory allocation from 0.5Gi through 8Gi. Default is "1Gi".
  - `protocols` - Invocation protocols implemented by the agent. Default is the responses protocol version 2.0.0.
- `container_registry` - (Optional) Existing registry contract used when `genai_container_registry_definition.deploy` is false.
  - `existing_resource_id` - Resource ID of an existing Azure Container Registry.
  - `existing_endpoint` - Login endpoint of the existing registry, for example `contoso.azurecr.io`.
  - `role_assignment_mode` - Registry permissions mode. Allowed values are `rbac` and `rbac-abac`. Default is `rbac`.

The supported hosted-agent scenario is standalone with network isolation. Hub-spoke and public standalone Foundry topologies are intentionally excluded. The selected Foundry account must enable AI Agent Service, and the selected project must enable project connections.
DESCRIPTION
  nullable    = false

  validation {
    condition = (
      !var.hosted_agent_definition.prepare &&
      !var.hosted_agent_definition.deploy
      ) || (
      !var.flag_platform_landing_zone &&
      length(var.ai_foundry_definition.ai_projects) > 0
    )
    error_message = "Hosted-agent prerequisites require a standalone deployment and at least one AI Foundry project."
  }
  validation {
    condition = (
      !var.hosted_agent_definition.prepare &&
      !var.hosted_agent_definition.deploy
      ) || (
      var.hosted_agent_definition.project_key != null ?
      contains(keys(var.ai_foundry_definition.ai_projects), var.hosted_agent_definition.project_key) :
      length(var.ai_foundry_definition.ai_projects) == 1
    )
    error_message = "Set project_key to a configured ai_foundry_definition.ai_projects key when hosted-agent prerequisites are enabled with multiple projects."
  }
  validation {
    condition = (
      !var.hosted_agent_definition.prepare &&
      !var.hosted_agent_definition.deploy
      ) || (
      var.ai_foundry_definition.ai_foundry.create_ai_agent_service &&
      (
        var.hosted_agent_definition.project_key != null ?
        try(var.ai_foundry_definition.ai_projects[var.hosted_agent_definition.project_key].create_project_connections, false) :
        try(values(var.ai_foundry_definition.ai_projects)[0].create_project_connections, false)
      )
    )
    error_message = "Hosted-agent prerequisites require ai_foundry.create_ai_agent_service and create_project_connections on the selected project."
  }
  validation {
    condition = var.genai_container_registry_definition.deploy || (
      var.hosted_agent_definition.container_registry.existing_resource_id != null &&
      var.hosted_agent_definition.container_registry.existing_endpoint != null &&
      trimspace(var.hosted_agent_definition.container_registry.existing_endpoint) != ""
      ) || (
      !var.hosted_agent_definition.prepare &&
      !var.hosted_agent_definition.deploy
    )
    error_message = "An existing container registry resource ID and endpoint are required when hosted-agent prerequisites are enabled and the module-managed registry is disabled."
  }
  validation {
    condition = (
      var.hosted_agent_definition.container_registry.existing_resource_id == null ||
      can(provider::azapi::parse_resource_id("Microsoft.ContainerRegistry/registries", var.hosted_agent_definition.container_registry.existing_resource_id))
    )
    error_message = "container_registry.existing_resource_id must be a valid Azure Container Registry resource ID."
  }
  validation {
    condition = (
      var.hosted_agent_definition.container_registry.existing_endpoint == null ||
      can(regex(
        "^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$",
        trimspace(var.hosted_agent_definition.container_registry.existing_endpoint)
      ))
    )
    error_message = "container_registry.existing_endpoint must be a non-empty registry login hostname without a URL scheme or path."
  }
  validation {
    condition = contains(
      ["rbac", "rbac-abac"],
      var.hosted_agent_definition.container_registry.role_assignment_mode
    )
    error_message = "container_registry.role_assignment_mode must be either `rbac` or `rbac-abac`."
  }
  validation {
    condition = !var.hosted_agent_definition.deploy || (
      trimspace(var.hosted_agent_definition.agent.name) != "" &&
      trimspace(var.hosted_agent_definition.agent.image) != "" &&
      can(regex("^sha256:[0-9a-f]{64}$", var.hosted_agent_definition.agent.version))
    )
    error_message = "Hosted-agent deployment requires a non-empty agent name and image plus an immutable sha256 digest."
  }
  validation {
    condition = (
      contains(["0.25", "0.5", "0.75", "1", "1.25", "1.5", "1.75", "2", "2.25", "2.5", "2.75", "3", "3.25", "3.5", "3.75", "4"], var.hosted_agent_definition.agent.runtime.cpu) &&
      contains(["0.5Gi", "1Gi", "1.5Gi", "2Gi", "2.5Gi", "3Gi", "3.5Gi", "4Gi", "4.5Gi", "5Gi", "5.5Gi", "6Gi", "6.5Gi", "7Gi", "7.5Gi", "8Gi"], var.hosted_agent_definition.agent.runtime.memory)
    )
    error_message = "Hosted-agent runtime must use a supported CPU value from 0.25 through 4 and memory value from 0.5Gi through 8Gi."
  }
  validation {
    condition = (
      length(var.hosted_agent_definition.agent.protocols) > 0 &&
      alltrue([
        for protocol in var.hosted_agent_definition.agent.protocols :
        contains(["responses", "invocations", "invocations_ws", "a2a"], protocol.protocol)
      ])
    )
    error_message = "Hosted-agent protocols must contain at least one supported protocol: responses, invocations, invocations_ws, or a2a."
  }
}
