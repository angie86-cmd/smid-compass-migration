# Terraform CLI and provider version requirements for the SMID Compass
# nonprofit DEV foundation.
#
# The AzureRM constraint (~> 4.0) allows any 4.x release rather than
# pinning to one exact patch, so routine provider bugfixes/security
# updates can be picked up without editing this file. Reproducibility
# across machines/CI still comes from the committed
# .terraform.lock.hcl (see terraform/README.md), which records the exact
# resolved version — not from pinning here.

terraform {
  required_version = ">= 1.16.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
