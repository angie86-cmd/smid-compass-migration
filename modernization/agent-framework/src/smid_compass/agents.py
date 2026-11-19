"""Builds references to the existing, live nonprofit DEV Foundry agents.

This module does NOT recreate agents, prompts, tools, File Search, vector
stores, or guardrails. Each FoundryAgent instance below is a live reference
to an agent already created and validated in Foundry (Phase 6/Phase 8) — the
service owns the definition; this orchestration layer only invokes it.

Credential: DefaultAzureCredential, not a single hardcoded credential type.
Its chain tries ManagedIdentityCredential (what a deployed Hosted Agent
container authenticates as — the platform creates a dedicated Entra agent
identity per hosted agent at deploy time; there is no `az login` session
inside that container) ahead of AzureCliCredential (what local development
uses, via your existing `az login` session) — so the same code runs
unmodified in both places. Microsoft's own docs do not specify or require a
different credential type for Hosted Agents, so there was no reason to
hardcode ManagedIdentityCredential and lose local-dev support.
"""

from azure.identity import DefaultAzureCredential
from agent_framework.foundry import FoundryAgent

from .config import AGENT_VERSIONS, FOUNDRY_PROJECT_ENDPOINT


def build_agent_registry(credential: DefaultAzureCredential | None = None) -> dict[str, FoundryAgent]:
    """Returns {agent_name: FoundryAgent} for every agent the workflow invokes by name.

    `default_options={"store": False}`: a client-side invocation setting, not
    a change to the agent's own definition. FoundryAgent's underlying client
    stores conversation state server-side by default; the native-workflow
    Hosted Agent adapter (src/smid_compass/host.py) requires storing clients
    to opt out explicitly, since the workflow's own YAML variables (not the
    client's server-side store) already carry state between nodes within a
    turn. Required for `host.py`'s ResponsesHostServer path; harmless and
    unused by the plain `workflow.run()` path (run_workflow.py, the
    validation suite) that was already validated without it.
    """
    credential = credential or DefaultAzureCredential()
    return {
        name: FoundryAgent(
            project_endpoint=FOUNDRY_PROJECT_ENDPOINT,
            agent_name=name,
            agent_version=version,
            credential=credential,
            default_options={"store": False},
        )
        for name, version in AGENT_VERSIONS.items()
    }
