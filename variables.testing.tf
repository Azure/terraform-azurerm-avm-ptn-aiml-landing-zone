/*
variable "flag_standalone" {
  type = object({
    deploy_build_resources = optional(bool, false) #TODO: create a validation rule that only allows this to be true if the platform landing zone is also being deployed
    testing_config = optional(object({
      tfvars_filename = optional(string, "test.auto.tfvars")
    }), {})
  })
  default = {
    deploy_build_resources = false
    testing_config = {
      tfvars_filename = "test.auto.tfvars"
    }
  }
  description = <<DESCRIPTION
Configuration object for standalone deployment and testing options.

- `deploy_build_resources` - (Optional) Whether to deploy build resources in standalone mode. Default is false. Note: This should only be set to true if the platform landing zone is also being deployed.
- `testing_config` - (Optional) Testing configuration options.
  - `tfvars_filename` - (Optional) The filename for the test Terraform variables file. Default is "test.auto.tfvars".
DESCRIPTION
}
*/
