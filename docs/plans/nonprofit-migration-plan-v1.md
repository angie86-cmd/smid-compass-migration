# SMID Compass — Nonprofit Migration Plan v1

Incremental phases for reconstructing SMID Compass in the Save My Identity nonprofit Azure tenant, following the architecture in [target-migration-architecture-v1.md](../architecture/target-migration-architecture-v1.md).

Strategy: **migrate first, validate parity, modernize later.** Migration and modernization are kept as separate phases (see Phase 10).

## Phase 0 — Source preservation

Status: **COMPLETE**

Evidence: `source-snapshot-v1` (finalization commit `90e43db8fcfd934a04a31d752c9b21c5867c8212`)

Do not reopen unless evidence is later found to be missing.

## Phase 1 — Target architecture

Status: **CURRENT**

Tasks:

- Document parity architecture.
- Document migration boundaries.
- Separate migration from modernization.
- Approve Target Migration Architecture v1.

Exit criterion: architecture approved before Terraform implementation.

## Phase 2 — Nonprofit preflight

No deployment yet. Verify:

- Correct nonprofit tenant
- Correct Azure subscription
- User permissions
- Terraform deployment permissions
- Required Azure resource providers
- Microsoft Foundry availability
- `swedencentral` support
- `gpt-4.1-mini` availability/version
- `text-embedding-3-small` availability/version
- Quota/capacity
- Foundry project capability
- File Search availability
- Web Search availability
- Guardrail capability
- Current workflow/orchestration capability
- Application Insights
- Log Analytics

Output: `docs/preflight/nonprofit-preflight.md` — not created yet; it will be produced during Phase 2.

Exit criterion: target region and required services confirmed.

## Phase 3 — Terraform foundation

Only after Phase 2 passes.

Create Terraform for infrastructure required by DEV. Expected scope:

- Resource group
- Foundry resource
- Foundry project
- Model deployments
- Application Insights
- Log Analytics
- Identities
- RBAC
- Budgets/alerts
- Connections required by infrastructure

Use AzureRM where supported. Use AzAPI only when required by missing AzureRM coverage. Do not force every Foundry application artifact into Terraform if REST/SDK/config deployment is more appropriate.

Commit `.terraform.lock.hcl`. Do not commit `*.tfstate`, secrets, production credentials, or sensitive tfvars.

Exit criterion: `terraform plan` reviewed before apply.

## Phase 4 — DEV infrastructure deployment

Deploy only DEV. No PROD.

Validate:

- Resource creation
- Project creation
- Model deployments
- Identities
- RBAC
- Observability
- Cost controls

Exit criterion: DEV infrastructure healthy.

## Phase 5 — Knowledge reconstruction

Using `source/inventory/agent-knowledge-mapping.json`:

- Re-upload original knowledge files.
- Create new vector stores.
- Preserve initial chunking: 800 / 400 (`max_chunk_size_tokens` / `chunk_overlap_tokens`).
- Recreate: `SMID-PassGuide` → 3 files; `SMID-WorkshopGuide` → 2 files; legacy `smid-compass-agent` → historical file membership as required for parity.
- Generate new target IDs. Do not reuse source IDs.

Exit criterion: File Search indexes successfully and expected memberships exist.

## Phase 6 — Agent reconstruction

Recreate the six source agents using the frozen YAML definitions (`source/agents/*.yaml`) as the baseline. Preserve initially:

- Instructions
- Model
- Temperature/top_p where applicable
- Tools
- Response schema
- Guardrail associations
- Functional role

Replace only source-specific IDs/references.

Exit criterion: all agents can be invoked individually in nonprofit DEV.

## Phase 7 — Workflow reconstruction

Recreate source routing semantics. Do not intentionally modernize behavior.

If source workflow technology cannot be recreated, use the minimum compatibility implementation required to preserve equivalent behavior, and record any deviation.

Exit criterion: end-to-end routing works.

## Phase 8 — Parity validation

Create validation cases for:

- Router passport
- Router workshop
- Router out_of_scope
- Conversation closing
- PassGuide retrieval
- WorkshopGuide retrieval
- Safety processing
- OutOfScope behavior
- Guardrails
- Web Search
- Malformed/unexpected route handling
- Knowledge retrieval
- Source-known edge cases

Use synthetic/non-sensitive test data. Compare target behavior with the frozen source baseline. Do not require runtime IDs to match.

Exit criterion: functional parity accepted.

## Phase 9 — Freeze nonprofit parity baseline

After validation, create a dedicated Git baseline/tag such as `nonprofit-parity-v1`. **Not created now.** It should represent a working nonprofit DEV reconstruction before modernization.

## Phase 10 — Modernization v2

Only after the nonprofit parity baseline exists. Potential future work:

- Microsoft Agent Framework
- Workflow modernization
- Safety corrections
- Web Search review
- Legacy agent retirement
- Improved guardrails
- Improved evaluations
- Observability improvements
- New SMID modules

Not implemented now.

## Production

PROD is not part of the current deployment phase. Production happens only after: DEV migration → parity validation → `nonprofit-parity-v1` → approved next step. Do not create PROD infrastructure yet.
