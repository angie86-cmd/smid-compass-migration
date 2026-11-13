# SMID Compass — Application-Layer Restoration (Target Artifacts)

This directory contains the target-side artifacts used to restore the source-parity SMID Compass application into the Save My Identity nonprofit Foundry DEV project (`smid-compass-dev-a5bc33` / `smid-compass`).

**Live restoration status as of 2026-11-13:** Phases 5–9 are all complete. The 10 target Agent Service files, three vector stores, six prompt agents, and the workflow agent all exist live in Foundry DEV, and the end-to-end parity smoke validation (Phase 8) has passed. This repository state represents the validated nonprofit parity baseline (Phase 9); the Git tag `nonprofit-parity-v1` is pending manual creation. The migration-to-parity milestone is complete — the next technical work is Modernization v2 (Microsoft Agent Framework migration in DEV), not started.

Read [mapping/source-to-target-mapping.md](mapping/source-to-target-mapping.md) first — it has the compatibility research findings, execution order, and the full per-agent/knowledge/guardrail/workflow mapping.

## Layout

- `rai-policy/` — ARM request body for the target `SMID-Guardrails-Policy` RAI policy.
- `knowledge/` — source filename → target file ID mapping for the 10 unique files that need uploading.
- `vector-stores/` — creation request specs for the three target vector stores (PassGuide, WorkshopGuide, legacy).
- `agents/` — one manifest per source agent, translating `source/agents/*.yaml` into the current Foundry `PromptAgentDefinition` schema.
- `workflow/` — the target workflow YAML (copy, no content changes needed) and its `WorkflowAgentDefinition` wrapper.
- `mapping/` — the full source→target mapping and compatibility decision record.

## Source of truth

`source/agents/`, `source/workflows/`, `source/guardrails/`, and `source/inventory/agent-knowledge-mapping.json` are authoritative. Nothing under `source/**` was modified to produce these artifacts.


## Live Phase 5 result

- `smid-passguide` → `vs_VvDHhLobUnN8s9YC4uk83BWU` — 3/3 completed.
- `smid-workshopguide` → `vs_HMvRtKkm9ew6RzyJ56zIeJvC` — 2/2 completed.
- `smid-compass-agent-legacy` → `vs_hUQ2f7P22jDSvP9cS9MhRYvM` — 7 completed / 1 failed.
- The failed legacy membership is `LOPNA 2015.pdf`, reproducing the same historical source ingestion failure.
- Static chunking `800/400` was preserved.
- Dataset-backed vector-store attachment was not accepted by the live API on this deployment, so parity restoration used Agent Service Files and `file_id` attachments.
- The Embajada PDF was uploaded as `EmbajadaBerlin_ascii.pdf` because the live Files API returned HTTP 500 for the original non-ASCII multipart filename. Content remained byte-identical to source.

## Live Phase 6 result (2026-11-13)

- All six agents created via `POST {PROJECT_ENDPOINT}/agents?api-version=v1`; no extra authentication, permission, or feature flag required beyond existing Azure CLI auth.
- `SMID-RouterAgent` v2, `SMID-PassGuide` v1, `SMID-WorkshopGuide` v1, `SMID-SafetyAgent` v1, `OutOfScopeAgent` v1, `smid-compass-agent` v1 — all `enabled`/`active`.
- `SMID-RouterAgent` is at target version 2 because a local UTF-8 extraction defect (not an API defect) corrupted non-ASCII characters in version 1's instructions; version 2 was created via `POST /agents/SMID-RouterAgent?api-version=v1` and verified field-for-field identical to the manifest. Target version numbers are independent of, and not expected to match, source version numbers.
- `POST /agents` returns `HTTP 409 Conflict` if called again with an existing agent name — creating a new version of an existing agent requires `POST /agents/{agent_name}?api-version=v1` instead.
- Intentional source asymmetries preserved exactly: `OutOfScopeAgent` has no RAI guardrail association; `SMID-SafetyAgent` has no `temperature`/`top_p`/`tool_choice`/`text` fields.
- No unexpected schema normalization observed on any agent.

## Live Phase 7 result (2026-11-13)

- `SMID-compass-workflow` created via the same `POST {PROJECT_ENDPOINT}/agents?api-version=v1` endpoint, `kind: workflow`, with required preview header `Foundry-Features: WorkflowAgents=V1Preview` — confirmed independently against the current Foundry TypeSpec (`AgentDefinitionOptInKeys.workflow_agents_v1_preview`), not assumed from prior research.
- Live identity: `SMID-compass-workflow:1`, version `1`, `enabled`/`active`, `draft: false`.
- The live `definition.workflow` string matched `target/migration/workflow/SMID-compass-workflow.yaml` exactly, byte-for-byte.
- All five referenced agents resolved correctly: `SMID-RouterAgent` v2, `SMID-PassGuide` v1, `SMID-WorkshopGuide` v1, `SMID-SafetyAgent` v1, `OutOfScopeAgent` v1.
- Routing preserved exactly, including that `OutOfScopeAgent` bypasses `SMID-SafetyAgent`, and that `SMID-SafetyAgent` still receives answer-only input (the known `<route> | <answer>` mismatch) — neither corrected, per migrate-first/modernize-later.
- Microsoft Foundry declarative workflows are scheduled for retirement on 2026-12-01; this does not invalidate the parity restoration. Modernization to Microsoft Agent Framework remains deferred to the later modernization phase.

## Live Phase 8 result (2026-11-13) — PARITY SMOKE TEST PASSED

- Full evidence: [docs/validation/phase-8-parity-validation.md](../../docs/validation/phase-8-parity-validation.md). This was a migration parity smoke validation, not exhaustive product QA.
- Invocation mechanism: `POST openai/v1/conversations` then `POST openai/v1/responses` with `agent_reference: {type: "agent_reference", name: "SMID-compass-workflow"}` and header `Foundry-Features: WorkflowAgents=V1Preview`.
- Six tests passed: Passport ES/DE, Workshop ES/DE, Out-of-scope ES/DE. Router classification, File Search execution (PassGuide/WorkshopGuide), Safety execution on passport/workshop paths, Safety bypass on out-of-scope, and bilingual (ES+DE) vs. single-language response behavior all matched source instructions exactly, with the workflow reaching `End` and no migrated-resource reference errors in every case.
- Observed during this phase: the live `SMID-compass-workflow` was at version 3 (Phase 7 had observed version 1); versions 2/3 differ only in comments, with functional YAML remaining equivalent to the validated parity definition. Target-side versioning behavior with no functional parity impact; not modified or downgraded.

## Phase 9 result (2026-11-13) — parity baseline documented

The source-parity migration is reconstructed (Phases 5–7), end-to-end parity smoke validation has passed (Phase 8), the validation evidence is stored permanently in this repository, and this repository state represents the validated nonprofit parity baseline. The Git tag `nonprofit-parity-v1` is pending manual creation, together with the final commit and push.
