# SMID Compass — Nonprofit Migration Plan v1

Incremental phases for reconstructing SMID Compass in the Save My Identity nonprofit Azure tenant, following the architecture in [target-migration-architecture-v1.md](../architecture/target-migration-architecture-v1.md).

Strategy: **migrate → validate → small PROD pilot → modernize in DEV → validate → promote modernization to PROD.** Migration and modernization are kept as separate phases (see Phase 11), and production is rolled out incrementally rather than as a single deployment that waits for modernization to finish.

## Phase 0 — Source preservation

Status: **COMPLETE**

Evidence: `source-snapshot-v1` (finalization commit `90e43db8fcfd934a04a31d752c9b21c5867c8212`)

Do not reopen unless evidence is later found to be missing.

## Phase 1 — Target architecture

Status: **COMPLETE**

Tasks:

- Document parity architecture.
- Document migration boundaries.
- Separate migration from modernization.
- Approve Target Migration Architecture v1.

Result: Target Migration Architecture v1 approved. Migration and modernization are formally separated. See [target-migration-architecture-v1.md](../architecture/target-migration-architecture-v1.md).

Exit criterion: architecture approved before Terraform implementation. Met.

## Phase 2 — Nonprofit preflight

Status: **COMPLETE**

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

Result: nonprofit tenant verified, Owner permissions confirmed at subscription scope, required resource providers registered, Sweden Central approved, `gpt-4.1-mini` and `text-embedding-3-small` versions verified with sufficient quota/capacity.

Output: [docs/preflight/nonprofit-preflight.md](../preflight/nonprofit-preflight.md) — result: **NONPROFIT PREFLIGHT PASSED**. Sweden Central approved for SMID Compass DEV.

Exit criterion: target region and required services confirmed. Met.

## Phase 3 — Terraform foundation

Status: **CURRENT**

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

After validation, create a dedicated Git baseline/tag: `nonprofit-parity-v1`. **Not created now.** It represents a working, source-parity nonprofit DEV reconstruction, before modernization and before any PROD deployment. It is what Phase 10 promotes to PROD, and what DEV branches from again in Phase 11 to begin modernization.

## Phase 10 — Initial PROD parity pilot

Only after `nonprofit-parity-v1` exists (Phase 9).

Promote the validated parity baseline — not a modernized version — to PROD, as a small, controlled pilot rather than a full production rollout:

- Deploy the `nonprofit-parity-v1` baseline to PROD infrastructure, scoped down (e.g. limited users/traffic) as appropriate for a pilot.
- Collect monitoring and operational feedback (observability, error rates, real-world usage patterns) from an actual PROD environment.
- Do not introduce Modernization v2 changes during this pilot. PROD at this point runs the same source-parity behavior validated in DEV, nothing more.
- DEV remains the only environment where modernization work happens (Phase 11); this PROD pilot is not touched by that work directly.

Exit criterion: parity baseline running in a small, controlled PROD pilot, with monitoring in place and no major issues observed.

## Phase 11 — Modernization v2 (DEV only)

Modernization starts only after the nonprofit parity baseline exists (Phase 9) — it does not need to wait for the PROD pilot to conclude, but it must never modify the already-running PROD pilot directly. All Modernization v2 work happens in DEV.

Potential future work:

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

Sequence once this phase begins:

1. Implement modernization changes in DEV, branching from `nonprofit-parity-v1`.
2. Validate the modernized DEV version (equivalent rigor to Phase 8, against modernized behavior rather than strict source parity).
3. Freeze a new modernized baseline (a dedicated Git tag, e.g. `nonprofit-modernized-v2`).
4. Promote that validated modernized baseline to PROD in a second, separate controlled rollout — distinct from, and after, the initial parity pilot in Phase 10.

## Production

Production is rolled out incrementally, in two controlled stages, not as a single deployment gated on Modernization v2:

1. **Initial parity pilot (Phase 10):** once `nonprofit-parity-v1` exists, that source-parity baseline is promoted to PROD as a small, controlled pilot with monitoring, before any modernization work begins.
2. **Modernization promotion (end of Phase 11):** once Modernization v2 is implemented and validated in DEV and frozen as its own baseline, that modernized version is promoted to PROD in a second, separate controlled rollout.

Do not create PROD infrastructure yet — Phase 4 (DEV infrastructure deployment) explicitly excludes PROD, and PROD work does not begin until Phase 10.
