# SMID Compass — Nonprofit Tenant Preflight

Phase 2 output, per [nonprofit-migration-plan-v1.md](../plans/nonprofit-migration-plan-v1.md). Verifies the nonprofit tenant, subscription, permissions, and required Azure/Foundry capabilities before any Terraform implementation or deployment.

No infrastructure was created or deployed during this preflight.

## Tenant and subscription

| | |
|---|---|
| Tenant | Save My Identity nonprofit |
| Tenant ID | `48cb7850-a5c9-4632-9dbd-eccda8b8b9bb` |
| Subscription | Azure subscription 1 |
| Subscription ID | `a5bc333b-cd24-4c66-95e0-18013949c94f` |
| User | `cloud_smid@savemyidentityorg.onmicrosoft.com` |
| RBAC | Owner at subscription scope |

## Required resource providers

| Provider | Status |
|---|---|
| `Microsoft.CognitiveServices` | Registered |
| `Microsoft.Insights` | Registered |
| `Microsoft.OperationalInsights` | Registered |
| `Microsoft.ManagedIdentity` | Registered |
| `Microsoft.Consumption` | Registered |

## Approved DEV region

`swedencentral`

## Model validation

| Model | Version | Deployment type | Quota | Available capacity |
|---|---|---|---|---|
| `gpt-4.1-mini` | 2025-04-14 | GlobalStandard — available | 5000 | 5000 |
| `text-embedding-3-small` | 1 | GlobalStandard — available | 1000 | 1000 |

Both source model/version pairs (see [target-migration-architecture-v1.md](../architecture/target-migration-architecture-v1.md)) are available in `swedencentral` with sufficient quota and capacity. No substitution is required.

## Feature validation — Sweden Central

| Capability | Status |
|---|---|
| Foundry Agent Service | Supported |
| File Search | Supported |
| Web Search | Supported |
| Guardrails / RAI policies | Supported |

## Workflow

- Foundry declarative workflows remain available, in Preview.
- Microsoft retirement date for this Preview capability: **2026-12-01**.
- Migration strategy remains parity first: attempt source workflow reconstruction first, as documented in the Target Migration Architecture v1.
- Microsoft Agent Framework modernization remains deferred to Modernization v2 and is not brought forward by this retirement date. The retirement date should be tracked against the Phase 7 (Workflow reconstruction) and Phase 10 (Modernization v2) timeline.

## Conclusion

**NONPROFIT PREFLIGHT PASSED**

Sweden Central is approved for SMID Compass DEV.

Next phase: **PHASE 3 — TERRAFORM FOUNDATION**
