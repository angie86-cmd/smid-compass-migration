# Configuration interface for this bootstrap root module. All values are
# supplied via bootstrap.tfvars (git-ignored; see bootstrap.tfvars.example)
# and default to the single, already-provisioned backend infrastructure
# this bootstrap manages — there is normally only one of these per tenant,
# unlike the main workload which is expected to be reused per environment.

# --- Azure target context ---------------------------------------------
# Identifies which Azure tenant/subscription/region this bootstrap
# targets. tenant_id/subscription_id are identifiers, not credentials,
# and have no defaults so this configuration can never silently target
# the wrong tenant.

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID for the Save My Identity nonprofit tenant. Not a credential; identifies which tenant the provider targets. No default: must be supplied explicitly."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID for the Save My Identity nonprofit tenant. Not a credential; identifies which subscription the provider targets. No default: must be supplied explicitly."
}

variable "location" {
  type        = string
  description = "Azure region for the Terraform state backend (resource group, storage account, container). Configuration value; defaults to the region of the already-provisioned backend infrastructure and normally does not need to be overridden."
  default     = "swedencentral"
}

# --- Backend infrastructure naming --------------------------------------
# Name the resource group/storage account/container this bootstrap
# manages. All three default to the single backend instance already
# deployed for this tenant; overriding them only makes sense if bootstrap
# is deliberately re-run to create a separate backend.

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group holding the Terraform state storage account. Configuration value; defaults to the already-provisioned backend resource group."
  default     = "rg-smid-tfstate"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account used as the Terraform remote state backend. Must be globally unique across Azure (storage account names share a DNS namespace). Configuration value; defaults to the already-provisioned backend storage account."
  default     = "stsmidtfstatea5bc33"
}

variable "container_name" {
  type        = string
  description = "Name of the blob container used to store Terraform state files. One container holds the state blobs for every environment (see terraform/backend.tf, where \"key\" distinguishes environments). Configuration value; defaults to the already-provisioned backend container."
  default     = "tfstate"
}
