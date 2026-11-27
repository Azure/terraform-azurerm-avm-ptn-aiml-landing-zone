output "public_ip_prefix_value" {
  description = "The public IP prefix CIDR. This focused module does not create a public IP prefix."
  value       = null
}

output "public_ip_resource" {
  description = "A map containing the public IP resource."
  value = {
    primary = azapi_resource.public_ip
  }
}

output "resource" {
  description = "The NAT Gateway resource."
  value       = azapi_resource.this
}

output "resource_id" {
  description = "The resource ID of the NAT Gateway."
  value       = azapi_resource.this.id
}
