# Architecture Decision Log

## Decision 001

**Decision:** Do not perform a direct tenant clone.

**Reason:** Microsoft Foundry does not provide full native cross-tenant migration for the complete project. The nonprofit environment will be recreated reproducibly from preserved source configuration and Infrastructure as Code.
