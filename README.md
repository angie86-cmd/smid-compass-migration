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

Source snapshot: **COMPLETE** / frozen at `source-snapshot-v1`

Current phase: Target Migration Architecture v1

Strategy: migrate → validate parity → modernize

Next phase: nonprofit tenant preflight

See [docs/architecture/target-migration-architecture-v1.md](docs/architecture/target-migration-architecture-v1.md) and [docs/plans/nonprofit-migration-plan-v1.md](docs/plans/nonprofit-migration-plan-v1.md).

## Repository rules

Files under source/ represent the original tenant and should not be edited to make them suitable for the target environment.

Target-specific or cleaned configurations must be created separately later.

Terraform state and secrets must never be committed.
