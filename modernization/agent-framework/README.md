# SMID Compass — Microsoft Agent Framework modernization (technical migration step)

## Migration status

```
Local Agent Framework migration POC:         COMPLETE
Local execution against live Foundry agents: PASS
Parity smoke validation:                     6/6 PASS
Hosted Agent adapter (host.py) local test:   PASS (full /responses round trip, 2026-11-19)
Azure DEV pre-deployment prep (ACR, RBAC):    DONE (2026-11-19) — see below
Hosted Agent deployment to Azure DEV:         DEPLOYED and ACTIVE (2026-11-20) — see below
Post-deployment DEV validation:               PASS — passport, workshop, out-of-scope all routed and answered correctly, no errors (2026-11-20)
Production deployment:                        NOT STARTED / NOT TOUCHED
```

The Agent Framework migration is now **deployed and validated in Azure DEV as a real Foundry Hosted Agent** (`smid-compass-agent-framework:1`, status `active`), not just locally. It reuses the existing live Foundry agents, the existing `smid-compass` project, and the existing ACR — no new project, model, or region. Three real queries (passport, workshop, out-of-scope) were run against the deployed agent and all routed and answered correctly with no errors. See [Hosted Agent deployment readiness](#hosted-agent-deployment-readiness-updated-2026-11-19--azure-dev-prep-done-container-validated-end-to-end-locally-hosted-agent-itself-still-not-deployed) below for the full deployment record, including two real deployment-time issues found and fixed.

This is the first Modernization v2 step: a *technical* migration of the orchestration layer from Foundry's declarative `kind: workflow` resource to Microsoft Agent Framework, with **no behavior changes**. It reuses the existing, live, validated nonprofit DEV Foundry agents (`SMID-RouterAgent`, `SMID-PassGuide`, `SMID-WorkshopGuide`, `SMID-SafetyAgent`, `OutOfScopeAgent`) by name/version — it does not recreate their prompts, tools, File Search, vector stores, or guardrails. **The existing, validated Foundry declarative workflow (`SMID-compass-workflow`, live in nonprofit DEV) has not been deleted or modified, and remains the behavioral reference/fallback until a Hosted Agent deployment of this implementation is itself deployed and validated in DEV** — see [Keeping the declarative workflow as fallback](#keeping-the-declarative-workflow-as-fallback).

Baseline: `nonprofit-parity-v1` (commit `3dc93c376ba5c688e04640fdb9e9ed744fe868d4`).

## Layout

```
modernization/agent-framework/
  pyproject.toml              dependency definition, exact-pinned (+ optional "hosting" extra)
  constraints.txt             pip constraints pinning behavior-critical transitive deps
  .env.example                variable NAMES only, no secrets (exempted from .gitignore's .env.* rule)
  .dockerignore                build-context hygiene for the Dockerfile
  .agentignore                 azd/Foundry packaging ignore (mirrors Microsoft's own samples)
  azure.yaml                   azd deployment config — NOT yet deployed, validated with `azd show`
  Dockerfile                  Hosted Agent container image — NOT yet deployed, see below
  Dockerfile.local-test       local-testing-only derived image (adds az CLI); not for real deployment
  workflows/
    SMID-compass-workflow.yaml  byte-identical copy of target/migration/workflow/SMID-compass-workflow.yaml
  scripts/
    validate_runtime.py         build-time (and re-runnable) Python/.NET/Power Fx/workflow validation
  src/smid_compass/
    config.py                  endpoint + agent name->version map (matches live Phase 6/8 state)
    agents.py                  builds FoundryAgent references to the existing live agents (no recreation)
    run_workflow.py            loads the YAML via WorkflowFactory and runs one message through it
    host.py                    Hosted Agent adapter (ResponsesHostServer) — validated locally, not yet deployed
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

**Local development:** validated successfully using **Python 3.11.9** (the `pyproject.toml` range `>=3.11,<3.15` is unchanged — it reflects what `agent-framework-declarative` actually supports locally, not a Hosted Agent requirement). Authentication uses `DefaultAzureCredential` — locally this resolves via your existing `az login` session (`AzureCliCredential`, inside the chain); no API keys, no `.env` values are required for the default DEV endpoint baked into `config.py`, though `.env.example` documents the one override variable the code actually reads (`FOUNDRY_PROJECT_ENDPOINT`).

**Hosted Agent deployment (not yet performed):** current Microsoft guidance for the Python Hosted Agent *runtime* (a separate concern from this local dev venv) names `python_3_13` and `python_3_14` as the supported `code_configuration.runtime` values, and states that packaging a source deployment locally needs `pip` from Python 3.13+. This is a deployment-time runtime choice, not a reason to change this project's local `pyproject.toml` — it will only need updating if a package actually requires it.

**Known environment issue (Windows only):** importing `agent_framework.declarative` crashes with `UnicodeEncodeError` unless UTF-8 I/O is forced, because Microsoft's own `powerfx` package unconditionally prints a `✓` checkmark on import and Windows' default console codepage (cp1252) can't encode it. Always run with:

```bash
PYTHONUTF8=1 PYTHONIOENCODING=utf-8 .venv/Scripts/python -m smid_compass.run_workflow "your message"
```

This is a third-party packaging bug, not something introduced by this project.

## What was verified

- The unmodified Foundry workflow YAML **loads successfully** via `agent_framework.declarative.WorkflowFactory().create_workflow_from_yaml_path(...)` — no syntax translation was required.
- The resulting graph was inspected with `agent_framework.WorkflowViz` and matches the source topology exactly: Router → `ConditionGroup` (passport/workshop/otherwise) → PassGuide or WorkshopGuide → Safety → End, **and** otherwise → OutOfScope → End **bypassing Safety** — the critical asymmetry is preserved, not re-implemented.
- `FoundryAgent(project_endpoint=..., agent_name=..., agent_version=..., credential=DefaultAzureCredential())` (from `agent-framework-foundry`) is the correct, current mechanism for referencing an *existing* live Foundry PromptAgent — confirmed by inspecting the installed package's actual constructor signature (Microsoft's own docs page did not show the Python signature at the time of writing). `DefaultAzureCredential`, not a hardcoded `AzureCliCredential`, so the same code authenticates correctly both locally (`az login`) and in a deployed Hosted Agent container (platform-issued managed identity) — see "Hosted Agent deployment readiness" below for the real local-vs-hosted test evidence.
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

## Hosted Agent deployment readiness (updated 2026-11-19 — Azure DEV prep done, container validated end-to-end locally, Hosted Agent itself still not deployed)

**1. Deploying into the existing `smid-compass` project is supported.** `azd ai agent init --project-id "<existing-project-resource-id>" ...` targets an existing Foundry project directly — this is a documented flow, not brand-new infrastructure by default. Caveat straight from the docs: *"Selecting an existing project doesn't automatically eliminate this step. Provisioning can still create missing resources declared in `azure.yaml`, such as a model deployment."* We do not need a new model deployment — the orchestration calls the existing live agents, which already use the existing `gpt-4.1-mini` deployment.

**2. This project needs the `container` deployment mode, not `code` (source) deployment — confirmed by the hybrid-runtime requirement.** Our code is Python, but the declarative workflow engine (`agent_framework.declarative` → `powerfx` → `clr_loader`) requires **CoreCLR/.NET 10** to evaluate the YAML's Power Fx expressions. Microsoft's documented Python Hosted Agent *source*-deployment runtimes (`python_3_13`, `python_3_14`) are **plain Python — they do not bundle a .NET runtime**, and nothing in Microsoft's docs suggests `--deploy-mode code` lets you add one. **Recommended option: a `container` deployment** (Linux x86_64) that bundles Python 3.13, .NET Runtime 10, and our Python dependencies ourselves — this is the only path that preserves the declarative YAML unmodified rather than rewriting the routing in Python. Prepared as `Dockerfile` in this directory:
   - Base: `python:3.13-slim-bookworm` (`linux/amd64`)
   - .NET Runtime 10 installed via Microsoft's official `dotnet-install.sh` script, pinned to the same `10.0.15` validated locally — runtime only, no SDK, same approach as the local install
   - `ENV PYTHONNOUSERSITE=1` as Microsoft's container docs require, plus `PYTHONUTF8=1`/`PYTHONIOENCODING=utf-8` (our own Windows-only finding, harmless to set on Linux too)
   - The **Hosted Agent adapter** (`src/smid_compass/host.py`, new): wraps the workflow using `agent_framework_foundry_hosting.ResponsesHostServer(workflow=build_workflow, parse_response=parse_response)` — the `workflow=` parameter (a fresh-graph-per-request factory), **not** the deprecated `agent=workflow.as_agent()` pattern Microsoft explicitly warns against for stateful workflows served to multiple concurrent users. `agent-framework-foundry-hosting` is an optional `pyproject.toml` extra (`pip install -e ".[hosting]"`, currently prerelease per Microsoft's own docs) — not a hard dependency of the already-validated local path.

**3. Local container test results — now including a full, successful, authenticated `/responses` round trip (2026-11-19):**
   - Image built for `linux/amd64`, tagged `smid-compass-agent-framework:dev`, pinned to **exact** .NET Runtime `10.0.15` (not just "channel 10.0", which can silently drift — see Dockerfile and Task 3 below), with a build-time validation step (`scripts/validate_runtime.py`) that fails the build itself if Python/.NET/Power Fx/the workflow don't match what was actually tested. Build-time output confirmed: `Python 3.13.18`, `.NET runtime 10.0.15`, Power Fx/CoreCLR imports clean, workflow YAML built with the expected 9 executors.
   - ✅ `GET /readiness` → `{"status":"healthy"}`.
   - ✅ `POST /responses` → **full success**, `status: "completed"`, 3 output messages (Router JSON → PassGuide bilingual answer → Safety's revised bilingual answer with disclaimer) — the exact same sequence validated throughout this project, now proven through the real Hosted Agent HTTP adapter, running locally with `DefaultAzureCredential` resolving via the host's `az login` session.
   - **Three real code defects were found and fixed in `src/smid_compass/host.py` while getting there** (not credential/auth issues — found and fixed with credentials working, on this Windows host, before even touching the container):
     1. `ResponsesHostServer`'s `workflow=` factory must accept one request argument (`def build_workflow(request: HostedResponseRequest)`), not zero — its internal signature check rejected a zero-arg factory with `TypeError: A workflow factory must accept one request argument.`
     2. `HostedResponseRequest.get_input_text()` is `async` — calling it without `await` silently passed a coroutine object as the workflow's input instead of a string, failing deep inside the workflow's typed-input validation with a generic, swallowed error. `parse_response` is now `async` and awaits it.
     3. The hosting library checkpoints workflow state by pickling it, and refuses (reasonably, for security) to deserialize object types not on an explicit allowlist. The declarative engine's own internal node-result types (`ActionTrigger`, `ActionComplete`, `ConditionResult`, `LoopIterationResult` from `agent_framework_declarative._workflows._declarative_base`) aren't allowlisted by default — `main()` now passes `checkpoint_store_provider=CheckpointStoreProvider(allowed_checkpoint_types=[...])` naming all four.
   - Also required in `src/smid_compass/agents.py`: `FoundryAgent(..., default_options={"store": False})` — the hosting library requires storing clients (the Foundry agents' default) to explicitly opt out of server-side conversation storage for the native-workflow pattern, since the workflow's own YAML variables (not the client's store) already carry state between nodes. This is a client-side invocation setting, not a change to any agent's own definition/prompts/tools/guardrails, and doesn't affect the plain `workflow.run()` path (`run_workflow.py`, the validation suite) that was already passing without it — re-confirmed 6/6 PASS after adding it.
   - Separately diagnosed on the **Windows host only** (unrelated to the container, doesn't recur on Linux): installing `agent-framework-foundry-hosting --pre` pulled a newly-published `regex` package release that Windows blocked with `Eine Anwendungssteuerungsrichtlinie hat diese Datei blockiert` (an application-control/endpoint-security policy blocking a just-downloaded, not-yet-trusted DLL). Fixed by pinning `regex` to the prior release — no Windows security policy was touched.
   - A **local-testing-only** derived image (`Dockerfile.local-test`) exists from earlier diagnosis and is explicitly **not** representative of the real deployment image — it is not used for the results above, which used the real `Dockerfile` and real container (no credentials copied into it; see next point).
   - Inside the **real, unmodified `Dockerfile`'s container** (no `az` CLI, no copied tokens, nothing added for testing convenience), `POST /responses` correctly fails at the authentication step — `DefaultAzureCredential`'s chain tries `EnvironmentCredential`, `WorkloadIdentityCredential`, `ManagedIdentityCredential` (fails: *"no response from the IMDS endpoint"* — there is no real Azure IMDS locally), then exhausts the rest (`AzureCliCredential: Azure CLI not found on path`, etc.) and raises `ClientAuthenticationError`. This is the **expected local-auth limitation** the task anticipated, not a code or configuration defect — already proven by the successful non-containerized run above, under the exact same code, with credentials available. A real deployed Hosted Agent container has a working IMDS endpoint for its platform-issued managed identity, so this resolves itself at actual deployment.

**4. `azd` mechanism (container-deployment path):** `azd ai agent init --project-id "<id>" --deploy-mode container ...`, then `azd up` (or `azd provision` + `azd deploy` separately). Inspect with `azd ai agent show`/`azd ai agent monitor --follow`; invoke with `azd ai agent invoke`; tear down with `azd down`. **`azd 1.39.1` is now installed** (`winget install Microsoft.Azd`, satisfies the ≥1.37.0 floor you set), along with the official extensions `azure.ai.agents` (1.2.0), `azure.ai.projects` (1.1.1), and `microsoft.foundry` (1.2.0, matching `azure.yaml`'s `infra.provider`), via `azd extension install`. `azure.yaml` was validated with the official tool itself: `azd show` (read-only — no environment created, nothing provisioned) correctly parsed both services (`foundry-project`, `smid-compass-agent-framework`) from this project's `azure.yaml`.

**5. RBAC — checked for real, found actually missing exactly as expected, and now fixed, narrowly scoped:**
   - `az role assignment list` against the live project confirmed: `cloud_smid@savemyidentityorg.onmicrosoft.com` had **"Foundry User"** at the Foundry *account* scope, but **nothing at all at the project scope** — "Foundry Project Manager" was genuinely missing, not assumed.
   - **Fixed, scoped to the project only** (not the whole account): `az role assignment create --assignee cloud_smid@savemyidentityorg.onmicrosoft.com --role eadc314b-1a2d-4efa-be10-5d325db5065e --scope <smid-compass project resource ID>` ("Foundry Project Manager", role ID confirmed from the live tenant's own role definitions, not guessed).
   - **Image push**, needed because this is the `container` deployment path: **`AcrPush`**, assigned **scoped to the new ACR resource only** (not the resource group) — see point 7.
   - **Not assigned, deliberately**: any role for the Hosted Agent's own platform-issued identity (e.g. `Container Registry Repository Reader` for image pulls) — that identity doesn't exist yet (Microsoft's docs: the platform creates it per hosted agent *at deploy time*), so there is nothing to scope a role to yet; the docs state the tooling assigns this automatically during deployment.
   - **Not assigned**: `Foundry Agent Consumer`/extra `Foundry User` grants for invoking the agent — not needed for deployment prep itself, and assigning access nobody asked for yet would violate least-privilege; add if/when someone other than the deploying account needs to invoke it.

**6. Sweden Central is officially supported for Foundry Hosted Agents.** Confirmed directly against Microsoft's current "[Hosted agents in Foundry Agent Service](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/hosted-agents)" page (ms.date 2026-11-09), which explicitly lists **Sweden Central** in its region-availability list (alongside Norway East, Poland Central, Spain Central, Switzerland North, and others), with the note that the list is updated as more regions become available. **We stay in Sweden Central, targeting the existing `smid-compass` project — no region change and no new project**, per your instruction. (This replaces the earlier "must be verified" wording in this README, which was based on weaker indirect evidence at the time.)

**7. Resources — the honest accounting, now with real state instead of predictions:**

| Resource | Status | Notes |
|---|---|---|
| Foundry project (`smid-compass`) | **Reused** | No new project, per your instruction. Not recreated, not modified. |
| Region (Sweden Central) | **Reused** | No region change, per your instruction, and officially confirmed supported (point 6). |
| Model deployment (`gpt-4.1-mini`) | **Reused** | The orchestration calls existing agents; no new model deployment is declared in `azure.yaml`. |
| **Azure Container Registry** | **✅ Created, 2026-11-19** | `smidcompassdeva5bc33` (Basic SKU, Sweden Central, admin user disabled), `smidcompassdeva5bc33.azurecr.io`. Confirmed via `az acr list` that none existed beforehand (not part of the Terraform foundation). Not linked into `azure.yaml` yet — the next session needs to confirm whether `azd provision` auto-discovers it or expects it referenced explicitly. |
| **RBAC: Foundry Project Manager** | **✅ Assigned, 2026-11-19** | `cloud_smid@savemyidentityorg.onmicrosoft.com`, scoped to the `smid-compass` project only (confirmed missing beforehand via `az role assignment list` — only "Foundry User" existed, at the account scope). |
| **RBAC: AcrPush** | **✅ Assigned, 2026-11-19** | Same account, scoped to the new ACR resource only (not the resource group). |
| **Foundry project connection** | **✅ Created, 2026-11-20** | `smidcompassdeva5bc33-conn` (kind `ContainerRegistry`, auth `ManagedIdentity`) — links the existing project to the existing ACR for remote builds. Created via `azd provision`, previewed first and matched the preview exactly. |
| **Hosted Agent resource itself** | **✅ Deployed and active, 2026-11-20** | `smid-compass-agent-framework:1`, status `active`. Validated with real passport/workshop/out-of-scope queries (see above). |
| **Dedicated Entra agent identity** | **✅ Created automatically at deploy time, 2026-11-20** | Platform-issued, as Microsoft's docs described in advance — `azd ai agent show` reports `Instance Identity Principal ID 1d5032d0-75a6-4dc7-aca5-a7adad355d51`. No role was assigned to it manually; image pulls worked without one, consistent with the earlier prediction that the tooling handles this automatically. |
| Application Insights | **Reused** | Already provisioned by Terraform for `smid-compass-dev`; container deployments get an auto-injected connection string, no new resource expected. |
| **Credential mechanism for the deployed container** | **✅ Fixed, 2026-11-19** | `agents.py` now uses `DefaultAzureCredential` (see "What was verified" / Setup above) instead of a hardcoded `AzureCliCredential` — works locally via your `az login` session today, and will resolve via the Hosted Agent's managed identity once deployed, with no further code change needed. |

**8. Cost — I could not get verified rate numbers, and won't invent any.** Azure's public Foundry Agent Service pricing pages list Hosted Agent compute as billed per **vCPU-hour + GiB-hour** of the sandbox size used (`azure.yaml` currently requests the smallest tier, 0.5 vCPU/1 GiB), separate from model-token costs (already being incurred today regardless, via the existing agents) — but the actual rate figures on Microsoft's pricing pages were blank placeholders in what I could fetch. The Basic-SKU ACR actually created above is a well-documented, low, roughly-$5/month-class cost, but I'm not treating that as precise either. **Recommend checking the Azure Pricing Calculator directly, or your Azure sales/billing contact, for real numbers before deciding on the Hosted Agent itself.**

**What was actually created/changed in Azure DEV through 2026-11-19:** one Basic-SKU Container Registry, and two narrowly-scoped RBAC role assignments (both listed above). The Hosted Agent itself was not yet deployed as of that point.

## 2026-11-20 — Hosted Agent deployed and validated in Azure DEV

With explicit authorization, the Hosted Agent was actually deployed. What was done, in order:

1. **`azd env new smid-compass`** — created the azd environment (subscription `a5bc333b-cd24-4c66-95e0-18013949c94f`, region `swedencentral`).
2. **Authentication**: `azd auth login` (device code) — required interactively; the automated session's non-interactive stdin couldn't complete a device-code flow, so this one step needed to be run by hand in a real terminal.
3. **`azd env set`**: `FOUNDRY_PROJECT_ENDPOINT`, `AZURE_CONTAINER_REGISTRY_ENDPOINT` (`smidcompassdeva5bc33.azurecr.io`), `AZURE_CONTAINER_REGISTRY_RESOURCE_ID`, `AZURE_AI_PROJECT_ID` — all local to the azd environment (`.azure/`, git-ignored), none of these are secrets.
4. **`azd provision --preview`**, checked before applying: the only planned change was `Create: Foundry project connection: smidcompassdeva5bc33-conn` — no new project, ACR, or model. Confirmed, then applied for real with `azd provision`.
5. **`azd deploy --all`** — found and fixed two real, narrow deployment-blocking issues (not architecture/security changes):
   - **ACR Tasks remote-build failure**: `docker: {remoteBuild: true}` builds run through Azure Container Registry Tasks, whose lightweight Dockerfile parser (used for its own dependency-scanning pre-step) does not understand `FROM --platform=linux/amd64 ...` and aborted the build before it started. Fixed by dropping the `--platform=` argument from the `Dockerfile`'s `FROM` line — ACR Tasks' build agents are amd64 Linux only, so the resulting image's architecture is unaffected; local builds still get `linux/amd64` via the existing `docker build --platform linux/amd64` instruction in the same comment block.
   - **Reserved environment variable rejected by the Foundry API**: the hosted-agent creation call returned `400 invalid_payload`: *"Environment variable 'FOUNDRY_PROJECT_ENDPOINT' is reserved for platform use. All FOUNDRY_* and AGENT_* variables are reserved per container-image-spec."* Fixed by removing the `env:` block from `azure.yaml`'s `smid-compass-agent-framework` service — the platform injects this variable itself at runtime, and `config.py`'s existing fallback default already matches this project's own endpoint, so no code change was needed.
   - After both fixes, `azd deploy --all` completed successfully in ~2m20s: image built and pushed via ACR Tasks, hosted agent version `1` created and activated.
6. **Verification**, all against the real deployed agent (not local):
   - `azd ai agent show smid-compass-agent-framework` → `Status: active`, `Version: 1`.
   - Passport query (Spanish) → `route: passport`, full bilingual PassGuide+Safety answer, no errors.
   - Workshop query (Spanish) → `route: workshop`, full bilingual WorkshopGuide+Safety answer, no errors.
   - Out-of-scope query (Spanish) → `route: out_of_scope`, canned redirect answer, Safety correctly bypassed, no errors.
   - No separate public `/readiness` HTTP path exists for a deployed Hosted Agent (that path was specific to the local Docker test) — the platform's own `active` status is itself the result of its internal readiness probing during deploy (visible in the deploy log as "Polling agent status").

**Not done, per explicit instruction:** production was not touched; the agent was not published to any external channel; the prior declarative Foundry workflow was not deleted or modified.

## Keeping the declarative workflow as fallback

The existing, validated Foundry declarative workflow (`SMID-compass-workflow`, live in nonprofit DEV, validated in Phase 8) has **not** been deleted, modified, or touched by this modernization work, and is not planned to be. It remains available as the behavioral reference and operational fallback until a Hosted Agent deployment of this Agent Framework implementation is itself deployed to Azure DEV and independently validated there. This matters especially because Microsoft is retiring declarative Foundry workflows on **2026-12-01** — until the Hosted Agent path is proven in DEV, the declarative workflow is still the only *deployed* working implementation, and should not be removed or altered as part of this work.

## Next session — beyond DEV smoke validation

**Do not rebuild the migration from scratch.** The Hosted Agent is deployed and active in Azure DEV (`smid-compass-agent-framework:1`). What's actually left:

1. Run the full six-case bilingual parity suite (`validation/run_suite.py`) against the deployed Hosted Agent endpoint, not just the three ad-hoc queries done at deploy time, and save that evidence under `validation/`.
2. Compare results against both Phase 8 (original Foundry workflow) and the local Agent Framework validation (`validation/agent-framework-smoke-validation.md`).
3. Decide on an evaluation suite (`azd extension install azure.ai.evaluations`, `azd ai eval init`) if ongoing quality monitoring in DEV is wanted — not set up yet.
4. Get real Hosted Agent pricing figures before any production decision (see point 8 above — still unresolved).
5. Document Hosted Agent DEV validation outcome before any production decision — production remains untouched until then.

## Current modernization status

- Agent Framework local POC: **COMPLETE**
- Existing live Foundry agents reused successfully (not recreated)
- Existing workflow semantics preserved (byte-identical YAML, zero redesign)
- Local runtime validation: **PASS**
- 6-test local parity suite: **6/6 PASS**
- Hosted Agent adapter (`host.py`) local round trip: **PASS** (2026-11-19)
- Azure DEV pre-deployment prep (ACR, RBAC, `azd`, `azure.yaml`): **DONE** (2026-11-19)
- Hosted Agent deployment to Azure DEV: **DONE — deployed and active** (2026-11-20)
- Azure DEV Hosted Agent validation: **PASS — passport, workshop, out-of-scope all correct, no errors** (2026-11-20)
- Production: **UNTOUCHED**
- Next major task: full six-case parity suite against the deployed Hosted Agent, then a production-readiness decision

This is a **technical parity smoke validation**, not exhaustive QA. See [validation/agent-framework-smoke-validation.md](validation/agent-framework-smoke-validation.md) for the documented scope and limitations (no detailed File Search call trace at this layer, no independent RAI re-verification, no multi-turn/malformed-route testing, no production traffic). The Hosted Agent deployment itself has now been validated with three real queries against the live DEV endpoint (see above), beyond what that document covers.
