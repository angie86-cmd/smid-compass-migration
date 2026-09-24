# Terraform Bootstrap — SMID Compass Remote State

This configuration bootstraps the Azure backend (resource group, storage account, blob container) used to store Terraform remote state for the main SMID Compass workload configuration (`terraform/`).

## State strategy

This bootstrap configuration itself uses **local state**. It only exists to create the storage account and container; it does not consume them as its own backend, avoiding a circular dependency.

After this bootstrap is applied and reviewed, the main workload configuration's state will be migrated from local state to the Azure Blob Storage backend it creates here (future workload state blob key: `smid-compass-dev.tfstate`).

## Authentication

Microsoft Entra ID / Azure CLI authentication (`az login`) is used for both the AzureRM provider and storage data-plane operations (`storage_use_azuread = true` in `providers.tf`). No storage account keys or other credentials are stored in this configuration, and the storage account itself has shared key access disabled (`shared_access_key_enabled = false`).

## Access control

The current authenticated principal is granted **Storage Blob Data Contributor**, scoped to the `tfstate` container, so it can read and write state blobs. This is required because the storage account has no key-based access; all data-plane operations (including future `terraform init`/`plan`/`apply` runs against the remote backend) go through Entra ID and require this role.

## Network access

`public_network_access_enabled = true` is set temporarily to support local development, where Terraform runs from a developer machine without a private network path to the storage account. Network hardening (private endpoints, IP allow-listing, or disabling public access once CI/CD or a private connectivity path exists) can be evaluated later, outside the scope of this bootstrap.

## Prerequisites

- Terraform >= 1.16.0
- Azure CLI
- Azure CLI authenticated to the correct nonprofit tenant/subscription

## Usage

```
cp bootstrap.tfvars.example bootstrap.tfvars   # bootstrap.tfvars is git-ignored
terraform init
terraform fmt -recursive
terraform fmt -check -recursive
terraform validate
terraform plan -var-file="bootstrap.tfvars"
```

**Do NOT run `terraform apply` yet.** This bootstrap has not been applied; the plan above is for review only, prior to manual approval.
