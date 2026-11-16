# Agent Framework modernization — smoke validation evidence

**Validation date:** 2026-11-16
**Scope:** Technical-migration smoke test of the Microsoft Agent Framework translation of `SMID-compass-workflow`, run locally against the real, live nonprofit DEV Foundry agents (no mocks, no recreated agents). Mirrors the 6 tests from [docs/validation/phase-8-parity-validation.md](../../../docs/validation/phase-8-parity-validation.md) for direct comparison against the original Foundry declarative workflow.
**Baseline:** `nonprofit-parity-v1` (commit `3dc93c376ba5c688e04640fdb9e9ed744fe868d4`). Workflow YAML used: `modernization/agent-framework/workflows/SMID-compass-workflow.yaml`, verified byte-identical to `target/migration/workflow/SMID-compass-workflow.yaml`.

## Environment

- Runner: `validation/run_suite.py`, invoking `agent_framework.declarative.WorkflowFactory` with `agents={"SMID-RouterAgent": FoundryAgent(...), ...}` bound to the live agents (`SMID-RouterAgent` v2, `SMID-PassGuide` v1, `SMID-WorkshopGuide` v1, `SMID-SafetyAgent` v1, `OutOfScopeAgent` v1).
- Auth: `AzureCliCredential` (existing `az login` session), no API keys.
- Runtime: Python 3.11.9 in the project's `.venv`; .NET Runtime 10.0.15 installed locally (`winget install Microsoft.DotNet.Runtime.10`, runtime only, no SDK) to satisfy the declarative engine's Power Fx expression evaluator (`powerfx` → `clr_loader` → .NET). Required env: `PYTHONUTF8=1 PYTHONIOENCODING=utf-8` (works around an unrelated encoding bug in Microsoft's own `powerfx` package on Windows, see project `README.md`).
- Raw per-test evidence (full event trace + full outputs, JSON): `validation/raw/<test_id>.json`.

## Node ID → agent name map

| Node ID in trace | Meaning |
|---|---|
| `node-1777738401900` | `SMID-RouterAgent` |
| `node-1777744904959` | `SMID-PassGuide` |
| `node-1777753695596` | `SMID-WorkshopGuide` |
| `node-1777753679454` | `OutOfScopeAgent` |
| `agent3` | `SMID-SafetyAgent` |
| `node-1777755417417` | `EndConversation` (out-of-scope branch, bypasses Safety) |
| `node-1777739592716` | `EndConversation` (main branch, after Safety) |

## Results summary

**6 / 6 PASS. No failures found in this run — nothing to debug.** Every test produced the expected router route, the expected node sequence (including the Safety bypass for out-of-scope), a non-empty and relevant final answer, and no errors or exceptions.

| Test | Lang | Prompt | Expected route | Observed route | Node sequence | Safety invoked? | Outputs | PASS/FAIL |
|---|---|---|---|---|---|---|---|---|
| A1 — Passport | ES | *Necesito renovar mi pasaporte venezolano desde Alemania. ¿Qué debo hacer?* | passport | **passport** | Router → PassGuide → Safety | Yes | 3 | **PASS** |
| A2 — Passport | DE | *Ich muss meinen venezolanischen Reisepass von Deutschland aus erneuern. Was muss ich tun?* | passport | **passport** | Router → PassGuide → Safety | Yes | 3 | **PASS** |
| B1 — Workshop | ES | *¿Qué talleres ofrece SMID y cómo puedo participar?* | workshop | **workshop** | Router → WorkshopGuide → Safety | Yes | 3 | **PASS** |
| B2 — Workshop | DE | *Welche Workshops bietet SMID an und wie kann ich daran teilnehmen?* | workshop | **workshop** | Router → WorkshopGuide → Safety | Yes | 3 | **PASS** |
| C1 — Out-of-scope | ES | *¿Cuál es la temperatura en Marte hoy?* | out_of_scope | **out_of_scope** | Router → OutOfScopeAgent | **No** (bypassed) | 2 | **PASS** |
| C2 — Out-of-scope | DE | *Wie ist das Wetter heute auf dem Mars?* | out_of_scope | **out_of_scope** | Router → OutOfScopeAgent | **No** (bypassed) | 2 | **PASS** |

No exceptions were raised in any of the 6 runs (`error: None` in every raw JSON file).

## Per-test detail

### A1 — Passport, Spanish
- Router output: `{"route":"passport","reason":"User asks about renewing Venezuelan passport from abroad."}`
- Final answer: 5628 chars, bilingual (both `SPANISH:` and `GERMAN:` sections present), Safety visibly revised PassGuide's answer.
  - SP: *"SPANISH: 1. Respuesta corta — Para renovar tu pasaporte venezolano desde Alemania debes hacer el trámite a través del consulado venezolano en Alemania, usando el portal..."*
  - DE: *"GERMAN: 1. Kurze Antwort — Um deinen venezolanischen Reisepass von Deutschland aus zu erneuern, musst du den Antrag über das venezolanische Konsulat in Deutschland über..."*

### A2 — Passport, German
- Router output: `{"route":"passport","reason":"User asks about renewing Venezuelan passport from Germany."}` — correctly classified from German input.
- Final answer: 5173 chars, bilingual.
  - SP: *"SPANISH: 1. Respuesta corta — Para renovar tu pasaporte venezolano desde Alemania, debes hacer la solicitud en línea en el portal SAIME, seleccionar el consulado venezol..."*
  - DE: *"GERMAN: 1. Kurze Antwort — Um deinen venezolanischen Reisepass von Deutschland aus zu erneuern, musst du den Antrag online im SAIME-Portal stellen, das venezolanische Ko..."*

### B1 — Workshop, Spanish
- Router output: `{"route":"workshop","reason":"User asks about SMID workshops and participation."}`
- Final answer: 2778 chars, bilingual.
  - SP: *"SPANISH: 1. SMID ofrece talleres prácticos para aprender a usar herramientas digitales como Canva e inteligencia artificial, enfocados en crear contenido, organizar tu..."*
  - DE: *"GERMAN: 1. SMID bietet praktische Workshops an, in denen du lernst, digitale Werkzeuge wie Canva und KI zu nutzen, um Inhalte zu erstellen, dein Geschäft zu organisiere..."*

### B2 — Workshop, German
- Router output: `{"route":"workshop","reason":"User asks about SMID workshops and participation."}` — correctly classified from German input.
- Final answer: 2935 chars, bilingual.
  - SP: *"SPANISH: 1. SMID ofrece talleres prácticos para aprender a usar herramientas digitales como Canva e inteligencia artificial, crear contenido, organizar tu negocio y gen..."*
  - DE: *"GERMAN: 1. SMID bietet praktische Workshops an, in denen du lernst, digitale Tools wie Canva und KI zu nutzen, Inhalte zu erstellen, dein Business zu organisieren und C..."*

### C1 — Out-of-scope, Spanish
- Router output: `{"route":"out_of_scope","reason":"Request is unrelated to passport or workshop topics."}`
- Node sequence stops at `OutOfScopeAgent` — `agent3` (Safety) never appears in the trace. Confirms the bypass asymmetry survived the translation.
- Full answer (166 chars), **near-verbatim match to the source template** in `source/agents/OutOfScopeAgent.yaml` and to Phase 8's live Foundry result: *"Lo siento, en este momento solo puedo ayudarte con trámites de pasaporte venezolano y talleres digitales SMID. Si quieres, puedo orientarte en alguno de esos temas."*

### C2 — Out-of-scope, German
- Router output: `{"route":"out_of_scope","reason":"Request is unrelated to passport or workshop topics."}` — correctly classified from German input.
- Node sequence stops at `OutOfScopeAgent`, Safety bypassed.
- Full answer (193 chars), near-verbatim match to source template and Phase 8: *"Es tut mir leid, ich kann dir aktuell nur bei venezolanischen Pass- und Identitätsthemen sowie bei SMID-Workshops helfen. Wenn du möchtest, unterstütze ich dich gerne bei einem dieser Themen."*

## Comparison against Phase 8 (original Foundry declarative workflow)

| Behavior | Phase 8 (Foundry) | This run (Agent Framework) | Match? |
|---|---|---|---|
| Router classifies ES/DE correctly | Yes | Yes | ✅ |
| Passport → PassGuide, Workshop → WorkshopGuide | Yes | Yes | ✅ |
| Safety runs after passport/workshop | Yes | Yes | ✅ |
| Safety bypassed for out-of-scope | Yes | Yes | ✅ |
| Bilingual ES+DE output for PassGuide/WorkshopGuide/Safety | Yes | Yes | ✅ |
| Single-language, template-matching output for OutOfScopeAgent | Yes | Yes | ✅ |
| Workflow reaches a terminal/End state | Yes | Yes (via `EndConversation` executors) | ✅ |

No behavioral differences were found between the two implementations in this smoke test. This is expected, since the same unmodified workflow YAML and the same live agents are used in both — the only thing that changed is the orchestration runtime (Foundry's own `kind: workflow` engine vs. Agent Framework's declarative `WorkflowFactory`).

## Known non-issues observed on every run

- `InvokeAzureAgent: failed to parse JSON for 'Local.passport_json'/'Local.workshop_json'/'Local.outOfScope_json': No valid JSON found in response: ..., storing as string` — printed once per agent-invoking node whose answer isn't JSON (i.e. every node except the Router). This is the declarative engine's expected fallback behavior for a field that's only used as a string variable downstream; it does not affect routing, outputs, or final answers. Not investigated further since it isn't a failure.
- A `dotnet --version`/SDK-resolution message can appear if an unrelated shell command (not this project's code) is run against the PATH before the Python process starts; it does not come from this project and does not affect test results.

## What is NOT yet covered by this validation

- File Search / vector-store evidence per call (Phase 8's Foundry trace exposed `file_search_call` items with the exact queries issued; this project's current event trace does not surface that level of detail — it would need deeper instrumentation of `AgentExecutor`/`FoundryAgent` telemetry to extract, not attempted here).
- Guardrail (RAI policy) enforcement evidence — assumed inherited automatically since the same live Foundry agents (with their guardrail associations) are invoked; not independently re-verified here.
- Conversation closing / malformed-route / multi-turn edge cases — out of scope for this smoke test, as in Phase 8.
- No Hosted Agent deployment, no production traffic — this is local-only, same as Phase 8 was live-API-only.
