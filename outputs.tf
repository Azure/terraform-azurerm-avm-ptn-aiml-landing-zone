output "apim" {
  description = "Details of the deployed APIM instance."
  value       = try(module.apim[0], null)
}

#TODO: determine what a good set of outpus should be and update.
output "resource_id" {
  description = "Future resource ID output for the LZA."
  value       = "tbd"
}
