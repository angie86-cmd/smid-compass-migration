# AzureRM provider configuration for the remote state bootstrap.
#
# Authentication relies on the existing Azure CLI session (`az login`).
# No client secrets, certificates, or other credentials are stored here
# or should ever be added to this file.
#
# storage_use_azuread = true ensures that if this provider instance ever
# performs a storage data-plane operation itself, it authenticates via
# Microsoft Entra ID rather than falling back to storage account keys —
# consistent with shared_access_key_enabled = false on the storage
# account in main.tf. In practice, the resources this configuration
# creates (storage account, container) go through the ARM control plane
# and do not require this setting, but it is kept as a safe default.
#
# This setting only affects this bootstrap provider's own behavior. It
# is unrelated to, and does not configure, authentication for the future
# `azurerm` backend block that the main workload configuration will use
# to read/write its state blob in this storage account: that backend
# configuration is defined separately, in the main workload directory,
# once this bootstrap has been applied.

provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  # If the AzureRM provider performs Storage Blob data-plane operations,
  # use Microsoft Entra ID rather than Shared Key authentication.
  # This setting applies to the provider only; authentication for the
  # Terraform remote backend is configured separately.
  storage_use_azuread = true
}
