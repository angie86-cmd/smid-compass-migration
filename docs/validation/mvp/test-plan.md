# MVP test plan / Plan de pruebas del MVP

## Español

1. Completar primero la [checklist de usuario en DEV](../../../modernization/agent-framework/validation/pruebas-de-usuario.md) y registrar la versión y los resultados.
2. Revisar los [requisitos](../../specs/mvp/requirements.md) y preparar datos ficticios y resultados esperados en español y alemán. Reutilizar los seis casos CLI de paridad para añadir comprobaciones automáticas.
3. Ejecutar las verificaciones deterministas en CI y las que dependen de Foundry en DEV. Verificar manualmente la experiencia visible del cliente del piloto. Repetir las evaluaciones probabilísticas con versiones registradas.
4. Registrar resultados y revisar los criterios de lanzamiento antes del acceso desde Linktree.

## English

1. First complete the [DEV user checklist](../../../modernization/agent-framework/validation/pruebas-de-usuario.md) and record the version and outcomes.
2. Review the [requirements](../../specs/mvp/requirements.md) and prepare synthetic data and expected outcomes in Spanish and German. Reuse the six CLI parity cases to add automated assertions.
3. Run deterministic checks in CI and Foundry-dependent checks in DEV. Manually verify what the pilot client displays. Repeat probabilistic evaluations with versions recorded.
4. Record results and review release criteria before enabling access through Linktree.

Automated test location / Ubicación de pruebas automatizadas: `modernization/agent-framework/tests/mvp/`.
