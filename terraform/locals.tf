# Minimal naming and tagging foundation. Resource-specific naming will be
# added incrementally as infrastructure is introduced in main.tf.

locals {
  project     = var.project_name
  environment = var.environment

  common_tags = {
    project      = local.project
    environment  = local.environment
    managed_by   = "terraform"
    organization = "save-my-identity"
  }
}
