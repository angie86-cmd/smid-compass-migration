# SMID Compass Migration

SMID Compass is a Microsoft Foundry multi-agent solution being migrated from a private Azure tenant to the Save My Identity nonprofit Azure tenant.

This repository serves two purposes:

1. Preserve an immutable source snapshot of the existing Microsoft Foundry implementation.
2. Build a reproducible target environment for the nonprofit tenant using Infrastructure as Code.

## Source architecture

Current known source components:

- Microsoft Foundry resource: smid-compass-resource
- Microsoft Foundry project: smid-compass
- Region: Sweden Central
- Application Insights
- Log Analytics Workspace

Model deployments:
- gpt-4.1-mini
  - version: 2025-04-14
  - deployment type: Global Standard
- text-embedding-3-small
  - version: 1
  - deployment type: Global Standard

Agents:
- SMID-RouterAgent
- SMID-PassGuide
- SMID-WorkshopGuide
- OutOfScopeAgent
- SMID-SafetyAgent
- smid-compass-agent (legacy prototype; migration decision pending)

Workflow:
- SMID-compass-workflow

Guardrail:
- SMID-Guardrails-Policy

Knowledge/Data:
- PDF files uploaded directly to Microsoft Foundry agents
- No external Azure AI Search resource identified
- No external Storage account identified for this project
- No Foundry IQ Knowledge Base configured
- No Memory configured
- No additional Services configured
- No MCP/API tools configured
- No Fine-tuning configured
- No Evaluations requiring migration identified

## Migration principle

The private tenant will remain untouched until the nonprofit development environment has been recreated and validated.

The migration strategy is:

Source inventory
→ Source configuration backup
→ Terraform target architecture
→ Nonprofit DEV deployment
→ Agent/data recreation
→ Workflow modernization
→ Testing and validation
→ Production deployment

Do not assume source resource IDs, endpoints, client IDs, principal IDs, agent GUIDs, blueprint IDs or API keys can be reused in the target tenant.

## Current migration status

Last status refresh: **2026-11-04**

Source snapshot: **COMPLETE** — frozen at `source-snapshot-v1`

Target Migration Architecture v1: **COMPLETE / APPROVED**

Nonprofit tenant preflight: **COMPLETE / PASSED**

Terraform DEV foundation: **COMPLETE / VALIDATED**

Application-layer restoration artifacts: **PREPARED / NOT YET EXECUTED**
- 10 referenced knowledge files mapped for target upload
- 3 target vector-store specifications prepared
- 6 agent manifests prepared
- target guardrail/RAI policy artifact prepared
- source-parity workflow manifest and YAML prepared

Current phase: **PHASE 5 — KNOWLEDGE RECONSTRUCTION**

Strategy: migrate → validate parity → modernize

Work resumed on **2026-11-04** after a pause of approximately one month.

Phase 4 infrastructure validation is now complete. Validation confirmed:
- correct nonprofit tenant and subscription context
- `gpt-4.1-mini` deployment: version `2025-04-14`, GlobalStandard, capacity 50
- `text-embedding-3-small` deployment: version `1`, GlobalStandard, capacity 120
- `SMID-Guardrails-Policy` present with expected Prompt/Completion filters and Prompt-side Jailbreak protection
- Foundry project system-assigned managed identity present
- required Foundry User RBAC assignments present
- Application Insights and Log Analytics healthy and linked
- DEV budget present at 50 EUR/month with enabled 50%, 80%, and 100% actual-spend notifications

Current technical objective:
1. Execute Phase 5 knowledge reconstruction: upload the 10 referenced source files and create the 3 target vector stores using new target IDs.
2. Continue with agent restoration, then workflow restoration.
3. Run parity validation and freeze the validated nonprofit baseline as `nonprofit-parity-v1`.

No PROD deployment or Modernization v2 work should begin before parity validation is accepted.

See [docs/architecture/target-migration-architecture-v1.md](docs/architecture/target-migration-architecture-v1.md), [docs/plans/nonprofit-migration-plan-v1.md](docs/plans/nonprofit-migration-plan-v1.md), [target/migration/README.md](target/migration/README.md), and [docs/preflight/nonprofit-preflight.md](docs/preflight/nonprofit-preflight.md).

## Repository rules

Files under source/ represent the original tenant and should not be edited to make them suitable for the target environment.

Target-specific or cleaned configurations must be created separately later.

Terraform state and secrets must never be committed.
