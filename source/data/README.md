# Source Data

This directory holds the knowledge files used by SMID Compass in the private Azure tenant.

- PDFs stored here are the original knowledge files used by SMID Compass — uploaded directly to Microsoft Foundry agents, not through an external Azure AI Search or Storage resource.
- Internal Foundry file IDs such as `assistant-*` are not portable and must not be assumed to exist or be reusable in the nonprofit tenant.
- New file/vector identifiers will be created in the nonprofit environment when these files are re-uploaded there.
- Preserve original filenames whenever possible, so the mapping between source and target knowledge files stays traceable.
