"""Configuration and Foundry agent identity for the SMID Compass Agent Framework
modernization. Values here match the live nonprofit DEV agents validated in
Phase 6/Phase 8 (see ../../../docs/validation/phase-8-parity-validation.md).
Agent prompts/instructions/tools are NOT duplicated here — the real agents are
invoked live in Foundry by name and version.
"""

import os

FOUNDRY_PROJECT_ENDPOINT = os.environ.get(
    "FOUNDRY_PROJECT_ENDPOINT",
    "https://smid-compass-dev-a5bc33.services.ai.azure.com/api/projects/smid-compass",
)

# Live nonprofit DEV agent name -> version, as validated in Phase 6/8.
# Do not recreate these agents; this is a reference to the existing live resources.
AGENT_VERSIONS = {
    "SMID-RouterAgent": "2",
    "SMID-PassGuide": "1",
    "SMID-WorkshopGuide": "1",
    "SMID-SafetyAgent": "1",
    "OutOfScopeAgent": "1",
}
