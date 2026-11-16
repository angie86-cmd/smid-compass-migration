"""Builds references to the existing, live nonprofit DEV Foundry agents.

This module does NOT recreate agents, prompts, tools, File Search, vector
stores, or guardrails. Each FoundryAgent instance below is a live reference
to an agent already created and validated in Foundry (Phase 6/Phase 8) — the
service owns the definition; this orchestration layer only invokes it.
"""

from azure.identity import AzureCliCredential
from agent_framework.foundry import FoundryAgent

from .config import AGENT_VERSIONS, FOUNDRY_PROJECT_ENDPOINT


def build_agent_registry(credential: AzureCliCredential | None = None) -> dict[str, FoundryAgent]:
    """Returns {agent_name: FoundryAgent} for every agent the workflow invokes by name."""
    credential = credential or AzureCliCredential()
    return {
        name: FoundryAgent(
            project_endpoint=FOUNDRY_PROJECT_ENDPOINT,
            agent_name=name,
            agent_version=version,
            credential=credential,
        )
        for name, version in AGENT_VERSIONS.items()
    }
