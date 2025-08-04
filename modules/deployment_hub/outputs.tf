output "resource_id" {
  description = "Future resource ID output for the LZA."
  value       = ""
}

output "virtual_network_resource_id" {
  description = "Azure Resource ID for the hub virtual network"
  value       = module.ai_lz_vnet.resource_id
}
