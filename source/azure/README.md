# Azure Raw Exports

This directory contains raw Azure resource exports captured from the private source tenant. These files preserve the historical source state and are now frozen as the migration baseline.

Raw Foundry resource snapshots:

- `foundry-resource.raw.json` — raw JSON export of the Microsoft Foundry resource (Azure Portal "JSON View" or Azure API).
- `foundry-project.raw.json` — raw JSON export of the Microsoft Foundry project (Azure Portal "JSON View" or Azure API).

Raw model deployment snapshots:

- `deployments/deployments.raw.json`
- `deployments/gpt-4.1-mini.raw.json`
- `deployments/text-embedding-3-small.raw.json`

Vector-store mappings:

- `vector-stores/smid-passguide.mapping.json`
- `vector-stores/smid-workshopguide.mapping.json`
- `vector-stores/smid-compass-agent.mapping.json`

These files must come directly from the real Azure Portal JSON View or the Azure API/CLI (e.g. `az resource show`). They must not be reconstructed or fabricated from other files in this repository.

## Important notes

- Tenant IDs, resource IDs, principal IDs, file IDs, vector-store IDs, GUIDs, and similar identifiers in these files are historical/non-portable and reflect the private source tenant only.
- These identifiers must not be reused in the nonprofit target tenant.
- No secrets or credentials should be stored here.
- New target resources, identities, file IDs, and vector-store IDs will be generated during reconstruction.
