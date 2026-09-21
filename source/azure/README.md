# Azure Raw Exports

This directory is a placeholder for raw Azure resource exports that may be added later.

Two optional files may be placed here:

- `foundry-resource.raw.json` — raw JSON export of the Microsoft Foundry resource (Azure Portal "JSON View" or Azure API).
- `foundry-project.raw.json` — raw JSON export of the Microsoft Foundry project (Azure Portal "JSON View" or Azure API).

These files must come directly from the real Azure Portal JSON View or the Azure API/CLI (e.g. `az resource show`). They must not be reconstructed or fabricated from other files in this repository.
