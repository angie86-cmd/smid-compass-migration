# Terraform — SMID Compass Nonprofit DEV

Purpose: infrastructure as code for the SMID Compass nonprofit DEV environment (Save My Identity nonprofit Azure tenant).

## Current phase

**Terraform foundation.** Already deployed and applied:

- Resource Group
- Remote Terraform state (Azure Blob Storage)
- Log Analytics Workspace
- Application Insights
- Microsoft Foundry resource and Microsoft Foundry project

Prepared in this change, **not yet applied** (pending manual review, `terraform plan`, and `terraform apply`):

- `gpt-4.1-mini` model deployment (source-parity)
- `text-embedding-3-small` model deployment (source-parity)
- Foundry User RBAC for the current developer identity, scoped to the Foundry resource
- Foundry User RBAC for the Foundry project's managed identity, scoped to the Foundry resource
- DEV Cost Management budget and threshold notifications for `rg-smid-compass-dev`

Once this batch is reviewed, planned, and applied, the Terraform foundation is considered complete. The next major phase is application/data-plane restoration: knowledge/vector stores → agents → tools → workflow → parity validation (outside this Terraform configuration).

Agents, knowledge/vector stores, and workflows are not part of this Terraform configuration at any point — see [Connections](#connections) below.

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

## Model deployments

`gpt-4.1-mini` and `text-embedding-3-small` are deployed directly on the Foundry resource (`azurerm_cognitive_deployment`), preserving source parity exactly: same model versions, `GlobalStandard` SKU, capacity, RAI policy (`Microsoft.DefaultV2`), and version upgrade option as `source/azure/deployments/*.raw.json`. Capacity is intentionally not optimized during this migration step.

## RBAC

The Foundry resource grants the **Foundry User** role (referenced by its stable role definition ID, since Foundry role display names are currently undergoing a rename rollout) to:

- The current developer's authenticated principal.
- The Foundry project's own system-assigned managed identity.

This is the minimum access needed for the next application-layer migration step (agent import, knowledge upload). It intentionally does not grant Owner, Contributor, Foundry Owner, or Foundry Account Owner — the signed-in user already has subscription Owner for management operations, and this assignment is only for Foundry data-plane/development access. No additional role is granted to the Foundry resource's own managed identity.

## Connections

Based on the frozen source inventory (`source/inventory/source-environment.json`, `source/inventory/source-manifest.yaml`), the source environment had no external Azure AI Search, no dedicated external storage account, no Foundry IQ Knowledge Base, and no external/MCP tooling. Accordingly, **no infrastructure-level Foundry connection resource is created** in this Terraform configuration:

- The Web Search tool used by `SMID-SafetyAgent` does not require a dedicated Bing resource or project connection at the infrastructure level.
- File Search vector stores and uploaded knowledge files are restored in the later application/data-plane migration step, not here.
- Models are deployed directly on the parent Foundry resource; no remote model connection is created.

Agent and tool configuration (which agent uses which tool) is application-layer configuration, not part of this Terraform foundation.

## Cost budget

A monthly Azure Cost Management budget (`azurerm_consumption_budget_resource_group`) is scoped to `rg-smid-compass-dev`, with email notifications at 50%, 80%, and 100% of actual (not forecasted) spend, sent directly by the budget resource (no Action Group — the automatically created "Application Insights Smart Detection" Action Group is unrelated and is not reused for cost governance).

**A budget alert does NOT stop resources or impose a hard spending cap.** It only provides cost monitoring and notifications. `monthly_budget_amount` and `budget_start_date` have no defaults and must be supplied (see `dev.tfvars.example`) before `terraform plan` will succeed.

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
