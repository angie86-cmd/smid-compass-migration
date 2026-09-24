# Common tags applied to the Terraform state backend resources.

locals {
  common_tags = {
    project      = "smid-compass"
    environment  = "shared"
    managed_by   = "terraform"
    organization = "save-my-identity"
    purpose      = "terraform-state"
  }
}
