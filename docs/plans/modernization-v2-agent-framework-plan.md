# SMID Compass Modernization v2 — Microsoft Agent Framework Strategy

Status: planning record only. No implementation has started. This document exists so the agreed modernization design decisions aren't lost between now and the point where Modernization v2 actually begins.

## 1. Purpose

Modernization v2 starts only after:

1. Nonprofit DEV parity migration is complete.
2. Parity testing is complete.
3. The `nonprofit-parity-v1` baseline is frozen.
4. A small, controlled PROD parity pilot has been deployed and observed.

Modernization must not be mixed with the current parity migration. Guiding sequence:

**MIGRATE → VALIDATE PARITY → FREEZE `nonprofit-parity-v1` → SMALL PROD PARITY PILOT → MODERNIZE IN DEV → VALIDATE MODERNIZATION → PROMOTE MODERNIZATION TO PROD**

## 2. Core architecture principle

**Microsoft Agent Framework does not replace Terraform.**

- Terraform remains the infrastructure-as-code layer.
- Agent Framework becomes the application/orchestration layer.
- Foundry remains the managed Azure runtime/project environment.

Conceptual separation:

| Layer | Role |
|---|---|
| Terraform | Azure infrastructure |
| Git | Versioning and traceability |
| Microsoft Agent Framework | Agent/workflow logic and orchestration |
| azd / Foundry deployment mechanism | Packaging and deployment of hosted agent/application code |
| Microsoft Foundry | Managed runtime, project, identity, sessions, endpoints, and related services |

## 3. Infrastructure to reuse

The following existing nonprofit DEV infrastructure is reused during modernization, not recreated:

- `rg-smid-compass-dev`
- Foundry resource: `smid-compass-dev-a5bc33`
- Foundry project: `smid-compass`
- `gpt-4.1-mini` deployment
- `text-embedding-3-small` deployment
- Log Analytics
- Application Insights
- Managed identities
- RBAC foundation
- Cost Management budget/notifications
- Terraform Azure Blob remote state

Modernization must not create a parallel Foundry environment unless a concrete technical requirement makes that unavoidable.

## 4. Terraform strategy

The current Terraform repository (`terraform/`) remains authoritative for Azure infrastructure.

When Microsoft Agent Framework / Hosted Agent requires additional Azure resources — for example, Azure Container Registry, additional identities, additional RBAC, networking, or other Hosted Agent runtime dependencies — add only the missing resources to the existing Terraform configuration. Do not duplicate resources already managed by the current Terraform state.

Preferred approach:

1. Optionally use Microsoft tooling / `azd` Terraform generation as a reference.
2. Inspect the generated infrastructure.
3. Compare it with the existing SMID Terraform.
4. Extract only genuinely missing resources/settings.
5. Integrate those changes into the existing Terraform root module.
6. Review `terraform plan` before apply.

Do not automatically apply a separately generated Terraform stack.

## 5. Existing Foundry agents can be reused

Preferred first modernization step: **do not immediately rewrite all six existing Foundry Prompt Agents.**

Initially keep as Foundry-managed Prompt Agents:

- SMID-RouterAgent
- SMID-PassGuide
- SMID-WorkshopGuide
- SMID-SafetyAgent
- OutOfScopeAgent
- smid-compass-agent

Microsoft Agent Framework can orchestrate/invoke existing Foundry agents. The first modernization target should primarily be **the workflow/orchestration**, not a simultaneous rewrite of all agents.

## 6. Workflow-first modernization

Intended first Agent Framework architecture:

```
Existing Foundry Prompt Agents
        ↓
Microsoft Agent Framework workflow
        ↓
Foundry Hosted Agent / managed execution
```

Preserve the current routing semantics initially:

```
Router
├─ passport
│  → PassGuide
│  → Safety
│  → end
│
├─ workshop
│  → WorkshopGuide
│  → Safety
│  → end
│
└─ out_of_scope
   → OutOfScope
   → end
```

During modernization, known parity limitations may then be intentionally reviewed, including:

- Safety input mismatch
- OutOfScope bypass of Safety
- Legacy agent retirement
- Guardrail consistency
- Web Search design
- Workflow implementation
- Broader observability
- Network/local-auth hardening

Unlike the parity migration, Modernization v2 **may** intentionally correct these items, but every behavioral change must be documented and tested.

## 7. YAML strategy

The existing repository YAML remains valuable. Current frozen source (`source/agents/`, `source/workflows/`) remains the historical parity baseline and is not overwritten.

Modernization creates a separate target structure, for example:

```
modernization/
  agent-framework/
    workflows/
    agents/
    deployment/
    docs/
```

Where possible, transform the existing workflow semantics into Agent Framework declarative YAML rather than rewriting everything immediately into imperative Python/C#. Use Python/C# only where Agent Framework capabilities or maintainability make it clearly preferable.

## 8. azd / Hosted Agent strategy

`azd` can be used for packaging/deploying the Agent Framework application, while Terraform continues to manage Azure infrastructure. The existing Foundry project is reused instead of provisioning a new one.

Conceptually:

```
terraform plan/apply  → infrastructure
azd deploy             → Agent Framework / Hosted Agent application
```

If Microsoft tooling can generate Terraform for Hosted Agent infrastructure, treat the generated Terraform as reference material, not as an independent source of truth.

## 9. RBAC implications

Hosted Agent deployment may require additional project-level permissions beyond the current parity configuration.

When Modernization v2 starts:

- Determine the exact current Microsoft role requirements.
- Add required role assignments through Terraform.
- Preserve least privilege.
- Do not manually configure long-lived production RBAC in the portal.

**Do not add these roles now.**

## 10. Incremental modernization plan

### M2.1 — Workflow modernization in DEV

- Keep existing Foundry Prompt Agents.
- Create Agent Framework workflow.
- Invoke existing agents.
- Reproduce routing behavior first.
- Deploy as Hosted Agent in the existing Foundry project.

### M2.2 — Validate workflow

- Routing tests
- Safety tests
- Retrieval tests
- Observability validation
- Operational validation

### M2.3 — Intentional corrections

Evaluate and intentionally address:

- Safety input contract
- OutOfScope safety behavior
- Web Search architecture
- Guardrail consistency
- Legacy agent retirement
- Prompt improvements

### M2.4 — Optional agent-by-agent migration

Only migrate individual Prompt Agents to native Agent Framework implementations if doing so provides a concrete benefit. Not required for the first modernization release.

### M2.5 — Freeze modernization baseline

Create a new baseline/tag after successful DEV validation. Exact future tag name can be decided later.

### M2.6 — Controlled PROD modernization rollout

Promote the validated modernized version to PROD separately from the original parity pilot. Do not combine the parity PROD launch and the modernization PROD rollout.

## 11. What we are explicitly avoiding

- Rebuilding the Azure platform from scratch.
- Creating a second parallel Foundry environment unnecessarily.
- Rewriting all six agents at once.
- Combining infrastructure migration with framework migration.
- Big-bang production cutover.
- Manual portal-only configuration that cannot be reproduced.
- Throwing away the Terraform work already completed.

## 12. Target end state

```
Azure infrastructure
managed by Terraform
        │
        ├── Foundry resource/project
        ├── model deployments
        ├── observability
        ├── identities/RBAC
        └── supporting Hosted Agent infrastructure
                │
                ↓
Microsoft Agent Framework
        │
        ├── workflow/orchestration
        ├── optional native framework agents
        └── integrations with existing Foundry agents
                │
                ↓
Foundry managed runtime / Hosted Agent
                │
                ↓
SMID Compass
```

## 13. Decision summary

- Terraform remains the infrastructure source of truth.
- Existing nonprofit Foundry infrastructure will be reused.
- Modernization starts with workflow/orchestration, not a six-agent rewrite.
- Existing Foundry Prompt Agents may be invoked from Agent Framework.
- Additional Hosted Agent infrastructure will be added incrementally through the existing Terraform configuration.
- `azd` may deploy application/runtime code but does not replace Terraform.
- Agent-by-agent migration is optional and driven by concrete benefits.
- Modernization happens in DEV first.
- Production modernization is a separate controlled rollout after validation.

This plan is intentionally deferred until `nonprofit-parity-v1` and the initial PROD parity pilot exist.
