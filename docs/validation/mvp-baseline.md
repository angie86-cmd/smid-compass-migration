# SMID Compass MVP validation baseline

Reviewed 2026-11-25 against `20d184b`. Scope: tracked implementation, Azure configuration, and historical DEV evidence. Live Azure configuration and acceptance tests were not checked in this review. Production gate: **NO-GO pending acceptance evidence and explicit review**.

## Baseline and gaps

| Area | Evidence in Git | Verification gap |
| --- | --- | --- |
| Hosted runtime | [Host](../../modernization/agent-framework/src/smid_compass/host.py) creates a fresh workflow per request and discards caller model overrides. [DEV validation](../../modernization/agent-framework/validation/pruebas-de-usuario.md) records Hosted Agent version 5 working in Playground, CLI, and VS Code. | Complete the hosted test matrix, including continuation, concurrency, and session isolation. The host module's deployment status comment predates the DEV evidence. |
| Routing and knowledge | [Workflow](../../modernization/agent-framework/workflows/SMID-compass-workflow.yaml) routes to passport, workshop, or out-of-scope agents. Specialists declare File Search in their migration manifests. | Confirm user-visible outputs and knowledge grounding in both supported test languages, Spanish and German. |
| Output safety | The workflow runs the Safety Agent after the two specialist routes. The router and specialists have `autoSend: true`. The out-of-scope route ends before the Safety Agent. | Inspect streamed and non-streamed hosted output to establish which messages clients receive. Verify safety coverage and fallback on every route, including hosted errors. No bypass was reproduced in this review. |
| Guardrails and permissions | [Terraform](../../terraform/main.tf) defines a custom RAI policy, model deployments with `Microsoft.DefaultV2`, and Foundry role assignments. Several [agent manifests](../../target/migration/agents/) reference the custom policy. | Inventory the effective policies per live agent version and deployment, runtime identity, tool permissions, and session, trace, and retention behavior. Terraform and manifests record intended configuration. |
| Web Search | The [Safety Agent manifest](../../target/migration/agents/SMID-SafetyAgent.manifest.json) already declares `web_search`. | Check the pinned live version for tool availability and actual invocation, citation preservation, reliable source selection, query privacy, untrusted content handling, and fallback. |
| Model | Migration agent manifests specify `gpt-4.1-mini`. [Runtime config](../../modernization/agent-framework/src/smid_compass/config.py) pins agent versions. | Confirm the live model and version. Run comparable evaluations with fixed fixtures, repeated runs, and dated evidence before deciding whether to change the model. |
| Tests and CI | [DEV validation](../../modernization/agent-framework/validation/pruebas-de-usuario.md) records six CLI passes and one completed manual Playground case. The [CLI runner](../../modernization/agent-framework/validation/run_suite.py) saves observations without asserting outcomes. No GitHub Actions workflow is tracked at the reviewed commit. | Turn the six cases into assertions and add hosted, safety, security, and quality coverage. Identify whether CI exists outside GitHub before choosing where to integrate. |
| Observability | Terraform defines Application Insights and Log Analytics. The [CLI trace helper](../../modernization/agent-framework/src/smid_compass/run_workflow.py) records output and event previews. | Verify hosted event delivery, redaction, retention and access, alert ownership, and fallback signals with synthetic test data. |

## Technical priorities for the formal MVP

Start with the [user acceptance checklist in DEV](../../modernization/agent-framework/validation/pruebas-de-usuario.md). The [delivery plan](../plans/compass-mvp-pilot.md) sequences that check before formal MVP specification and implementation. The priorities below apply to the formal MVP.

1. **P0 · Establish the runtime baseline.** Record DEV host, agent, tool, policy, model and identity versions. Verify client-visible message boundaries first, then confirm session isolation and preserve privacy-safe evidence. Make the existing routing cases assert their expected result.
2. **P0 · Define the acceptance contract.** Assign IDs to functional, non-functional, safety, security, and Web Search requirements. Review hazards covering vulnerable users, inaccurate guidance, and unsafe output. Review trust boundaries at client input, tools, identity, session state, and logs. Link each critical risk to a requirement, test, and owner.
3. **P0 · Validate safety and security in DEV.** Cover crisis recognition, appropriate human support, sustained multi-turn behavior, and safe fallback on all routes. Verify least privilege, privacy, and that untrusted content cannot alter instructions or authorize actions using inert fixtures. Verify that clients receive only approved user-facing output. Change the workflow only where evidence shows a gap.
4. **P0 · Validate search and compare models.** Confirm whether Web Search requires activation in DEV. Test current information, official sources, citations that support the answer, failure handling, and protection of sensitive query data. Evaluate the current model and eligible alternatives on the same bilingual cases for safety, groundedness, routing, tool use, cost, and latency. Record model and agent versions and define pass thresholds before comparing results.
5. **P1 · Make verification repeatable.** Integrate deterministic tests into CI and run credentialed hosted evaluations in DEV. Verify operational telemetry, alerts, and incident ownership. Assemble the safety case with test evidence and residual risks for the release review.

## Proposed documentation structure

| Location | Purpose |
| --- | --- |
| `docs/specs/mvp/` | Scope, use cases, versioned requirements, and acceptance criteria. Use stable requirement IDs and link to the existing architecture. |
| `docs/validation/mvp/` | Test plan, cases, traceability, results and release decision. Link this evidence to the hazard analysis, threat model and model evaluation as these are developed. |
| `modernization/agent-framework/tests/mvp/` | Automated assertions and synthetic fixtures alongside the existing suite. |

Use one traceability record per requirement with links to the relevant risk, implementation path, test ID, and result. Include the tested versions and execution date in each result. The release review requires passing critical cases, disposition of residual risks, and evidence that fallback and monitoring work in the release candidate.

## Español

Revisión del 25 de noviembre de 2026 sobre el commit `20d184b`. Se revisaron la implementación, la configuración en Git y la evidencia histórica de DEV. La configuración efectiva de Azure y las pruebas de aceptación quedan pendientes de verificación. Producción queda en **NO-GO hasta contar con evidencia de aceptación y una revisión explícita**.

| Área | Evidencia en Git y comprobación pendiente |
| --- | --- |
| Runtime hospedado | El host crea un workflow por solicitud y descarta opciones del modelo enviadas por el cliente. La versión 5 figura como validada en Playground, CLI y VS Code. Falta completar las pruebas de continuidad, concurrencia y aislamiento. |
| Enrutamiento y conocimiento | El workflow enruta a pasaportes, talleres o fuera de alcance. Los especialistas declaran File Search. Falta confirmar las salidas visibles y el respaldo documental en español y alemán. |
| Seguridad de la salida | El Safety Agent se ejecuta después de los especialistas. El router y los especialistas usan `autoSend: true`. La ruta fuera de alcance termina antes de ese agente. Falta inspeccionar las respuestas visibles, con y sin streaming, y verificar cobertura y contingencia en todas las rutas. La revisión no reprodujo un bypass. |
| Políticas y permisos | Terraform define una política RAI personalizada, despliegues con `Microsoft.DefaultV2` y asignaciones de roles. Algunos manifiestos referencian esa política. Falta confirmar políticas efectivas por versión, identidad, permisos, sesiones, trazas y retención. |
| Web Search | El manifiesto del Safety Agent declara `web_search`. Falta verificar disponibilidad, invocación, citas, fuentes, privacidad de consultas, tratamiento del contenido externo y contingencia en la versión activa. |
| Modelo | Los manifiestos especifican `gpt-4.1-mini` y el runtime fija versiones de agentes. Falta confirmar el modelo efectivo y ejecutar evaluaciones comparables y repetidas antes de decidir cambios. |
| Pruebas y CI | Hay seis PASS históricos por CLI y una prueba manual completada en Playground. El runner registra observaciones. Falta añadir aserciones y ampliar cobertura. En el commit revisado no hay workflows de GitHub Actions versionados. Falta averiguar si existe CI externo. |
| Observabilidad | Terraform define Application Insights y Log Analytics. El runner CLI registra vistas previas de eventos y salidas. Falta verificar la entrega de eventos en el servicio hospedado, la redacción, la retención, el acceso, las alertas y sus responsables con datos ficticios. |

Empezar por la [checklist de usuario en DEV](../../modernization/agent-framework/validation/pruebas-de-usuario.md). Durante el MVP formal, documentar la configuración efectiva, acordar los criterios de aceptación, comprobar seguridad y privacidad, verificar Web Search y evaluar el modelo. Automatizar las comprobaciones repetibles y reunir evidencia para la revisión de lanzamiento. Las prioridades técnicas detalladas y los enlaces a la implementación figuran en la sección en inglés y en el [plan bilingüe](../plans/compass-mvp-pilot.md).

El [alcance y los requisitos](../specs/mvp/) se versionan en `docs/specs/mvp/`. El [plan de pruebas, la trazabilidad y la revisión de lanzamiento](mvp/) se versionan en `docs/validation/mvp/`. Cada registro vincula riesgo, requisito, implementación, prueba, resultado, fecha y versiones. Los tests automatizados se ubican junto al código de Agent Framework.
