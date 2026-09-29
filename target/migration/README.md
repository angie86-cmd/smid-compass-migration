# SMID Compass — Application-Layer Restoration (Target Artifacts)

This directory contains reviewable, not-yet-executed target-side artifacts for restoring the source-parity SMID Compass application into the Save My Identity nonprofit Foundry DEV project (`smid-compass-dev-a5bc33` / `smid-compass`).

**Nothing here has been created in Azure.** These are local specifications only, prepared per the migration plan's Phase 5–7 (knowledge, agents, workflow), for review before any live Foundry/ARM call.

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
