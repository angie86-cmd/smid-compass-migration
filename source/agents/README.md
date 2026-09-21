# Source Agents

This directory holds the exported Microsoft Foundry agent configurations from the private Azure tenant.

Rules for this directory:

- Exported YAML must remain unchanged. Do not reformat, reorder keys, "clean up," or otherwise normalize these files — they must represent exactly what was exported from Microsoft Foundry.
- Each exported agent YAML should be stored using the agent name, e.g. `SMID-RouterAgent.yaml`, `SMID-PassGuide.yaml`, `SMID-WorkshopGuide.yaml`, `OutOfScopeAgent.yaml`, `SMID-SafetyAgent.yaml`, `smid-compass-agent.yaml`.
- Tenant-specific identity IDs (principal IDs, client IDs, agent GUIDs, connection IDs, etc.) are expected to appear in these source files because they are part of the historical snapshot. They must **not** be reused in the nonprofit tenant — new identities will be created there.

See the top-level [README.md](../../README.md) for the full migration principle.
