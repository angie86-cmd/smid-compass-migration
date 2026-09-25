# Governance metadata applied to the Terraform state backend resources,
# for cost attribution/reporting and to identify Terraform-managed
# resources at a glance. environment = "shared" (not "dev"/"prod")
# because this backend infrastructure is not environment-specific: it
# stores state for every environment's workload (see terraform/backend.tf,
# where "key" is what varies per environment within this one backend).

locals {
  common_tags = {
    project      = "smid-compass"
    environment  = "shared"
    managed_by   = "terraform"
    organization = "save-my-identity"
    purpose      = "terraform-state"
  }
}
