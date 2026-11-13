# Phase 8 — Parity Validation Evidence

**Validation date:** 2026-11-13

**Target environment:** Save My Identity nonprofit Azure tenant, DEV project
- Tenant: `48cb7850-a5c9-4632-9dbd-eccda8b8b9bb`
- Subscription: `a5bc333b-cd24-4c66-95e0-18013949c94f`
- Foundry project endpoint: `https://smid-compass-dev-a5bc33.services.ai.azure.com/api/projects/smid-compass`

**Authentication method:** Existing Azure CLI login (`cloud_smid@savemyidentityorg.onmicrosoft.com`), verified via `az account show` before testing. Foundry data-plane access tokens were acquired dynamically per call via `az account get-access-token --scope https://ai.azure.com/.default`, held only in process/shell memory, never printed, persisted, or written to any repository file, and discarded after use. No API keys were used. No tokens, secrets, or raw `Authorization` headers appear anywhere in this document or in the repository.

## Live resource versions used

| Resource | Version | State / status |
|---|---|---|
| SMID-RouterAgent | 2 | enabled / active |
| SMID-PassGuide | 1 | enabled / active |
| SMID-WorkshopGuide | 1 | enabled / active |
| SMID-SafetyAgent | 1 | enabled / active |
| OutOfScopeAgent | 1 | enabled / active |
| smid-compass-agent | 1 | enabled / active (not exercised by these tests; legacy/parity artifact) |
| SMID-compass-workflow | **3** (see note below) | enabled / active |
| vs_VvDHhLobUnN8s9YC4uk83BWU (smid-passguide) | — | completed, 3/3 files |
| vs_HMvRtKkm9ew6RzyJ56zIeJvC (smid-workshopguide) | — | completed, 2/2 files |
| vs_hUQ2f7P22jDSvP9cS9MhRYvM (smid-compass-agent-legacy) | — | completed, 7/8 files (LOPNA parity-preserved failure) |

**Note on workflow version:** at the start of Phase 8, `SMID-compass-workflow` was found live at version **3**, not version 1 as recorded at the end of Phase 7. Versions 2 and 3 were not created by this validation session. Diffing all three versions' `definition.workflow` strings line-by-line showed the difference is **comment-only**: Phase 7's explanatory header comment is absent from v2/v3, and v2 added then v3 removed a single empty, unused sticky-note comment. Every functional line (trigger, actions, `InvokeAzureAgent` nodes, agent names, conditions, the `Coalesce` expression, `EndConversation` nodes) is byte-identical across v1, v2, and v3, and identical to `target/migration/workflow/SMID-compass-workflow.yaml`. This pattern is consistent with the agent having been opened (even without an intentional logic edit) in the Foundry portal visual designer at some point between Phase 7 sign-off and the start of Phase 8, which re-serializes the YAML and drops unrecognized leading comments — note that Phase 7 and this Phase 8 prompt both explicitly instruct not to use the portal UI; this did not originate from this validation session's own actions. It is flagged here for visibility, not corrected (routing logic is unaffected and no fix was required or attempted). All tests below exercised the live workflow as found, i.e. version 3.

## Invocation mechanism

The live, currently-supported Foundry invocation mechanism was determined by TypeSpec inspection, not assumed:

1. `POST {PROJECT_ENDPOINT}/openai/v1/conversations` with body `{}` → returns a `ConversationResource` with an `id` (e.g. `conv_...`).
2. `POST {PROJECT_ENDPOINT}/openai/v1/responses`, header `Foundry-Features: WorkflowAgents=V1Preview`, body:
   ```json
   {
     "agent_reference": {"type": "agent_reference", "name": "SMID-compass-workflow"},
     "conversation": "<conversation id from step 1>",
     "input": "<user message>"
   }
   ```
   This is the modern OpenAI-compatible Responses API, extended by Azure with `agent_reference` (the documented successor to a deprecated `agent` field removed in `api-version=v1`). Omitting `conversation` returns `HTTP 400 invalid_payload` ("Not defined", `param: conversation`) — a `conversation` resource is required for workflow-agent invocation; this was discovered via one exploratory call before the six test calls, documented here rather than treated as a blocking failure since it is a usage correction, not a schema incompatibility.
3. The response's `output` array contains, in order: `workflow_action` items (`kind: InvokeAzureAgent` / `EndConversation`, i.e. the executed node sequence), `message` items (each tagged with the `agent_reference` of the agent that produced it), and `file_search_call` items (tagged with the invoking agent, plus the actual search `queries` issued) — giving direct, read-only trace evidence of routing, node sequence, and tool activity without needing a separate trace API.

No older Assistants/Threads API, run-polling loop, or portal UI was used. The workflow definition itself was not read, exercised, or modified by any write call beyond the two documented above; Step 1's resource checks and Step 2's mechanism discovery were otherwise read-only (`GET /agents`, `GET /agents/{name}`, `GET /agents/{name}/versions`, `GET /openai/v1/vector_stores`).

## Step 1 — live resource verification

- All 6 prompt agents + 1 workflow agent confirmed present via `GET /agents?api-version=v1`: all `enabled` / `active`.
- All 3 vector stores confirmed present and `completed` via `GET /openai/v1/vector_stores`.
- `SMID-PassGuide` → `file_search` → `vs_VvDHhLobUnN8s9YC4uk83BWU` (matches target; not a source/historical ID).
- `SMID-WorkshopGuide` → `file_search` → `vs_HMvRtKkm9ew6RzyJ56zIeJvC` (matches target).
- `smid-compass-agent` → `file_search` → `vs_hUQ2f7P22jDSvP9cS9MhRYvM` (matches target).
- No source/historical vector-store or file IDs (`assistant-*` from the original tenant) appear in any live agent definition — all references are target-tenant IDs generated during Phases 5–7.
- No required resource was missing or unhealthy; Step 1 passed (workflow version drift noted above, not blocking).

## Step 3–4 — parity test results

| Test | Lang | Expected route | Observed route | Node sequence | Safety invoked? | File Search evidence | Lang. result | PASS/FAIL |
|---|---|---|---|---|---|---|---|---|
| A1 — Passport | ES | passport | **passport** | Router → PassGuide → Safety → End | Yes | `SMID-PassGuide`, 5 Spanish queries, `status: completed` | Bilingual ES+DE output (by design, see below) | **PASS** |
| A2 — Passport | DE | passport | **passport** | Router → PassGuide → Safety → End | Yes | `SMID-PassGuide`, 6 German queries, `status: completed` | Bilingual ES+DE output | **PASS** |
| B1 — Workshop | ES | workshop | **workshop** | Router → WorkshopGuide → Safety → End | Yes | `SMID-WorkshopGuide`, 4 Spanish queries, `status: completed` | Bilingual ES+DE output | **PASS** |
| B2 — Workshop | DE | workshop | **workshop** | Router → WorkshopGuide → Safety → End | Yes | `SMID-WorkshopGuide`, 4 German queries, `status: completed` | Bilingual ES+DE output | **PASS** |
| C1 — Out-of-scope | ES | out_of_scope | **out_of_scope** | Router → OutOfScopeAgent → End | **No** (bypassed) | none (no file_search tool on this agent) | Single-language Spanish, verbatim source template | **PASS** |
| C2 — Out-of-scope | DE | out_of_scope | **out_of_scope** | Router → OutOfScopeAgent → End | **No** (bypassed) | none | Single-language German, verbatim source template | **PASS** |

All six responses returned `status: completed`, `error: null`, `incomplete_details: null` on the first attempt (HTTP 200 on every `responses` call). No STOP conditions were triggered.

### Language-preservation note (important, resolved by checking source instructions)

The Spanish and German tests for Passport and Workshop (A1/A2/B1/B2) all return a response containing **both** a `SPANISH:` section and a `GERMAN:` section, regardless of which language the user typed in. This initially looked like a possible language-preservation defect for the German-input tests, but checking `source/agents/SMID-PassGuide.yaml`, `source/agents/SMID-WorkshopGuide.yaml`, and `source/agents/SMID-SafetyAgent.yaml` confirms this is the **intended source design**: these three agents are explicitly instructed to always produce a bilingual Spanish+German structure ("The German version must be a faithful translation of the Spanish content" / "Preserve bilingual structure (Spanish + German). Do not remove either language."). The live behavior matches this exactly — both sections are present, relevant, and (spot-checked) mutually consistent translations in all four tests.

`OutOfScopeAgent`, by contrast, is instructed with **separate single-language template replies** (`source/agents/OutOfScopeAgent.yaml`, one under `SPANISH:`, one under `GERMAN:`, as alternatives, not a required pair) and is expected to pick the one matching the input language. Live tests C1 and C2 each returned a single-language reply, **matching the corresponding source template nearly verbatim**, in the correct language for the input.

Conclusion: all observed language behavior is explained by, and consistent with, each agent's own preserved source instructions. No language-preservation defect was found.

### Response excerpts

**A1 (ES input):**
> SPANISH: 1. Respuesta corta — Para renovar tu pasaporte venezolano desde Alemania debes hacer el trámite a través del consulado venezolano en Berlín, usando el portal SAIME para s...
> GERMAN: 1. Kurze Antwort — Um deinen venezolanischen Reisepass aus Deutschland zu erneuern, musst du den Antrag über das venezolanische Konsulat in Berlin stellen, den regulären R...

**A2 (DE input):**
> SPANISH: 1. Respuesta corta — Para renovar tu pasaporte venezolano desde Alemania debes hacer el trámite a través del consulado venezolano en Alemania usando el portal SAIME, hace...
> GERMAN: 1. Kurze Antwort — Um deinen venezolanischen Reisepass von Deutschland aus zu erneuern, musst du den Antrag über das venezolanische Konsulat in Deutschland über das SAIME-...

**B1 (ES input):**
> SPANISH: 1. SMID ofrece talleres prácticos para aprender a usar herramientas digitales como Canva e inteligencia artificial, enfocados en crear contenido, organizar tu negocio y...
> GERMAN: 1. SMID bietet praktische Workshops an, in denen du lernst, digitale Tools wie Canva und KI zu nutzen, um Inhalte zu erstellen, dein Business zu organisieren und echte Ch...

**B2 (DE input):**
> SPANISH: 1. SMID ofrece talleres prácticos para aprender a usar herramientas digitales como Canva e Inteligencia Artificial, enfocados en crear contenido, organizar negocios y ge...
> GERMAN: 1. SMID bietet praktische Workshops an, in denen du digitale Werkzeuge wie Canva und Künstliche Intelligenz lernst, um Inhalte zu erstellen, dein Geschäft zu organisieren...

**C1 (ES input), full response:**
> Lo siento, en este momento solo puedo ayudarte con trámites de pasaporte venezolano y talleres digitales SMID.
> Si quieres, puedo orientarte en alguno de esos temas.

**C2 (DE input), full response:**
> Es tut mir leid, ich kann dir aktuell nur bei venezolanischen Pass- und Identitätsthemen sowie bei SMID-Workshops helfen.
> Wenn du möchtest, unterstütze ich dich gerne bei einem dieser Themen.

## Errors / warnings

- One exploratory call (before the 6 official tests) returned `HTTP 400 invalid_payload` for omitting the required `conversation` field. This was a usage-discovery step, not a test failure, and is documented above under "Invocation mechanism." No other errors occurred.
- The `SMID-compass-workflow` version-3 drift (comment-only, functionally identical) described above.
- No resource-reference errors from the tenant migration were observed in any test: all `agent_reference` values in every response correctly resolved to the expected target-tenant agents and versions.

## Overall conclusion

**PARITY SMOKE TEST PASSED.**

All 6 controlled tests passed. The migrated nonprofit DEV workflow (`SMID-compass-workflow`) is invokable end-to-end through the current, Microsoft-supported live API (`openai/v1/conversations` + `openai/v1/responses` with `agent_reference`), using only Entra/Azure CLI authentication. Routing, File Search knowledge retrieval, the Safety bypass for out-of-scope requests, and each agent's distinct language behavior all reproduce source-parity behavior in both Spanish and German. No modernization was performed or required to achieve this result.

## Known parity limitations / preserved source behavior

- `OutOfScopeAgent` bypasses `SMID-SafetyAgent` by design — this is a preserved source asymmetry, not a migration gap, and was re-confirmed live in tests C1/C2 (node sequence has no third `InvokeAzureAgent` before `EndConversation`).
- The known `SMID-SafetyAgent` input mismatch remains preserved: its instructions describe expecting `<route> | <answer>` as input, but the workflow sends only the answer text (`=Coalesce(Local.passport_answer, Local.workshop_answer)`). Not corrected during this migration or this validation.
- `LOPNA 2015.pdf`'s ingestion failure in the legacy `smid-compass-agent-legacy` vector store (`invalid_file`, no extractable content) remains a parity-preserved historical condition, reproducing the same failure present in the original source tenant.
- Microsoft Foundry declarative workflows (the `kind: workflow` resource type used here) are scheduled for retirement on 2026-12-01. This does not invalidate this parity validation. Migration to Microsoft Agent Framework remains intentionally deferred to the later Modernization v2 phase, after the nonprofit parity baseline (`nonprofit-parity-v1`) is created and accepted.
- The `SMID-compass-workflow` version-3 comment-only drift described above is a live-state observation from this validation, not a correction made by this validation.
