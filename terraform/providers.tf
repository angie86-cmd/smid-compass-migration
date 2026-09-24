# AzureRM provider configuration.
#
# Authentication relies on the existing Azure CLI session (`az login`).
# No client secrets, certificates, or other credentials are stored here
# or should ever be added to this file.

provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
