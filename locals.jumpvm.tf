locals {
  jump_vm_name = try(var.jumpvm_definition.name, null) != null ? var.jumpvm_definition.name : (var.name_prefix != null ? "${var.name_prefix}-jump" : "ai-alz-jumpvm")
}
