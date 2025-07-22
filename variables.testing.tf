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
}
