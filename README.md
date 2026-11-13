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

Last status refresh: **2026-11-13**

Source snapshot: **COMPLETE** — frozen at `source-snapshot-v1`

Target Migration Architecture v1: **COMPLETE / APPROVED**

Nonprofit tenant preflight: **COMPLETE / PASSED**

Terraform DEV foundation: **COMPLETE / VALIDATED**

Application-layer restoration status:
- Phase 5 knowledge reconstruction: **COMPLETE**
- 10 Agent Service files uploaded and mapped to new target IDs
- 3 target vector stores created with source-parity memberships and static 800/400 chunking
- `LOPNA 2015.pdf` reproduces its historical source ingestion failure in the legacy vector store (expected parity condition)
- Phase 6 agent reconstruction: **COMPLETE** — six prompt agents live and enabled/active in nonprofit DEV (`SMID-RouterAgent` v2, `SMID-PassGuide` v1, `SMID-WorkshopGuide` v1, `SMID-SafetyAgent` v1, `OutOfScopeAgent` v1, `smid-compass-agent` v1)
- Phase 7 workflow reconstruction: **COMPLETE** — `SMID-compass-workflow` live, enabled/active, routing verified to match source exactly
- Phase 8 parity validation: **COMPLETE — PARITY SMOKE TEST PASSED** — see [docs/validation/phase-8-parity-validation.md](docs/validation/phase-8-parity-validation.md)
- Phase 9 baseline freeze: **COMPLETE (documentation)** — nonprofit parity baseline validated; Git tag `nonprofit-parity-v1` to be created manually

## Migration status overview

- Phase 0 — Source preservation: **COMPLETE**
- Phase 1 — Target architecture: **COMPLETE**
- Phase 2 — Nonprofit preflight: **COMPLETE**
- Phase 3 — Terraform foundation: **COMPLETE**
- Phase 4 — DEV infrastructure deployment: **COMPLETE**
- Phase 5 — Knowledge reconstruction: **COMPLETE**
- Phase 6 — Agent reconstruction: **COMPLETE**
- Phase 7 — Workflow reconstruction: **COMPLETE**
- Phase 8 — Parity validation: **COMPLETE / PARITY SMOKE TEST PASSED**
- Phase 9 — Freeze nonprofit parity baseline: **COMPLETE**

The migration-to-parity milestone is complete. The next technical work is **Modernization v2 — Microsoft Agent Framework migration in DEV** (Phase 11); it has not started. The validated parity baseline is the reference point for that work and must remain unmodified until modernization explicitly branches from it.

Current phase: **Awaiting manual Git freeze (`nonprofit-parity-v1` tag); next engineering phase is Modernization v2**

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

Phase 5 completed on **2026-11-06**. Live results:
- `smid-passguide`: 3/3 completed
- `smid-workshopguide`: 2/2 completed
- `smid-compass-agent-legacy`: 7 completed / 1 failed, where the failed membership is `LOPNA 2015.pdf`, matching the historical source failure
- all target File Search memberships use static chunking with `max_chunk_size_tokens: 800` and `chunk_overlap_tokens: 400`
- current Foundry live behavior required Agent Service `file_id` attachments; Dataset `data_source` attachments were rejected on this deployment
- the Embajada PDF required an ASCII-safe upload filename (`EmbajadaBerlin_ascii.pdf`) because the live Files API returned HTTP 500 for the original non-ASCII multipart filename; file content remained byte-identical

Phase 6 completed on **2026-11-13**. Live results:
- all six agents created via `POST {PROJECT_ENDPOINT}/agents?api-version=v1`, no additional authentication/feature-flag/preview-header required
- `SMID-RouterAgent`, `SMID-PassGuide`, `SMID-WorkshopGuide`, `SMID-SafetyAgent`, `OutOfScopeAgent`, `smid-compass-agent` all live, `enabled`/`active`
- `SMID-RouterAgent` is at **target runtime version 2**, not 1 — a version-2 definition was created locally via `POST /agents/SMID-RouterAgent?api-version=v1` to correct a UTF-8 extraction defect in the initial version-1 instructions text (mojibake on non-ASCII arrow characters, introduced by local tooling, not by the API). Version 2 was verified field-for-field identical to the prepared manifest. This is a target-side runtime/versioning artifact only — it does not reflect, and is not expected to match, the source agent's version number (source `SMID-RouterAgent` was version 9). No source version numbers are reused or expected to match target version numbers for any of the six agents.
- all intentional source asymmetries preserved exactly: `OutOfScopeAgent` has no RAI guardrail association; `SMID-SafetyAgent` has no `temperature`/`top_p`/`tool_choice`/`text` fields (absent, not defaulted by the platform)
- no unexpected schema normalization observed on any agent

Phase 7 completed on **2026-11-13**. Live results:
- `SMID-compass-workflow` created via the same `POST {PROJECT_ENDPOINT}/agents?api-version=v1` endpoint, using `kind: workflow` and the required preview header `Foundry-Features: WorkflowAgents=V1Preview` (value independently confirmed against the current Foundry TypeSpec, not assumed)
- live identity: `SMID-compass-workflow:1`, version `1`, `enabled`/`active`, `draft: false`
- the live `definition.workflow` string matched `target/migration/workflow/SMID-compass-workflow.yaml` exactly (byte-for-byte), and all five referenced agents (`SMID-RouterAgent` v2, `SMID-PassGuide` v1, `SMID-WorkshopGuide` v1, `SMID-SafetyAgent` v1, `OutOfScopeAgent` v1) resolved correctly
- routing preserved exactly, including that `OutOfScopeAgent` bypasses `SMID-SafetyAgent`, and that `SMID-SafetyAgent` still receives answer-only input (the known `<route> | <answer>` mismatch), per the migrate-first/modernize-later strategy
- no modernization performed; Microsoft Foundry declarative workflows are scheduled for retirement on 2026-12-01, but this does not invalidate the parity restoration — migration to Microsoft Agent Framework remains deferred to the later modernization phase, after the nonprofit parity baseline is validated

Phase 8 completed on **2026-11-13**. A migration parity smoke validation — not exhaustive product QA — proving the nonprofit migration works end-to-end before modernization. Result: **PARITY SMOKE TEST PASSED**, all 6 tests passed (Passport/Workshop/Out-of-scope × Spanish/German). Full evidence: [docs/validation/phase-8-parity-validation.md](docs/validation/phase-8-parity-validation.md). Key verified facts:
- Router classifies correctly in both Spanish and German.
- Passport routes to `SMID-PassGuide`, Workshop routes to `SMID-WorkshopGuide`, both with successful File Search execution against their migrated vector stores.
- `SMID-SafetyAgent` executes after the passport/workshop paths; `OutOfScopeAgent` bypasses it, exactly as in source.
- The workflow reaches `End` successfully in all 6 cases, with no migrated-resource reference errors.
- `SMID-PassGuide`/`SMID-WorkshopGuide`/`SMID-SafetyAgent` bilingual (ES+DE) responses and `OutOfScopeAgent`'s single-input-language responses both match their respective source instructions exactly.
- Invocation mechanism: `POST openai/v1/conversations` then `POST openai/v1/responses` with `agent_reference: {type: "agent_reference", name: "SMID-compass-workflow"}` and header `Foundry-Features: WorkflowAgents=V1Preview`.
- During Phase 8, the live workflow was observed at version 3 (Phase 7 had observed version 1); versions 2 and 3 contain comment-only differences, with the functional workflow YAML remaining equivalent to the validated parity definition. This is target-side versioning behavior with no functional parity impact; it was not modified or downgraded.

Phase 9 completed (documentation) on **2026-11-13**: the source-parity migration is reconstructed, end-to-end parity smoke validation passed, validation evidence is stored in the repository, and this repository state represents the validated nonprofit parity baseline. The Git tag `nonprofit-parity-v1` marking this baseline is to be created manually (not created by this update).

Current technical objective: begin **Modernization v2 — Microsoft Agent Framework migration in DEV** (not started yet). No PROD deployment beyond the Phase 10 pilot sequencing already defined, and no further parity migration work, is expected before that.

See [docs/architecture/target-migration-architecture-v1.md](docs/architecture/target-migration-architecture-v1.md), [docs/plans/nonprofit-migration-plan-v1.md](docs/plans/nonprofit-migration-plan-v1.md), [target/migration/README.md](target/migration/README.md), and [docs/preflight/nonprofit-preflight.md](docs/preflight/nonprofit-preflight.md).

## Repository rules

Files under source/ represent the original tenant and should not be edited to make them suitable for the target environment.

Target-specific or cleaned configurations must be created separately later.

Terraform state and secrets must never be committed.
