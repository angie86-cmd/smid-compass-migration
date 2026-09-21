# Source Workflows

This directory holds the exported Microsoft Foundry workflow configuration from the private Azure tenant (SMID-compass-workflow).

Rules for this directory:

- Preserve the original Microsoft Foundry workflow YAML unchanged. Do not edit it to make it suitable for the target environment.
- Target workflow modernization will be handled separately, as its own deliverable later in the migration (see [docs/migration-plan.md](../../docs/migration-plan.md), Phase 6).
- Internal node IDs used within the exported workflow do not need to be preserved in the target architecture — they are an artifact of the source Foundry project and are not portable.
