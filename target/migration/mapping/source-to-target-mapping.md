# SMID Compass — Source → Target Mapping (Application-Layer Restoration)

Status: **Phases 5–9 complete (knowledge/agents/workflow live: 2026-11-06 and 2026-11-13; parity smoke validation passed and baseline documented: 2026-11-13).** The migration-to-parity milestone is complete. The Git tag `nonprofit-parity-v1` is pending manual creation. The next technical work is Modernization v2 (Microsoft Agent Framework migration in DEV), not started.

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

Steps 1–5 have now been executed/validated in nonprofit DEV. Step 6 (minimal provisioning verification) is satisfied by the live field-level checks performed during steps 4–5; functional/semantic parity testing (Phase 8) remains pending.

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

### Live target agent versions (2026-11-13)

Target agent version numbers are a target-runtime fact only; they are not expected to match, and do not reuse, source version numbers (source versions are listed in the "Source version" column above).

| Target name | Live target version | State / status |
|---|---|---|
| SMID-RouterAgent | **2** | enabled / active |
| SMID-PassGuide | 1 | enabled / active |
| SMID-WorkshopGuide | 1 | enabled / active |
| SMID-SafetyAgent | 1 | enabled / active |
| OutOfScopeAgent | 1 | enabled / active |
| smid-compass-agent | 1 | enabled / active |

`SMID-RouterAgent` is at target version 2, not 1, because the first live creation attempt was affected by a local UTF-8 extraction defect in the migration tooling (not a Foundry API defect): non-ASCII arrow characters in the instructions were corrupted during extraction from the manifest file. This was caught via byte-level verification, and a corrected definition was pushed as version 2 using `POST /agents/SMID-RouterAgent?api-version=v1` (the dedicated update-agent route; `POST /agents` returns `HTTP 409 Conflict` for an existing agent name rather than creating a new version). Version 2 was verified field-for-field identical to the prepared manifest, including correct byte-level arrow characters. Version 1 remains in the agent's version history as a superseded, inactive version; `latest` correctly resolves to version 2.

## 4. Knowledge / vector stores

- 25 physical assets preserved in `source/data/`; 13 vector-store memberships existed in source; **10 unique physical files** are actually referenced (some files are shared across two source vector stores under different `assistant-*` IDs — uploaded once per file in target, ID reused). Full detail: `target/migration/knowledge/file-mapping.json`.
- 15 preserved local assets are **not** uploaded — never referenced by any source membership, uploading them would restore nothing.
- Chunking preserved exactly: `static`, `max_chunk_size_tokens: 800`, `chunk_overlap_tokens: 400` (this also happens to match the current API's own default, so no override risk).
- `LOPNA 2015.pdf` had `source_vector_status: failed` in the source legacy store. Target Agent Service upload succeeded, but target vector-store parsing also failed (`invalid_file`, no extractable content). This reproduces the historical source failure and is accepted as source-parity behavior.
- Live target vector stores: `smid-passguide` = `vs_VvDHhLobUnN8s9YC4uk83BWU`; `smid-workshopguide` = `vs_HMvRtKkm9ew6RzyJ56zIeJvC`; `smid-compass-agent-legacy` = `vs_hUQ2f7P22jDSvP9cS9MhRYvM`.
- Live API difference: Dataset-backed `data_source` / `data_sources` attachment is rejected on this deployment despite appearing in the published TypeSpec. Agent Service Files with `file_id` are the working mechanism used.
- Live filename difference: the Embajada PDF required an ASCII-safe multipart upload filename (`EmbajadaBerlin_ascii.pdf`) because the original accented/en-dash filename deterministically returned HTTP 500. Uploaded bytes are identical to the source file.

## 5. Guardrails

Custom policy `SMID-Guardrails-Policy` applied to: Router, PassGuide, WorkshopGuide, Safety, legacy agent. **Not** applied to OutOfScopeAgent — preserved asymmetry, not normalized. See `target/migration/rai-policy/SMID-Guardrails-Policy.arm-request.json` for the ARM translation and its one flagged ambiguity (the jailbreak filter's exact category name/threshold, not fully confirmed from documentation this session — marked `_unverified: true`, needs a live check before that PUT is executed).

## 6. Workflow

Router → (passport → PassGuide → Safety → end) | (workshop → WorkshopGuide → Safety → end) | (otherwise → OutOfScope → end, **bypassing Safety**). Preserved exactly, including the known Safety input mismatch (instructions expect `<route> | <answer>`, workflow sends answer-only). Not fixed — this is explicitly deferred to Modernization v2, per the approved migration strategy.

**Live result (2026-11-13):** `SMID-compass-workflow` created via `POST {FOUNDRY_PROJECT_ENDPOINT}/agents?api-version=v1` with `kind: workflow` and the required preview header `Foundry-Features: WorkflowAgents=V1Preview`. Live identity: `SMID-compass-workflow:1`, version `1`, `enabled`/`active`, `draft: false`. The live `definition.workflow` string matched `target/migration/workflow/SMID-compass-workflow.yaml` exactly, byte-for-byte. All five referenced agents resolved correctly against their live target versions (`SMID-RouterAgent` v2, `SMID-PassGuide` v1, `SMID-WorkshopGuide` v1, `SMID-SafetyAgent` v1, `OutOfScopeAgent` v1). No modernization was performed, and the OutOfScope-bypasses-Safety asymmetry and the Safety input mismatch were both preserved unchanged. Microsoft Foundry declarative workflows are scheduled for retirement on 2026-12-01 — this does not invalidate this parity restoration; migration to Microsoft Agent Framework remains deferred to Modernization v2 (Phase 11), after the nonprofit parity baseline is validated.

## 7. Open items (resolved)

1. **Jailbreak RAI filter mapping** — **resolved live**. `SMID-Guardrails-Policy` is deployed and validated; Jailbreak is enabled for Prompt with the accepted live configuration.
2. **`Foundry-Features` header exact value** for creating the workflow agent — **resolved live**. Confirmed as `Foundry-Features: WorkflowAgents=V1Preview` both by a successful live call and by independent verification against the current Foundry TypeSpec (`AgentDefinitionOptInKeys.workflow_agents_v1_preview` in `specification/ai-foundry/data-plane/Foundry/src/common/servicepatterns.tsp`).
3. **`web_search` tool schema** for Safety — **resolved live**. The source's zero-parameter shape (`{"type": "web_search"}`) was accepted as-is by `POST /agents?api-version=v1`; no schema incompatibility.

All open items from this round of migration are resolved. Phase 8 functional/semantic parity validation has passed (see [docs/validation/phase-8-parity-validation.md](../../docs/validation/phase-8-parity-validation.md)); remaining work is Modernization v2, not further compatibility research or parity migration.

## 8. Phase 8 parity validation result (2026-11-13)

**PARITY SMOKE TEST PASSED.** Six synthetic, bilingual smoke tests (Passport/Workshop/Out-of-scope × Spanish/German) were run live against the workflow via `POST openai/v1/conversations` + `POST openai/v1/responses` (`agent_reference`, `Foundry-Features: WorkflowAgents=V1Preview`). All six passed: correct Router classification in both languages, successful File Search execution for PassGuide/WorkshopGuide against their migrated vector stores, Safety executing on the passport/workshop paths and bypassed on the out-of-scope path exactly as in source, the workflow reaching `End` in every case, no migrated-resource reference errors, and language behavior (bilingual ES+DE for PassGuide/WorkshopGuide/Safety; single input-matching language for OutOfScopeAgent) matching each agent's source instructions exactly. This was a migration parity smoke validation, not exhaustive product QA. Full evidence is permanent in [docs/validation/phase-8-parity-validation.md](../../docs/validation/phase-8-parity-validation.md).

During this validation, the live `SMID-compass-workflow` was observed at version 3 (Phase 7 had observed version 1); versions 2/3 differ from version 1 only in comments — the functional workflow YAML remains equivalent to the validated parity definition across all three versions. This is target-side versioning behavior with no functional parity impact; it was not modified or downgraded.

## 9. Phase 9 — parity baseline (2026-11-13)

The source-parity migration is reconstructed (Phases 5–7), end-to-end parity smoke validation has passed (Phase 8), the validation evidence is stored permanently in this repository, and this repository state represents the validated nonprofit parity baseline. The Git tag `nonprofit-parity-v1` is pending manual creation, together with the final commit and push. The migration-to-parity milestone is complete; the next technical work is Modernization v2 (Microsoft Agent Framework migration in DEV, Phase 11), not started — the current agents, workflow, and other live resources must remain unmodified until that work explicitly branches from this baseline.
