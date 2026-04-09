#TODO: determine what a good set of outpus should be and update.
output "resource_id" {
  description = "Future resource ID output for the LZA."
  value       = "tbd"
}

output "apim" {
  description = "The deployed API Management instance. Returns null when APIM is not deployed."
  value       = var.apim_definition.deploy ? module.apim[0] : null
}

output "foundry" {
  description = "The deployed AI Foundry pattern module outputs."
  value       = module.foundry_ptn
}
