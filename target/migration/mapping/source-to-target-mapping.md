# SMID Compass — Source → Target Mapping (Application-Layer Restoration)

Status: **prepared, not yet executed.** Nothing in this document has been created in Azure. All artifacts in `target/migration/` are local files for review before any live Foundry/ARM call is made, per the parity-restoration task's Step 7/12 checkpoints.

`source/**` is unchanged. `terraform/**` is unchanged. This restoration is entirely application/data-plane (Foundry Agents API + one ARM RAI-policy resource), not infrastructure.

## 1. Compatibility research summary

Researched against the authoritative current source (Azure/azure-rest-api-specs TypeSpec for the Foundry Agents data plane, not just prose docs), because getting this wrong wouldn't fail loudly — it could silently produce agents that look right but don't preserve routing/tool behavior.

| Question | Finding |
|---|---|
| Does the current `AgentDefinition`/`PromptAgentDefinition` schema match source YAML? | Yes, almost field-for-field: `kind`, `model`, `instructions`, `temperature`, `top_p`, `tools`, `tool_choice`, `text.format`, `rai_config.rai_policy_name`. Source YAML is effectively a raw export of this same resource shape. |
| Which source fields are non-portable and dropped? | `metadata`, `object`, `id`, `version`, `created_at`, `draft`, `status`, `instance_identity`, `blueprint`, `blueprint_reference`, `agent_guid` — all marked `@visibility(Lifecycle.Read)` in the spec, i.e. server-assigned on creation. The API itself enforces "never reuse historical IDs/GUIDs." |
| Is `POST /agents/{name}/versions:import` the right endpoint? | **No** — its body is `{manifest_id, parameter_values}`, for importing a pre-registered, parameterized Manifest template. Since none of the six agents use template parameters, `POST /agents` (create agent + v1) is used instead — same outcome, no unnecessary manifest-registration indirection. Confirmed with you before proceeding. |
| Is the source declarative workflow still creatable? | Yes. `WorkflowAgentDefinition` (`kind: workflow`) still exists, gated behind an opt-in preview header, consistent with the 2026-12-01 retirement date you already knew about. No Agent Framework migration needed for this task. |
| Is file_search attached directly, or via a "toolbox" + MCP connection? | Direct attachment (`tools: [{type: file_search, vector_store_ids: [...]}]`), matching source exactly and matching the plain SDK sample (`FileSearchTool(vector_store_ids=...)`). The newer toolbox+MCP+connection pattern was available but rejected: it would introduce a toolbox and a project connection, neither of which existed in source. |
| Is `SMID-Guardrails-Policy` a Foundry data-plane object? | No — it's `Microsoft.CognitiveServices/accounts/raiPolicies`, an ARM resource (sibling of the model deployments), created via ARM REST, not the Agents API. |

## 2. Execution order (once you approve moving to live creation)

1. **RAI policy** (ARM) — `target/migration/rai-policy/SMID-Guardrails-Policy.arm-request.json`. Must exist first since five of the six agents reference it.
2. **Knowledge files** — upload the 10 unique files per `target/migration/knowledge/file-mapping.json`.
3. **Vector stores** — create the 3 stores per `target/migration/vector-stores/*.json`, using the file IDs from step 2.
4. **Agents** — create the 6 agents per `target/migration/agents/*.manifest.json`, using the RAI policy ARM ID (step 1) and vector store IDs (step 3).
5. **Workflow** — create the workflow agent per `target/migration/workflow/`, after all 5 agents it references by name exist.
6. **Minimal provisioning verification only** (Step 11): confirm each resource exists, has the expected tools/model/vector-store attached — no semantic prompts, no functional/parity testing (deferred to next week).

Nothing below this line has happened yet.

## 3. Agent mapping

| Source agent | Source version | Target name | Model | Tools | Guardrail | Notes |
|---|---|---|---|---|---|---|
| SMID-RouterAgent | 9 | SMID-RouterAgent | gpt-4.1-mini | none | Applied | Structured output (`smid_router_output`, strict, `additionalProperties: false`) preserved exactly. |
| SMID-PassGuide | 7 | SMID-PassGuide | gpt-4.1-mini | file_search → PassGuide store (3 files) | Applied | |
| SMID-WorkshopGuide | 13 | SMID-WorkshopGuide | gpt-4.1-mini | file_search → WorkshopGuide store (2 files) | Applied | |
| SMID-SafetyAgent | 7 | SMID-SafetyAgent | gpt-4.1-mini | web_search | Applied | No temperature/top_p/tool_choice/text in source — none added. |
| OutOfScopeAgent | 5 | OutOfScopeAgent | gpt-4.1-mini | none | **Not applied** | Source asymmetry, deliberately preserved. |
| smid-compass-agent | 6 | smid-compass-agent | gpt-4.1-mini | file_search → legacy store (8 files) | Applied | Legacy candidate, preserved, not retired or redesigned. |

Router/PassGuide/WorkshopGuide/legacy all use `temperature: 0.3`, `top_p: 1` (source values, unchanged).

## 4. Knowledge / vector stores

- 25 physical assets preserved in `source/data/`; 13 vector-store memberships existed in source; **10 unique physical files** are actually referenced (some files are shared across two source vector stores under different `assistant-*` IDs — uploaded once per file in target, ID reused). Full detail: `target/migration/knowledge/file-mapping.json`.
- 15 preserved local assets are **not** uploaded — never referenced by any source membership, uploading them would restore nothing.
- Chunking preserved exactly: `static`, `max_chunk_size_tokens: 800`, `chunk_overlap_tokens: 400` (this also happens to match the current API's own default, so no override risk).
- `LOPNA 2015.pdf` had `source_vector_status: failed` in the legacy store. This is preserved as a documented historical fact. The physical file is included in the target legacy-store request so reconstruction can be attempted, but if it succeeds where source failed, that's a noted platform difference — not something to claim as an intentional fix.

## 5. Guardrails

Custom policy `SMID-Guardrails-Policy` applied to: Router, PassGuide, WorkshopGuide, Safety, legacy agent. **Not** applied to OutOfScopeAgent — preserved asymmetry, not normalized. See `target/migration/rai-policy/SMID-Guardrails-Policy.arm-request.json` for the ARM translation and its one flagged ambiguity (the jailbreak filter's exact category name/threshold, not fully confirmed from documentation this session — marked `_unverified: true`, needs a live check before that PUT is executed).

## 6. Workflow

Router → (passport → PassGuide → Safety → end) | (workshop → WorkshopGuide → Safety → end) | (otherwise → OutOfScope → end, **bypassing Safety**). Preserved exactly, including the known Safety input mismatch (instructions expect `<route> | <answer>`, workflow sends answer-only). Not fixed — this is explicitly deferred to Modernization v2, per the approved migration strategy.

## 7. Open items requiring a decision or verification before live execution

1. **Jailbreak RAI filter mapping** — flagged in the RAI policy artifact, not resolved.
2. **`Foundry-Features` header exact value** for creating the workflow agent — the opt-in requirement is confirmed, the literal header string is not independently verified against a live call.
3. **`web_search` tool schema** for Safety — assumed identical to source's zero-parameter shape; not independently re-verified against current docs this session (low risk, since `tools` is typed as the standard `OpenAI.Tool[]` union and source already used the simplest possible form).

None of these block preparing the artifacts (done). They should be resolved or explicitly accepted before Step 4 (agents) and the RAI policy PUT actually execute.
