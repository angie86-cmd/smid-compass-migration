# SMID Compass — Microsoft Agent Framework modernization (technical migration step)

## Migration status

```
Local Agent Framework migration POC:        COMPLETE
Local execution against live Foundry agents: PASS
Parity smoke validation:                     6/6 PASS
Hosted Agent deployment to Azure DEV:        PENDING
Post-deployment DEV validation:              PENDING
Production deployment:                       NOT STARTED / NOT TOUCHED
```

The Agent Framework migration has been proven **locally** but has **not yet been executed as an Azure Hosted Agent deployment**. The next technical step is to deploy this validated implementation to the existing nonprofit Azure DEV environment, if supported, and repeat the validation against the hosted runtime. See [Next session — Hosted Agent deployment](#next-session--hosted-agent-deployment) below.

This is the first Modernization v2 step: a *technical* migration of the orchestration layer from Foundry's declarative `kind: workflow` resource to Microsoft Agent Framework, with **no behavior changes**. It reuses the existing, live, validated nonprofit DEV Foundry agents (`SMID-RouterAgent`, `SMID-PassGuide`, `SMID-WorkshopGuide`, `SMID-SafetyAgent`, `OutOfScopeAgent`) by name/version — it does not recreate their prompts, tools, File Search, vector stores, or guardrails. **The existing, validated Foundry declarative workflow (`SMID-compass-workflow`, live in nonprofit DEV) has not been deleted or modified, and remains the behavioral reference/fallback until a Hosted Agent deployment of this implementation is itself deployed and validated in DEV** — see [Keeping the declarative workflow as fallback](#keeping-the-declarative-workflow-as-fallback).

Baseline: `nonprofit-parity-v1` (commit `3dc93c376ba5c688e04640fdb9e9ed744fe868d4`).

## Layout

```
modernization/agent-framework/
  pyproject.toml              dependency definition (+ optional "hosting" extra)
  .env.example                variable NAMES only, no secrets
  Dockerfile                  Hosted Agent container image — NOT yet deployed, see below
  Dockerfile.local-test       local-testing-only derived image (adds az CLI); not for real deployment
  workflows/
    SMID-compass-workflow.yaml  byte-identical copy of target/migration/workflow/SMID-compass-workflow.yaml
  src/smid_compass/
    config.py                  endpoint + agent name->version map (matches live Phase 6/8 state)
    agents.py                  builds FoundryAgent references to the existing live agents (no recreation)
    run_workflow.py            loads the YAML via WorkflowFactory and runs one message through it
    host.py                    Hosted Agent adapter (ResponsesHostServer) — NOT yet deployed, see below
  validation/
    run_suite.py                 reproducible 6-test bilingual parity suite
    agent-framework-smoke-validation.md  full evidence, 6/6 PASS
    raw/                          per-test raw JSON traces
```

The workflow YAML here is **not modified** from the validated baseline — verified with `diff` against `target/migration/workflow/SMID-compass-workflow.yaml` (byte-identical). It was not even necessary to translate the file's syntax: Agent Framework's declarative `WorkflowFactory` loads Foundry's own `kind: workflow` CSDL YAML directly (see "What was verified" below).

## Setup

```bash
cd modernization/agent-framework
python -m venv .venv
.venv/Scripts/python -m pip install -e .
```

**Local development:** validated successfully using **Python 3.11.9** (the `pyproject.toml` range `>=3.11,<3.15` is unchanged — it reflects what `agent-framework-declarative` actually supports locally, not a Hosted Agent requirement). Authentication reuses your existing `az login` session via `AzureCliCredential` — no API keys, no `.env` values are required for the default DEV endpoint baked into `config.py`, though `.env.example` documents the one override variable the code actually reads (`FOUNDRY_PROJECT_ENDPOINT`).

**Hosted Agent deployment (not yet performed):** current Microsoft guidance for the Python Hosted Agent *runtime* (a separate concern from this local dev venv) names `python_3_13` and `python_3_14` as the supported `code_configuration.runtime` values, and states that packaging a source deployment locally needs `pip` from Python 3.13+. This is a deployment-time runtime choice, not a reason to change this project's local `pyproject.toml` — it will only need updating if a package actually requires it.

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

## Hosted Agent deployment readiness (re-verified 2026-11-16, investigated and locally container-tested only — nothing deployed to Azure)

**1. Deploying into the existing `smid-compass` project is supported.** `azd ai agent init --project-id "<existing-project-resource-id>" ...` targets an existing Foundry project directly — this is a documented flow, not brand-new infrastructure by default. Caveat straight from the docs: *"Selecting an existing project doesn't automatically eliminate this step. Provisioning can still create missing resources declared in `azure.yaml`, such as a model deployment."* We do not need a new model deployment — the orchestration calls the existing live agents, which already use the existing `gpt-4.1-mini` deployment.

**2. This project needs the `container` deployment mode, not `code` (source) deployment — confirmed by the hybrid-runtime requirement.** Our code is Python, but the declarative workflow engine (`agent_framework.declarative` → `powerfx` → `clr_loader`) requires **CoreCLR/.NET 10** to evaluate the YAML's Power Fx expressions. Microsoft's documented Python Hosted Agent *source*-deployment runtimes (`python_3_13`, `python_3_14`) are **plain Python — they do not bundle a .NET runtime**, and nothing in Microsoft's docs suggests `--deploy-mode code` lets you add one. **Recommended option: a `container` deployment** (Linux x86_64) that bundles Python 3.13, .NET Runtime 10, and our Python dependencies ourselves — this is the only path that preserves the declarative YAML unmodified rather than rewriting the routing in Python. Prepared as `Dockerfile` in this directory:
   - Base: `python:3.13-slim-bookworm` (`linux/amd64`)
   - .NET Runtime 10 installed via Microsoft's official `dotnet-install.sh` script, pinned to the same `10.0.15` validated locally — runtime only, no SDK, same approach as the local install
   - `ENV PYTHONNOUSERSITE=1` as Microsoft's container docs require, plus `PYTHONUTF8=1`/`PYTHONIOENCODING=utf-8` (our own Windows-only finding, harmless to set on Linux too)
   - The **Hosted Agent adapter** (`src/smid_compass/host.py`, new): wraps the workflow using `agent_framework_foundry_hosting.ResponsesHostServer(workflow=build_workflow, parse_response=parse_response)` — the `workflow=` parameter (a fresh-graph-per-request factory), **not** the deprecated `agent=workflow.as_agent()` pattern Microsoft explicitly warns against for stateful workflows served to multiple concurrent users. `agent-framework-foundry-hosting` is an optional `pyproject.toml` extra (`pip install -e ".[hosting]"`, currently prerelease per Microsoft's own docs) — not a hard dependency of the already-validated local path.

**3. Local container test results (2026-11-16):**
   - Image built successfully: `docker build --platform linux/amd64 -t smid-compass-agent-framework:local-test .`
   - ✅ **Power Fx/.NET import succeeds inside the Linux container** — `agent_framework.declarative` and `agent_framework.foundry` both import cleanly.
   - ✅ **The unmodified workflow YAML loads correctly inside the container**, same graph as validated locally on Windows. Interestingly, the `powerfx` package's checkmark-printing startup message that crashes on Windows (see above) **printed fine on Linux without `PYTHONUTF8`** — confirming that bug is Windows-codepage-specific, not a problem for the real (Linux) Hosted Agent container.
   - ⚠️ **The six live-agent tests could not be completed inside this container**, for a testing-infrastructure reason, not a code defect: `AzureCliCredential` shells out to the `az` CLI, and Azure CLI's Windows token cache (`~/.azure`) is encrypted with Windows DPAPI, which a Linux container cannot decrypt — mounting the host's `~/.azure` into the container produces `Please run 'az login' to set up an account` even though the host is already logged in. This is a **local Windows→Linux credential-portability limitation of this specific test setup**, not something that would occur in the real deployed Hosted Agent (which would use its platform-issued managed identity, not `AzureCliCredential`, at that point — see point 7). Running a fresh `az login` (device-code flow) *inside* the container would resolve this for local testing, but that's a new interactive login step — per the authentication rules for this project, **I'm reporting this rather than attempting it myself.** If you want full live-agent container testing, the next session should either run `az login --use-device-code` inside the container, or move straight to the real deployment (where the credential question is moot).
   - Separately discovered and fixed on the **Windows host** (unrelated to the container): installing `agent-framework-foundry-hosting --pre` pulled a newly-published `regex` package release that Windows blocked with `Eine Anwendungssteuerungsrichtlinie hat diese Datei blockiert` (an application-control/endpoint-security policy blocking a just-downloaded, not-yet-trusted DLL) — I did not touch any Windows security policy; fixed by pinning `regex` to the previous release. This also doesn't apply to the Linux container.
   - A **local-testing-only** derived image (`Dockerfile.local-test`, adds `azure-cli` + a forced `azure-ai-projects` version fix) was used for the above — it is explicitly **not** representative of the real deployment image (see point 7) and should not be used for anything beyond this kind of local diagnostic.

**4. `azd` mechanism (container-deployment path):** `azd ai agent init --project-id "<id>" --deploy-mode container ...`, then `azd up` (or `azd provision` + `azd deploy` separately). Inspect with `azd ai agent show`/`azd ai agent monitor --follow`; invoke with `azd ai agent invoke`; tear down with `azd down`. Prerequisites: Azure CLI ≥2.80, the Foundry Dev Pack (installs `azd` and the Foundry extensions) or `azd ext install azure.ai.agents` directly — **Microsoft's own pages disagree on the minimum `azd` version** (1.27.1 in one prerequisites list, 1.36.0 in the same page's troubleshooting section); `azd` itself is **not installed on this machine** (confirmed: `azd` command not found) — would need installing and version-verified (`azd version`) before any deployment, not assumed.

**5. RBAC for deploying into our existing project:** **"Foundry Project Manager"** role **at project scope** — this is what's actually needed for our case (an existing project), *not* the `Owner` role at resource-group scope, which Microsoft's docs reserve for *creating a brand-new* project. Separately, invoking the deployed agent needs **Foundry Agent Consumer** (invoke-only) or **Foundry User** (develop + invoke) at project scope. For the container path specifically, pushing the image needs **Container Registry Repository Writer** or **AcrPush** on the ACR (tooling handles **Container Registry Repository Reader** for the project's managed identity automatically, per Microsoft's docs). **None of these roles were checked or assigned** — `az role assignment list` was not run against the live subscription as part of this task, since that itself edges toward deployment prep requiring your go-ahead; confirm/request before deployment.

**6. Sweden Central is officially supported for Foundry Hosted Agents.** Confirmed directly against Microsoft's current "[Hosted agents in Foundry Agent Service](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/hosted-agents)" page (ms.date 2026-11-09), which explicitly lists **Sweden Central** in its region-availability list (alongside Norway East, Poland Central, Spain Central, Switzerland North, and others), with the note that the list is updated as more regions become available. **We stay in Sweden Central, targeting the existing `smid-compass` project — no region change and no new project**, per your instruction. (This replaces the earlier "must be verified" wording in this README, which was based on weaker indirect evidence at the time.)

**7. Resources this deployment would actually create — the honest accounting (none created yet):**

| Resource | New or reused? | Notes |
|---|---|---|
| Foundry project (`smid-compass`) | **Reused** | No new project, per your instruction. |
| Region (Sweden Central) | **Reused** | No region change, per your instruction, and now confirmed supported (point 6). |
| Model deployment (`gpt-4.1-mini`) | **Reused** | The orchestration calls existing agents; no new model deployment should be declared in `azure.yaml`. |
| **Azure Container Registry** | **Likely new** | `smid-compass-dev-a5bc33` has no ACR today (not part of the Terraform foundation) — the container path needs one to push the built image to. Basic SKU would suffice for a single small image. |
| **Hosted Agent resource itself** | **New** | The actual hosted-agent entity within the existing project — this is the thing being deployed. |
| **Dedicated Entra agent identity** | **New, automatic** | Microsoft's docs state the platform creates one per hosted agent at deploy time; not something we provision manually. |
| Application Insights | **Reused** | Already provisioned by Terraform for `smid-compass-dev`; container deployments get an auto-injected connection string, no new resource expected. |
| **RBAC role assignments** (point 5) | **New** | Not infrastructure, but new access grants, needed before deployment. |
| **Credential mechanism for the deployed container** | **Needs a code decision, not made here** | `agents.py` currently uses `AzureCliCredential()`, which has no `az login` session inside a real deployed container — it would need `ManagedIdentityCredential`/`DefaultAzureCredential` (using the Entra agent identity from the row above) instead. **This is a real code change, not yet made** — flagging it rather than silently changing `agents.py`, since you asked not to change the logic/agents without approval. |

**8. Cost — I could not get verified numbers, and won't invent any.** Azure's public Foundry Agent Service pricing pages list Hosted Agent compute as billed per **vCPU-hour + GiB-hour** of the sandbox size used (0.5 vCPU/1 GiB, 1 vCPU/2 GiB, or 2 vCPU/4 GiB), separate from model-token costs (already being incurred today regardless, via the existing agents) — but the actual rate figures on Microsoft's pricing pages were blank placeholders in what I could fetch. A small Basic-SKU Azure Container Registry is a well-documented, low, roughly-$5/month-class cost, but I'm not treating that as precise either. **Recommend checking the Azure Pricing Calculator directly, or your Azure sales/billing contact, for real numbers before deciding** — I did not want to report invented figures as fact.

**Nothing in this section was created, assigned, or deployed** — no `azd` commands were run against Azure, no ACR was created, no RBAC was assigned, no container was pushed. Per this task's boundaries, Hosted Agent deployment is explicitly out of scope until authorized. See [Next session — Hosted Agent deployment](#next-session--hosted-agent-deployment) for the concrete checklist.

## Keeping the declarative workflow as fallback

The existing, validated Foundry declarative workflow (`SMID-compass-workflow`, live in nonprofit DEV, validated in Phase 8) has **not** been deleted, modified, or touched by this modernization work, and is not planned to be. It remains available as the behavioral reference and operational fallback until a Hosted Agent deployment of this Agent Framework implementation is itself deployed to Azure DEV and independently validated there. This matters especially because Microsoft is retiring declarative Foundry workflows on **2026-12-01** — until the Hosted Agent path is proven in DEV, the declarative workflow is still the only *deployed* working implementation, and should not be removed or altered as part of this work.

## Next session — Hosted Agent deployment

**Do not rebuild the migration from scratch.** The working implementation already lives in `modernization/agent-framework/`, and its validation evidence is already in `modernization/agent-framework/validation/`. The next session should continue from this state, starting with:

1. Re-check current Microsoft Hosted Agent documentation (it moves fast; re-verify the facts above, including the `azd` version disagreement).
2. Install and verify `azd` (not installed on this machine as of 2026-11-16) and the Foundry extension; confirm the actual version with `azd version` rather than trusting either number in point 4 above.
3. Confirm the required RBAC (**Foundry Project Manager** at project scope for deploy; **Container Registry Repository Writer**/**AcrPush** for pushing the image) is actually assignable/assigned — `az role assignment list` was not run this session.
4. **Decide and implement the deployed container's credential mechanism** (point 7's table, last row): replace or branch `agents.py`'s `AzureCliCredential()` with `ManagedIdentityCredential`/`DefaultAzureCredential` for the container path specifically, since the real Hosted Agent container has no `az login` session — this is a real code change needing its own review, not something to do silently.
5. Create the Azure Container Registry (Basic SKU is likely sufficient) if one doesn't already exist for `smid-compass-dev-a5bc33`.
6. Build and push the image (`Dockerfile` in this directory — not `Dockerfile.local-test`, which is diagnostic-only) via `azd deploy` or `docker push`.
7. Prepare the deployment command/configuration (`azure.yaml`, `azd ai agent init --project-id "<smid-compass project id>" --deploy-mode container`).
8. Deploy to **DEV only**, once explicitly authorized.
9. Run the same six parity smoke tests (`validation/run_suite.py`) against the deployed Hosted Agent (this time credential-complete, unlike the local container test in point 3 above).
10. Compare results against both Phase 8 (original Foundry workflow) and this local Agent Framework validation (`validation/agent-framework-smoke-validation.md`).
11. Document Hosted Agent DEV validation before any production decision — production remains untouched until then.

## Current modernization status

- Agent Framework local POC: **COMPLETE**
- Existing live Foundry agents reused successfully (not recreated)
- Existing workflow semantics preserved (byte-identical YAML, zero redesign)
- Local runtime validation: **PASS**
- 6-test parity suite: **6/6 PASS**
- Hosted Agent deployment: **PENDING**
- Azure DEV Hosted Agent validation: **PENDING**
- Production: **UNTOUCHED**
- Next major task: Hosted Agent deployment into DEV and post-deployment validation

This is a **technical parity smoke validation**, not exhaustive QA, and not yet a production-ready or fully-Azure-deployed migration. See [validation/agent-framework-smoke-validation.md](validation/agent-framework-smoke-validation.md) for the documented scope and limitations (no detailed File Search call trace at this layer, no independent RAI re-verification, no multi-turn/malformed-route testing, no Hosted Agent deployment, no production traffic).
