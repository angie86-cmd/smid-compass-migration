# AzureRM is the sole/primary provider for this workload; no other cloud
# or SaaS provider is configured here.
#
# Authentication relies on the existing Azure CLI session (`az login`),
# not a service principal or stored secret. tenant_id/subscription_id
# pin the provider to the intended Save My Identity nonprofit tenant and
# subscription (see terraform/README.md, "Expected Azure context") so
# Terraform cannot silently target the wrong Azure context if the local
# CLI session ever points elsewhere. No client secrets, certificates, or
# other credentials are stored here or should ever be added to this file.

provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
