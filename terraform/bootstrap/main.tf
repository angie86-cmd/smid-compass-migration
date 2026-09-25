# Bootstraps the Azure backend used to store Terraform remote state for
# the SMID Compass nonprofit environment, solving the usual chicken-and-egg
# "backend bootstrap" problem: the storage account/container a remote
# backend needs cannot itself be created using that same remote backend,
# so this separate root module creates them using local state, one time,
# before the main workload configuration (terraform/) can point its own
# backend at them. This bootstrap configuration's own state stays local
# permanently — only the storage account/container it creates is used as
# a remote backend, and only by the main workload, never by this module.
#
# Provisioning here (resource group, storage account, container) goes
# through the Azure Resource Manager (ARM) control plane only. The blob
# data plane — which is what actually reads/writes state files — is not
# touched by this configuration and is not needed to create these
# resources; it only comes into play later, when the main workload
# configuration authenticates to the backend to read/write its state
# blob. The Storage Blob Data Contributor role assignment below exists
# to authorize that later, separate data-plane access.

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}

resource "azurerm_storage_account" "tfstate" {
  name                = var.storage_account_name
  resource_group_name = azurerm_resource_group.tfstate.name
  location            = azurerm_resource_group.tfstate.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  # Data-plane access is authenticated via Microsoft Entra ID; storage
  # account keys are disabled and never used.
  default_to_oauth_authentication = true
  shared_access_key_enabled       = false

  # Temporarily enabled for local development during the bootstrap phase.
  # Network hardening (e.g. private endpoints, IP allow-listing) can be
  # evaluated once the workload moves beyond local Terraform runs.
  public_network_access_enabled = true

  tags = local.common_tags
}

# storage_account_id (an ARM resource ID) is used deliberately instead of
# the deprecated storage_account_name argument. In AzureRM v4 this makes
# Terraform create the container through the ARM control plane, the same
# way the storage account itself is created above. No blob data-plane
# permissions are required to create this container, so there is no
# bootstrap circular dependency: the role assignment below (which grants
# the data-plane access needed later) can safely depend on this resource.
resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# Grants the current authenticated principal (the identity running
# Terraform) the Storage Blob Data Contributor role, which is required
# for data-plane access (reading/writing the state blob) once the main
# workload configuration switches to this storage account/container as
# its remote backend — plain ARM permissions on the storage account are
# not sufficient for that, since shared_access_key_enabled is false and
# all data-plane access goes through Microsoft Entra ID.
#
# The scope is intentionally the container (via azurerm_storage_container
# .tfstate.id, a proper ARM resource ID in AzureRM v4), not the storage
# account, to grant only the minimum access this workload needs.
#
# Azure RBAC assignments are not always instantly effective: there can be
# a short propagation delay (typically well under a few minutes) after
# apply before the principal can actually read/write blobs in this
# container. If the first backend init/plan against this container fails
# with an authorization error immediately after applying this bootstrap,
# retry after a short wait rather than assuming the assignment is wrong.
resource "azurerm_role_assignment" "tfstate_blob_contributor" {
  scope                = azurerm_storage_container.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
