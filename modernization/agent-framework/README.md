# SMID Compass — Microsoft Agent Framework modernization (technical migration step)

**Status: local project created, workflow loads AND runs correctly end-to-end against the live Foundry agents (Spanish and German passport smoke tests both passed, 2026-11-16). Not deployed. Does not replace the validated Foundry workflow, which remains live and untouched.**

This is the first Modernization v2 step: a *technical* migration of the orchestration layer from Foundry's declarative `kind: workflow` resource to Microsoft Agent Framework, with **no behavior changes**. It reuses the existing, live, validated nonprofit DEV Foundry agents (`SMID-RouterAgent`, `SMID-PassGuide`, `SMID-WorkshopGuide`, `SMID-SafetyAgent`, `OutOfScopeAgent`) by name/version — it does not recreate their prompts, tools, File Search, vector stores, or guardrails.

Baseline: `nonprofit-parity-v1` (commit `3dc93c376ba5c688e04640fdb9e9ed744fe868d4`).

## Layout

```
modernization/agent-framework/
  pyproject.toml              dependency definition
  .env.example                variable NAMES only, no secrets
  workflows/
    SMID-compass-workflow.yaml  byte-identical copy of target/migration/workflow/SMID-compass-workflow.yaml
  src/smid_compass/
    config.py                  endpoint + agent name->version map (matches live Phase 6/8 state)
    agents.py                  builds FoundryAgent references to the existing live agents (no recreation)
    run_workflow.py            loads the YAML via WorkflowFactory and runs one message through it
```

The workflow YAML here is **not modified** from the validated baseline — verified with `diff` against `target/migration/workflow/SMID-compass-workflow.yaml` (byte-identical). It was not even necessary to translate the file's syntax: Agent Framework's declarative `WorkflowFactory` loads Foundry's own `kind: workflow` CSDL YAML directly (see "What was verified" below).

## Setup

```bash
cd modernization/agent-framework
python -m venv .venv
.venv/Scripts/python -m pip install -e .
```

Python 3.11–3.14 required (this project was built and tested on Python 3.11.9). Authentication reuses your existing `az login` session via `AzureCliCredential` — no API keys, no `.env` values are required for the default DEV endpoint baked into `config.py`, though `.env.example` documents the override variables.

**Known environment issue (Windows only):** importing `agent_framework.declarative` crashes with `UnicodeEncodeError` unless UTF-8 I/O is forced, because Microsoft's own `powerfx` package unconditionally prints a `✓` checkmark on import and Windows' default console codepage (cp1252) can't encode it. Always run with:

```bash
PYTHONUTF8=1 PYTHONIOENCODING=utf-8 .venv/Scripts/python -m smid_compass.run_workflow "your message"
```

This is a third-party packaging bug, not something introduced by this project.

## What was verified

- The unmodified Foundry workflow YAML **loads successfully** via `agent_framework.declarative.WorkflowFactory().create_workflow_from_yaml_path(...)` — no syntax translation was required.
- The resulting graph was inspected with `agent_framework.WorkflowViz` and matches the source topology exactly: Router → `ConditionGroup` (passport/workshop/otherwise) → PassGuide or WorkshopGuide → Safety → End, **and** otherwise → OutOfScope → End **bypassing Safety** — the critical asymmetry is preserved, not re-implemented.
- `FoundryAgent(project_endpoint=..., agent_name=..., agent_version=..., credential=AzureCliCredential())` (from `agent-framework-foundry`) is the correct, current mechanism for referencing an *existing* live Foundry PromptAgent — confirmed by inspecting the installed package's actual constructor signature (Microsoft's own docs page did not show the Python signature at the time of writing).
- `WorkflowFactory(agents={"SMID-RouterAgent": <FoundryAgent>, ...})` binds the YAML's bare agent-name references (`agent: {name: SMID-RouterAgent}`) to real live agent instances — confirmed by reading the installed `InvokeAzureAgentExecutor` source, which resolves names against this dict.
- Python syntax, imports, and configuration (endpoint, agent versions) all validate cleanly against the live nonprofit DEV values recorded in Phase 6/8 — no old source-tenant IDs are present anywhere in this project.

## Resolved: local .NET runtime installed, declarative YAML runs as-is

Running the workflow requires evaluating the YAML's Power Fx expressions (`=System.ConversationId`, `=Local.router_json.route = "passport"`, `=Coalesce(...)`) through a .NET-hosted Power Fx engine (`powerfx` Python package → `clr_loader` → .NET). This is Microsoft's own packaging choice inside a Python library, not something introduced by this project.

**Resolved on 2026-11-16** by installing only the .NET **Runtime** (not the SDK) locally:

```
winget install --id Microsoft.DotNet.Runtime.10 --exact --source winget
```

Verified: `dotnet --list-runtimes` → `Microsoft.NETCore.App 10.0.15`. The workflow YAML was **not modified or translated** — the exact same byte-identical copy from the validated baseline now runs successfully end-to-end. The project remains 100% Python; .NET is purely a local runtime dependency of Microsoft's Power Fx package, invisible to this project's own code.

### Local execution results (2026-11-16)

Both smoke tests from `tests/smoke_test.py` passed, invoking the real live Foundry agents (no mocks):

| Test | Router classification | Node sequence | Final answer |
|---|---|---|---|
| Spanish passport | `route: "passport"` | Router → PassGuide → Safety → End | Non-empty, bilingual (ES+DE), Safety visibly added a disclaimer sentence beyond PassGuide's answer |
| German passport | `route: "passport"` (correctly classified from German input) | Router → PassGuide → Safety → End | Non-empty, bilingual (ES+DE), same Safety disclaimer behavior |

Both runs produced exactly 3 outputs each (Router's JSON classification, PassGuide's raw answer, Safety's revised final answer) — consistent with the live Foundry workflow's behavior validated in Phase 8.

**Benign warning observed on every run** (not an error, does not affect output): `InvokeAzureAgent: failed to parse JSON for 'Local.passport_json': No valid JSON found in response: ... storing as string` — expected, since PassGuide's answer is bilingual prose, not JSON, and the engine's fallback (store as string) is correct behavior for this field, which is only consumed as a variable reference downstream, not actually required to be JSON.

**Update 2026-11-16:** the full 6-test suite (matching Phase 8 exactly: Passport/Workshop/Out-of-scope × Spanish/German) was run and **all 6 passed**, including explicit confirmation that `OutOfScopeAgent` still bypasses `SMID-SafetyAgent` in this translation. Full evidence, per-test traces, and a side-by-side comparison against Phase 8's Foundry results: [validation/agent-framework-smoke-validation.md](validation/agent-framework-smoke-validation.md). Raw per-test JSON traces: `validation/raw/`.

## Visual inspection options (current Microsoft tooling, investigated only — nothing installed/configured)

| Option | What it shows | Editable? | Suitable for a non-Python board member? |
|---|---|---|---|
| `agent_framework.WorkflowViz` (used above, no extra install) | Static graph as Mermaid/Graphviz text, or exported SVG/PNG/PDF (image export needs the separate `graphviz` system package) | Read-only | **Yes, for the exported image** — a static diagram needs no tooling to view, closest thing to the old portal's workflow canvas. No live trace data, though. |
| **Foundry Toolkit** (VS Code extension, renamed from "AI Toolkit") — **Agent Inspector** | Execution graph with node-to-source navigation; consolidates the former "Local Agent Playground" and "Local Visualizer" | Read-only (inspection/debugging, not a drag-and-drop editor) | No — requires VS Code + running a local dev server; developer tooling. |
| **DevUI Agent Inspector** (Agent Framework, public preview as of mid-2026) | Navigable tree of model calls, tool invocations, intermediate state, as a local sidecar process | Read-only | No — same reason, developer-facing. |

None of these were installed or configured in this task (out of scope — Step 8 was investigation only, not tooling selection). The static `WorkflowViz` export is the only one of the three that doesn't require running Python/VS Code to view, so it's the best current fit if the goal is something a non-technical stakeholder can open directly.

## Hosted Agent deployment readiness (investigated only — nothing deployed)

Deploying this as a Foundry Hosted Agent would require, per current Microsoft guidance:

- **New Azure infrastructure**: `azd provision`/`azd up` creates a **new resource group** containing a Foundry instance, project, model deployment, Application Insights, and a container registry — this is not a deploy into the existing `smid-compass-dev-a5bc33` resource, it provisions fresh infrastructure.
- **New RBAC**: the "Foundry Project Manager" role at project scope is required to create/deploy Hosted agents — not currently assigned for this task's purposes.
- **New tooling**: Azure Developer CLI (`azd`, reportedly ≥1.25.3) plus its `microsoft.foundry` extension; one third-party source also states the .NET 10 SDK is needed (would overlap with the Power Fx decision above).
- **Region constraint**: Hosted agents are reported as currently limited to **North Central US**, while our existing DEV resources are in **Sweden Central** — this alone may block an in-place hosted deployment and needs explicit confirmation before any deployment is attempted.
- **Networking**: provisioning needs outbound internet access to pull dependencies.
- Packaging: code deployment auto-detects `pyproject.toml`/`requirements.txt` for Python — this project's `pyproject.toml` would be usable as-is for that detection, once the project itself is runnable.

**None of this was created.** Per this task's boundaries, Hosted Agent deployment is explicitly out of scope until authorized.
