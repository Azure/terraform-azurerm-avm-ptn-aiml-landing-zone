output "ai_foundry_account" {
  description = "Core details of the deployed Microsoft Foundry account, including authentication posture and service endpoints."
  value = {
    resource_id         = module.foundry_ptn.ai_foundry_id
    name                = module.foundry_ptn.ai_foundry_name
    account_endpoint    = local.foundry_account_endpoint
    openai_endpoint     = local.foundry_openai_endpoint
    local_auth_disabled = var.ai_foundry_definition.ai_foundry.disable_local_auth
    agent_service_id    = module.foundry_ptn.ai_agent_account_capability_host_id
  }
}

output "ai_foundry_byor_resource_ids" {
  description = "Resource IDs for Microsoft Foundry Bring Your Own Resource dependencies, including existing resources."
  value = {
    ai_search       = module.foundry_ptn.ai_search_id
    cosmos_db       = module.foundry_ptn.cosmos_db_id
    key_vault       = module.foundry_ptn.key_vault_id
    storage_account = module.foundry_ptn.storage_account_id
  }
}

output "ai_foundry_model_deployment_ids" {
  description = "Map of Microsoft Foundry model deployment resource IDs."
  value       = module.foundry_ptn.ai_model_deployment_ids
}

output "ai_foundry_projects" {
  description = "Map of Microsoft Foundry project details keyed by ai_foundry_definition.ai_projects."
  value = {
    for key, project in var.ai_foundry_definition.ai_projects : key => {
      resource_id                  = module.foundry_ptn.ai_foundry_project_id[key]
      name                         = module.foundry_ptn.ai_foundry_project_name[key]
      display_name                 = project.display_name
      description                  = project.description
      endpoint                     = local.foundry_project_endpoints[key]
      system_identity_principal_id = module.foundry_ptn.ai_foundry_project_system_identity_principal_id[key]
      agent_service_id             = try(module.foundry_ptn.ai_agent_service_id[key], null)
      dependency_resource_ids      = local.foundry_project_dependencies[key]
    }
  }
}

output "deploy_hosted_agent" {
  description = "Whether the returned handoff requests downstream Microsoft Foundry hosted-agent deployment."
  value       = var.hosted_agent_definition.deploy
}

output "hosted_agent_deployment" {
  description = "Typed infrastructure handoff for a downstream Microsoft Foundry hosted-agent deployment. No data-plane agent identity or version is created by this module."
  value = {
    enabled = var.hosted_agent_definition.deploy
    agent = var.hosted_agent_definition.deploy ? {
      name            = var.hosted_agent_definition.agent.name
      image           = local.hosted_agent_image_reference
      image_version   = var.hosted_agent_definition.agent.version
      startup_command = var.hosted_agent_definition.agent.startup_command
      runtime         = var.hosted_agent_definition.agent.runtime
      protocols       = var.hosted_agent_definition.agent.protocols
    } : null
    foundry = local.foundry_hosted_agent_enabled ? {
      project_resource_id      = try(module.foundry_ptn.ai_foundry_project_id[local.foundry_hosted_agent_project_key], null)
      project_endpoint         = try(local.foundry_project_endpoints[local.foundry_hosted_agent_project_key], null)
      project_principal_id     = try(module.foundry_ptn.ai_foundry_project_system_identity_principal_id[local.foundry_hosted_agent_project_key], null)
      agent_subnet_resource_id = try(local.subnet_ids["AIFoundrySubnet"], null)
    } : null
    container_registry = local.foundry_hosted_agent_enabled ? {
      resource_id          = local.hosted_agent_container_registry_resource_id
      endpoint             = local.hosted_agent_container_registry_endpoint
      role_assignment_mode = var.genai_container_registry_definition.deploy ? "rbac" : var.hosted_agent_definition.container_registry.role_assignment_mode
      pull_role_prepared   = var.genai_container_registry_definition.deploy
    } : null
    private_build = {
      required                 = local.foundry_hosted_agent_enabled
      subnet_resource_id       = local.foundry_hosted_agent_enabled ? try(local.subnet_ids["DevOpsBuildSubnet"], null) : null
      jumpbox_resource_id      = local.foundry_hosted_agent_enabled ? try(module.jumpvm[0].resource_id, null) : null
      acr_task_agent_pool_name = null
    }
  }
}

output "hosted_agent_prepared" {
  description = "Whether hosted-agent prerequisites were selected. This does not indicate that a hosted-agent version exists."
  value       = local.foundry_hosted_agent_enabled
}
