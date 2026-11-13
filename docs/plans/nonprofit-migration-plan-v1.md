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

Status: **COMPLETE**

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

Progress as of 2026-11-04:
- Resource group, remote state, Log Analytics, Application Insights, Foundry resource, and Foundry project have been deployed.
- The Terraform foundation was extended to include the source-parity model deployments, minimum Foundry RBAC, DEV cost budget, and `SMID-Guardrails-Policy`.
- Live Azure validation has started. The custom `SMID-Guardrails-Policy` is present in `rg-smid-compass-dev` and its filter configuration is being verified.
- The remaining task for this phase is not to redesign Terraform, but to finish validating that the deployed DEV foundation matches the intended configuration.

Exit criterion: deployed Terraform-managed DEV foundation reviewed and validated healthy.

## Phase 4 — DEV infrastructure deployment

Status: **COMPLETE**

DEV only. No PROD.

Work resumed on **2026-11-04** after a pause of approximately one month. Infrastructure validation has now been completed successfully.

Validate:

- Resource creation
- Project creation
- Model deployments
- Identities
- RBAC
- Observability
- Cost controls

Validation completed:
- Foundry resource and project confirmed healthy.
- `gpt-4.1-mini`: version `2025-04-14`, GlobalStandard, capacity 50.
- `text-embedding-3-small`: version `1`, GlobalStandard, capacity 120.
- Foundry project uses a system-assigned managed identity.
- Developer identity and Foundry project managed identity have the expected Foundry User RBAC assignment on the Foundry resource.
- Log Analytics and Application Insights both report `Succeeded` and Application Insights is linked to the expected workspace.
- DEV budget `budget-smid-compass-dev` exists at 50 EUR/month.
- Budget notifications are enabled at 50%, 80%, and 100% of actual spend.
- `SMID-Guardrails-Policy` exists with the expected Hate, SelfHarm, Sexual, and Violence filters for Prompt and Completion, plus Jailbreak for Prompt.

Exit criterion: DEV infrastructure healthy and ready for application/data-plane restoration. **Met.**

## Phase 5 — Knowledge reconstruction

Status: **COMPLETE**

Target-side restoration specs already exist under `target/migration/`. The knowledge mapping identifies the 10 unique source files that are actually referenced and need target upload; unreferenced preserved source assets are not part of parity restoration.

Using `source/inventory/agent-knowledge-mapping.json`:

- Re-upload original knowledge files.
- Create new vector stores.
- Preserve initial chunking: 800 / 400 (`max_chunk_size_tokens` / `chunk_overlap_tokens`).
- Recreate: `SMID-PassGuide` → 3 files; `SMID-WorkshopGuide` → 2 files; legacy `smid-compass-agent` → historical file membership as required for parity.
- Generate new target IDs. Do not reuse source IDs.

Live result (2026-11-06):
- 10 unique Agent Service files uploaded and assigned new target file IDs.
- `smid-passguide`: 3/3 memberships completed.
- `smid-workshopguide`: 2/2 memberships completed.
- `smid-compass-agent-legacy`: 7 completed / 1 failed.
- The sole failed legacy membership is `LOPNA 2015.pdf`; target parsing reports `invalid_file` / no extractable content, reproducing the historical source vector-store failure already recorded in the frozen snapshot.
- Static chunking `800 / 400` is preserved on all memberships.
- Live Foundry API behavior on this project rejects Dataset-backed `data_source` / `data_sources` vector-store attachment. Agent Service `file_id` attachment is the working path used for parity restoration.
- The Embajada PDF required an ASCII-safe upload filename due a deterministic HTTP 500 from `/openai/v1/files` when the original non-ASCII filename was used. The uploaded content is byte-identical to the source file.

Exit criterion: File Search indexes successfully and expected source-parity memberships exist, including preservation of the known LOPNA failure. **Met.**

## Phase 6 — Agent reconstruction

Status: **COMPLETE**

Six target agent manifests existed under `target/migration/agents/`. The six source agents were recreated live in nonprofit DEV on **2026-11-13**, using the frozen YAML definitions (`source/agents/*.yaml`) as the baseline, via `POST {PROJECT_ENDPOINT}/agents?api-version=v1`. Preserved:

- Instructions
- Model
- Temperature/top_p where applicable
- Tools
- Response schema
- Guardrail associations
- Functional role

Only source-specific IDs/references were replaced (new target vector-store IDs, new target RAI policy ARM ID; no historical source IDs/GUIDs reused).

Live result:
- `SMID-RouterAgent` v2, `SMID-PassGuide` v1, `SMID-WorkshopGuide` v1, `SMID-SafetyAgent` v1, `OutOfScopeAgent` v1, `smid-compass-agent` v1 — all `enabled`/`active`.
- `SMID-RouterAgent`'s target version is 2, not 1: a local UTF-8 extraction defect corrupted non-ASCII characters in version 1's instructions (tooling issue, not an API issue); version 2 was created via `POST /agents/SMID-RouterAgent?api-version=v1` and verified field-for-field identical to the manifest. This is a target runtime/versioning fact only — target version numbers are not expected to match, and do not reuse, source version numbers (source `SMID-RouterAgent` was version 9).
- Intentional source asymmetries preserved exactly: `OutOfScopeAgent` has no RAI guardrail; `SMID-SafetyAgent` has no `temperature`/`top_p`/`tool_choice`/`text`.
- No unexpected schema normalization by Foundry.

Exit criterion: all agents can be invoked individually in nonprofit DEV. **Met** (individual invocation / semantic testing deferred to Phase 8; existence, configuration, and field-level parity are verified).

## Phase 7 — Workflow reconstruction

Status: **COMPLETE**

The source-parity workflow YAML and target workflow manifest were prepared under `target/migration/workflow/`, and the workflow was created live in nonprofit DEV on **2026-11-13**.

Recreated source routing semantics exactly; no intentional modernization.

Creation mechanism: `POST {PROJECT_ENDPOINT}/agents?api-version=v1`, `kind: workflow`, with required preview header `Foundry-Features: WorkflowAgents=V1Preview` (value independently confirmed against the current Foundry TypeSpec `AgentDefinitionOptInKeys` enum).

Live result:
- `SMID-compass-workflow`, id `SMID-compass-workflow:1`, version `1`, `enabled`/`active`, `draft: false`.
- The live `definition.workflow` string matched `target/migration/workflow/SMID-compass-workflow.yaml` exactly (byte-for-byte).
- All five referenced agents resolved correctly: `SMID-RouterAgent` v2, `SMID-PassGuide` v1, `SMID-WorkshopGuide` v1, `SMID-SafetyAgent` v1, `OutOfScopeAgent` v1.
- Routing preserved exactly: Router → passport → PassGuide → Safety → End; Router → workshop → WorkshopGuide → Safety → End; Router → otherwise → OutOfScope → End. `OutOfScope` bypasses Safety entirely — preserved, not corrected. `SMID-SafetyAgent` still receives answer-only input (the known `<route> | <answer>` instructions mismatch) — preserved, not corrected; deferred to Modernization v2.
- Microsoft Foundry declarative workflows are scheduled for retirement on **2026-12-01**. This does not invalidate this parity restoration — migration to Microsoft Agent Framework remains deferred to Phase 11 (Modernization v2), after the nonprofit parity baseline is validated.

Exit criterion: end-to-end routing works. **Met** at the configuration/wiring level (all nodes, branches, and agent references verified live); end-to-end semantic/functional parity testing is Phase 8.

## Phase 8 — Parity validation

Status: **COMPLETE / PARITY SMOKE TEST PASSED**

This was a migration parity **smoke validation**, not exhaustive product QA. Its purpose was to prove that the nonprofit migration works end-to-end before modernization begins — not to replace a full future QA pass.

Executed live on **2026-11-13** against the restored nonprofit DEV agents and workflow, via `POST openai/v1/conversations` + `POST openai/v1/responses` (`agent_reference`, header `Foundry-Features: WorkflowAgents=V1Preview`). Six controlled, synthetic, bilingual test cases:

- Router passport (ES, DE)
- Router workshop (ES, DE)
- Router out_of_scope (ES, DE)

All six passed. Verified: Router classification in Spanish and German; Passport routes to `SMID-PassGuide` with successful File Search against the migrated vector store; Workshop routes to `SMID-WorkshopGuide` with successful File Search against the migrated vector store; `SMID-SafetyAgent` executes after passport/workshop; `OutOfScopeAgent` bypasses Safety exactly as in source; the workflow reaches `End` in every case; no migrated-resource reference errors; `SMID-PassGuide`/`SMID-WorkshopGuide`/`SMID-SafetyAgent` bilingual ES+DE output and `OutOfScopeAgent`'s single-input-language output both match their respective source instructions exactly.

Full evidence, including per-test routing/node-sequence traces, File Search query evidence, and response excerpts, is recorded permanently in [docs/validation/phase-8-parity-validation.md](../validation/phase-8-parity-validation.md).

Observed during this phase: the live `SMID-compass-workflow` was at version 3 (Phase 7 had observed version 1); versions 2/3 differ from version 1 only in comments, with functional YAML remaining equivalent to the validated parity definition. Documented as target-side versioning behavior with no functional parity impact; not modified or downgraded.

Exit criterion: functional parity accepted. **Met.**

## Resume checkpoint — 2026-11-13

Phases 6–9 are all complete: agent creation, workflow creation, parity smoke validation (passed), and the parity baseline documentation freeze. The migration-to-parity milestone is complete. The next engineering work is Modernization v2 (Phase 11), not started yet. The Git tag `nonprofit-parity-v1` marking this baseline is to be created manually, together with the final commit and push, after this documentation update is reviewed.

Prepared application-layer artifacts are documented in `target/migration/README.md` and `target/migration/mapping/source-to-target-mapping.md`.

## Phase 9 — Freeze nonprofit parity baseline

Status: **COMPLETE (documentation)** — Git tag pending manual creation.

The dedicated Git baseline/tag `nonprofit-parity-v1` represents a working, source-parity nonprofit DEV reconstruction, validated by Phase 8's passed parity smoke test, before modernization and before any PROD deployment. As of 2026-11-13: the source-parity migration is reconstructed (Phases 5–7), end-to-end parity smoke validation has passed (Phase 8), the validation evidence is stored permanently in the repository (`docs/validation/phase-8-parity-validation.md`), and this repository state represents the validated nonprofit parity baseline. **The tag itself is not created by this update** — it is to be created manually, together with the final commit and push, after this documentation update is reviewed. It is what Phase 10 promotes to PROD, and what DEV branches from again in Phase 11 to begin modernization.

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
