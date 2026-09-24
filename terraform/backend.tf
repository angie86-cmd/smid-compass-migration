# Remote state backend for the main SMID Compass DEV workload.
#
# State is stored in Azure Blob Storage rather than on the developer
# workstation, so it survives machine loss and can be shared safely
# between contributors and future CI/CD runs. Local development
# authenticates using Microsoft Entra ID through the existing Azure CLI
# session (use_cli/use_azuread_auth); no storage account keys or other
# credentials are stored in this file or anywhere in the repository.
#
# This backend infrastructure (resource group, storage account,
# container, and the RBAC role assignment that authorizes access to it)
# is provisioned separately by terraform/bootstrap/ and is intentionally
# not managed by this workload configuration.
#
# Backend blocks cannot reference variables, so the values below are
# literal, matching terraform/bootstrap/bootstrap.tfvars.example.
terraform {
  backend "azurerm" {
    use_cli          = true
    use_azuread_auth = true

    tenant_id       = "48cb7850-a5c9-4632-9dbd-eccda8b8b9bb"
    subscription_id = "a5bc333b-cd24-4c66-95e0-18013949c94f"

    resource_group_name  = "rg-smid-tfstate"
    storage_account_name = "stsmidtfstatea5bc33"
    container_name       = "tfstate"
    key                  = "smid-compass-dev.tfstate"
  }
}
