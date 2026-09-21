# Source Inventory

This directory contains the structured inventory of the SMID Compass source configuration as it exists in the private Azure tenant.

`source-manifest.yaml` is the single source of truth for what was found during inventory: the Foundry project, model deployments, agents, workflow, guardrails, and the explicit absence of external services (Azure AI Search, dedicated storage, Foundry IQ Knowledge Base, memory, MCP/API tools, fine-tuning).

The `migration_status` block should be updated as each phase of the migration (see [docs/migration-plan.md](../../docs/migration-plan.md)) progresses. It reflects the state of the migration project, not the state of the source tenant.
