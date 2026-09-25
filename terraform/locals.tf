# Minimal naming and tagging foundation. Names are derived deterministically
# from var.project_name/var.environment rather than hard-coded per resource,
# so the whole workload's naming stays consistent and environment-aware if
# this configuration is ever reused for another environment (e.g. prod).
# Deliberately simple: no enterprise naming-convention module, since this
# workload is small enough that convention-over-configuration is enough.

locals {
  project     = var.project_name
  environment = var.environment

  # Governance metadata applied to every resource for cost
  # attribution/reporting and to identify Terraform-managed resources at
  # a glance in the Azure portal.
  common_tags = {
    project      = local.project
    environment  = local.environment
    managed_by   = "terraform"
    organization = "save-my-identity"
  }

  log_analytics_name = "log-${local.project}-${local.environment}"
  app_insights_name  = "appi-${local.project}-${local.environment}"

  # foundry_resource_name carries a fixed uniqueness suffix (a5bc33, from
  # the nonprofit subscription ID) because the Foundry resource's custom
  # subdomain must be globally unique across Azure, unlike the other
  # resource names above which only need to be unique within this
  # resource group.
  foundry_resource_name = "smid-compass-dev-a5bc33"
  # foundry_project_name intentionally matches the source tenant's
  # project name ("smid-compass") for source-name parity, unlike the
  # other names here which are newly introduced during migration.
  foundry_project_name = "smid-compass"

  budget_name = "budget-${local.project}-${local.environment}"
}
