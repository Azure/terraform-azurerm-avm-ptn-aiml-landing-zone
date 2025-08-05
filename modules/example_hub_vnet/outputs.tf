output "dns_resolver_inbound_ip_addresses" {
  description = "The inbound IP address of the DNS resolver in the hub virtual network"
  value       = module.private_resolver.inbound_endpoint_ips
}

output "firewall_ip_address" {
  description = "The IP address of the Azure Firewall in the hub virtual network"
  value       = module.firewall.resource.ip_configuration[0].private_ip_address
}

output "resource_group_resource_id" {
  description = "The resource ID of the resource group where the hub virtual network is deployed"
  value       = azurerm_resource_group.this.id
}

output "resource_id" {
  description = "Duplicating the vnet resource ID output to keep the linter happy."
  value       = ""
}

output "virtual_network_resource_id" {
  description = "Azure Resource ID for the hub virtual network"
  value       = module.ai_lz_vnet.resource_id
}
