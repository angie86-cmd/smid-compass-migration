# Terraform — SMID Compass Nonprofit DEV

Purpose: infrastructure as code for the SMID Compass nonprofit DEV environment (Save My Identity nonprofit Azure tenant).

## Current phase

**Terraform foundation only.** The DEV foundation currently contains:

- Resource Group
- Log Analytics Workspace
- Application Insights (connected to the Log Analytics Workspace)
- Azure Blob remote Terraform state

Microsoft Foundry, model deployments, identities/RBAC, and budgets/alerts have not been added yet. Resources continue to be introduced incrementally, reviewed and validated at each step.

## Deployment strategy

Migrate first → validate parity → modernize later.

See [../docs/architecture/target-migration-architecture-v1.md](../docs/architecture/target-migration-architecture-v1.md) and [../docs/plans/nonprofit-migration-plan-v1.md](../docs/plans/nonprofit-migration-plan-v1.md).

## Authentication

Azure CLI authentication using the currently authenticated Save My Identity nonprofit account (`az login`). No client secrets, certificates, or other credentials are stored in this configuration.

## State backend

State is stored remotely in Azure Blob Storage (`backend.tf`), not locally, using Microsoft Entra ID authentication through the Azure CLI (`use_cli` / `use_azuread_auth`). No storage keys or credentials are stored in the repository.

| | |
|---|---|
| Backend resource group | `rg-smid-tfstate` |
| Storage account | `stsmidtfstatea5bc33` |
| Container | `tfstate` |
| State key | `smid-compass-dev.tfstate` |
| Authentication | Microsoft Entra ID + Azure CLI |

[`terraform/bootstrap/`](bootstrap/) creates this backend infrastructure (resource group, storage account, container, and the RBAC role granting access to it). This `terraform/` configuration only *uses* that backend to store the SMID Compass workload's own state — the two configurations are intentionally separate, so the backend is never at risk of being modified or destroyed by the workload it stores state for.

## Observability

- **Log Analytics Workspace** (`log-smid-compass-dev`) is the central workspace for collecting and querying operational logs and telemetry across the DEV environment.
- **Application Insights** (`appi-smid-compass-dev`) provides application-level observability: requests, failures, dependencies, traces, and performance data.
- Application Insights is linked to the Log Analytics Workspace (workspace-based mode), so observability data can be analyzed centrally.
- These are freshly provisioned nonprofit-tenant resources, distinct from the source tenant's own Application Insights/Log Analytics instances — consistent with the Target Migration Architecture v1 principle of never cloning historical IDs or configuration.
- The observability layer is deployed before Foundry resources so monitoring and troubleshooting are available from the start of the workload build-out.

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
