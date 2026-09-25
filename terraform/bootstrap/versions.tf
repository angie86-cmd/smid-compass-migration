# Terraform CLI and provider version requirements for the SMID Compass
# remote state bootstrap. This is a separate Terraform root module from
# terraform/ (the main workload) — it has its own state, providers, and
# lock file, and is applied independently, before the main workload's
# backend can be configured.
#
# The AzureRM constraint (~> 4.0) is not pinned to one exact patch, for
# the same reason as the main workload (see terraform/versions.tf):
# reproducibility comes from this directory's own committed
# .terraform.lock.hcl, not from pinning here.

terraform {
  required_version = ">= 1.16.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
