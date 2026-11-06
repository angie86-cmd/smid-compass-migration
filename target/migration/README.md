# SMID Compass — Application-Layer Restoration (Target Artifacts)

This directory contains the target-side artifacts used to restore the source-parity SMID Compass application into the Save My Identity nonprofit Foundry DEV project (`smid-compass-dev-a5bc33` / `smid-compass`).

**Live restoration status as of 2026-11-06:** Phase 5 knowledge reconstruction is complete. The 10 target Agent Service files and three vector stores now exist in Foundry DEV. Agent and workflow manifests remain prepared but not yet created live.

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
