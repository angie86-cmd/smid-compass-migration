# Terraform — SMID Compass Nonprofit DEV

Purpose: infrastructure as code for the SMID Compass nonprofit DEV environment (Save My Identity nonprofit Azure tenant).

## Current phase

**Terraform foundation only.** This configuration currently defines only Terraform/provider requirements, variables, and locals. No Azure resources are declared yet (see `main.tf`). Resources will be introduced incrementally after this foundation is reviewed and validated.

## Deployment strategy

Migrate first → validate parity → modernize later.

See [../docs/architecture/target-migration-architecture-v1.md](../docs/architecture/target-migration-architecture-v1.md) and [../docs/plans/nonprofit-migration-plan-v1.md](../docs/plans/nonprofit-migration-plan-v1.md).

## Authentication

Azure CLI authentication using the currently authenticated Save My Identity nonprofit account (`az login`). No client secrets, certificates, or other credentials are stored in this configuration.

## Expected Azure context

| | |
|---|---|
| Tenant | `48cb7850-a5c9-4632-9dbd-eccda8b8b9bb` |
| Subscription | `a5bc333b-cd24-4c66-95e0-18013949c94f` |
| Region | `swedencentral` |

## Local prerequisites

- Terraform >= 1.16.0
- Azure CLI
- Azure CLI authenticated to the correct nonprofit tenant/subscription (`az account show` to verify)

## Usage

```
cp dev.tfvars.example dev.tfvars   # dev.tfvars is git-ignored
terraform init
terraform fmt -recursive
terraform fmt -check -recursive
terraform validate
```

**Do NOT run `terraform plan` or `terraform apply` during this foundation-only step.** Those commands are only appropriate once Azure resources have been added and reviewed.

## File tracking notes

**`.terraform.lock.hcl` is committed.** It pins resolved provider versions, giving every contributor and CI run the same provider version and a reproducible `terraform init`.

**`*.tfstate` files must never be committed.** State can contain infrastructure metadata and sensitive values, and requires controlled storage and access (e.g. a remote backend), not source control.

**Credentials are never stored in these files.** Local development authenticates through the Azure CLI session; `tenant_id` and `subscription_id` are identifiers, not credentials, and are the only Azure context values checked in via `dev.tfvars.example`.
