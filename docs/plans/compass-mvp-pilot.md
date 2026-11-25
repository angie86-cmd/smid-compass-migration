# SMID Compass — de DEV al piloto en Linktree

Objetivo: validar la migración con pruebas básicas de usuario, construir un MVP con requisitos y pruebas en GitHub y abrir un piloto pequeño desde el Linktree de SMID. La evolución del piloto informará la futura integración en [savemyidentity.org](https://savemyidentity.org/).

## 1. Primero · Pruebas de usuario en DEV

Usar el [Playground de Foundry y su checklist existente](../../modernization/agent-framework/validation/pruebas-de-usuario.md). A1 tiene un PASS histórico del 23 de noviembre en la versión 5. Si cambia la versión, repetir A1 en la nueva versión. Anotar versión, fecha, resultado observado y estado (`PASS`, `FAIL` o `BLOCKED`). Usar conversaciones nuevas salvo en las continuaciones y datos ficticios.

| Sesión de hasta 1–2 h | Casos y observaciones |
| --- | --- |
| 1 · Flujos principales | A2–A3, B1–B2 y C1–C2. Comprobar que responde, aborda el tema correcto, conserva el idioma y muestra una respuesta comprensible. Si aparece un enlace, comprobar que abre y corresponde al trámite o taller. |
| 2 · Continuidad y casos límite | D1–D2 y E1–E2. Para D1, iniciar con A1 en el mismo chat. Confirmar que el seguimiento conserva el contexto y que los casos límite se gestionan sin errores. Si el Playground impide enviar una entrada vacía, registrar ese comportamiento del cliente. |

Si aparece una regresión en un flujo principal, registrar el caso, la versión y qué vio el usuario. Corregir en DEV y repetir el caso y los flujos relacionados. Cerrar esta etapa cuando los recorridos básicos tengan resultado registrado y los fallos que bloquean el uso estén resueltos. Esta evidencia respalda la migración. La validación de seguridad, privacidad y lanzamiento se realiza en la etapa siguiente.

## 2. MVP formal · Spec-Driven Development en GitHub

Usar Markdown, Pull Requests y los tests del repositorio. Por cada cambio: describir la necesidad y el riesgo, escribir el requisito y su criterio de aceptación, diseñar el caso de prueba, implementar el cambio mínimo y registrar el resultado. Vincular requisito, implementación, test y evidencia mediante IDs estables. Empezar con un solo recorrido completo antes de extender el patrón al resto.

| Lugar | Qué se versiona |
| --- | --- |
| [`docs/specs/mvp/`](../specs/mvp/) | Alcance, casos de uso ES/DE y requisitos funcionales y no funcionales, Safety, Security, privacidad y Web Search. |
| [`docs/validation/mvp/`](../validation/mvp/) | Plan y casos de prueba, trazabilidad, resultados por versión y decisión GO/NO-GO. Reutilizar el [diagnóstico técnico](../validation/mvp-baseline.md). |
| `modernization/agent-framework/tests/mvp/` | Tests y fixtures sintéticos junto a la suite existente. Convertir los seis casos CLI en comprobaciones automáticas. Ejecutar los tests deterministas en CI y las evaluaciones que requieren Azure en DEV. |

### Primer conjunto de requisitos y pruebas propuesto

| Requisito | Evidencia de aceptación |
| --- | --- |
| `FUN-001` · Pasaporte, talleres y fuera de alcance en ES/DE | Las rutas esperadas pasan en CLI y en el cliente del piloto. La respuesta es pertinente y los seguimientos mantienen el contexto cuando corresponde. |
| `SAF-001` · Respuesta segura ante señales de crisis | Casos sintéticos en ambos idiomas, incluidos seguimientos, verifican que la respuesta evita contenido dañino y orienta hacia apoyo humano cuando corresponde. |
| `SAF-002` · Respuesta visible y fallback | Verificar en cada ruta y en streaming qué llega al cliente. Solo se muestra contenido aprobado para el usuario. Un fallo del modelo, de la validación o de una herramienta produce una salida segura. |
| `PRV-001` · Minimización y aislamiento | Con marcadores ficticios, comprobar que las sesiones están aisladas y que los datos sensibles no se envían a Web Search ni aparecen en telemetría o evidencias. Documentar qué se conserva, por cuánto tiempo y quién puede acceder. |
| `SEC-001` · Permisos y contenido externo | Revisar roles efectivos e identidades. Con fuentes de prueba inocuas, verificar que el contenido recuperado no modifica instrucciones ni concede permisos. |
| `WEB-001` · Fuentes y citas | Confirmar el uso de Web Search en DEV, priorizar fuentes oficiales para información cambiante y comprobar que las citas respaldan la respuesta. Comunicar la falta de verificación o usar el fallback si la búsqueda falla. |
| `QUAL-001` · Modelo y calidad | Evaluar primero el modelo actual. Repetir el mismo conjunto bilingüe con candidatos elegibles si procede y registrar seguridad, calidad, grounding, herramientas, coste y latencia. Documentar la decisión con versiones y resultados. |
| `OPS-001` · Observabilidad | Comprobar en DEV que se puede detectar un fallo y que existe una persona responsable de revisarlo, con telemetría que respeta los requisitos de privacidad. |

Ejemplo del primer cambio trazable: riesgo de enviar un identificador personal a Web Search → `PRV-001` → prueba con un identificador ficticio → evidencia de la consulta efectivamente enviada o bloqueada → resultado vinculado al PR. Los IDs y criterios son una propuesta inicial para revisar después de las pruebas de usuario.

Tomar decisiones de alcance antes de publicar. Si una capacidad queda en el MVP, sus criterios aplican al candidato que se va a publicar. Antes del GO, tener pruebas críticas aprobadas, fallos críticos resueltos, permisos y tratamiento de datos revisados, fallback y monitorización comprobados, riesgos residuales documentados y revisión explícita registrada en Git. Para el portfolio, preparar un caso de estudio con requisitos, decisiones y evidencia sintética o anonimizada aprobada para publicación.

## 3. Piloto pequeño · Chat desde Linktree

Preparar un enlace a una interfaz de chat apta para usuarios externos. Validar desde móvil el recorrido completo desde Linktree, el alcance del asistente, el aviso de privacidad y el canal de feedback. Mantener el enlace sin publicar hasta el GO. Antes de abrirlo, acordar con SMID el tamaño del grupo, la duración, quién revisa el feedback y cómo se desactiva el acceso si aparece un problema crítico.

Recoger si la persona pudo completar el trámite o encontrar el taller, en qué idioma, qué le faltó y si la fuente le sirvió. Evitar pedir datos personales en el formulario de feedback. Revisar incidencias de seguridad y privacidad junto a las de calidad, y convertir los hallazgos relevantes en requisitos o regresiones para la siguiente versión.

## En paralelo · Evolución de la web de SMID

Inventariar páginas, contenidos, idiomas, formularios y responsables de la web actual. Preparar una prueba de concepto en un entorno separado para evaluar low-code y web propia según facilidad de edición, accesibilidad, multilingüismo, mantenimiento e integración con el chat. Mantener la elección de plataforma abierta durante el piloto. Usar el feedback para decidir cómo integrar el asistente en la web y qué mejoras entran en esa versión.

Con un máximo de 1–2 horas al día, dedicar las primeras sesiones al Playground. Después, trabajar en un requisito y su prueba por vez y reservar, si cabe, una sesión semanal para la web. Cerrar cada sesión con el resultado observado o con el siguiente caso pendiente. La fecha del piloto depende de la evidencia de aceptación.

## English

### 1. DEV user testing

Use the [existing Foundry Playground checklist](../../modernization/agent-framework/validation/pruebas-de-usuario.md). A1 has a historical PASS from November 23 on version 5. Repeat it if the version changes. Record date, version, observation, and PASS, FAIL, or BLOCKED. Use synthetic inputs and fresh conversations except for follow-ups.

| Session, up to 1–2 hours | Cases and observations |
| --- | --- |
| 1 · Main flows | A2–A3, B1–B2 and C1–C2. Check that answers are understandable, on topic and in the requested language. Check any links for availability and relevance. |
| 2 · Follow-ups and edge cases | D1–D2 and E1–E2. Start D1 by asking A1 in the same conversation. Verify continuity and graceful handling of edge cases. Record if the Playground prevents sending empty input. |

Record regressions with the case, version and user-visible outcome. Fix blocking issues in DEV and retest related flows. Close this step after recording the basic journeys and resolving blockers. Formal safety, privacy and release verification follows in the MVP phase.

### 2. Formal MVP using Spec-Driven Development

Use Markdown, pull requests and repository tests. For each change, document the need and risk, write the requirement and acceptance criterion, design the test, implement the change and record the result. Link requirement, implementation, test and evidence using stable IDs. Start with one complete journey.

Store [scope and requirements](../specs/mvp/) in `docs/specs/mvp/`, the [test plan, cases, traceability, results and release review](../validation/mvp/) in `docs/validation/mvp/`, and automated checks with synthetic fixtures in `modernization/agent-framework/tests/mvp/`. Reuse the six CLI cases and add assertions. Run deterministic checks in CI and Azure-dependent evaluations in DEV.

The proposed baseline covers bilingual routing, crisis response, safe visible output and fallback, data minimization and isolation, least privilege and handling of external content, verifiable Web Search citations, model evaluation and observability. Review the [requirements](../specs/mvp/requirements.md) and their [test cases](../validation/mvp/test-cases.md) after DEV user testing. For example, trace the risk of sending personal data to a search service to `PRV-001`, then verify with a synthetic marker and link privacy-safe evidence to the PR.

Resolve scope before publication. Require passing critical tests, resolved critical defects, reviewed permissions and data handling, fallback and monitoring evidence, documented residual risks and an explicit GO decision. For the portfolio, prepare a case study with requirements, decisions and synthetic or anonymized evidence approved for publication.

### 3. Small Linktree pilot and website work

Prepare a chat interface suitable for external users and validate the mobile journey from Linktree, scope notice, privacy notice and feedback channel. Publish after the GO decision. Agree on group size, duration, review ownership and how to disable access if a critical issue occurs. Collect whether users resolved their request, in which language, what was missing and whether sources helped. Avoid asking for personal data in feedback. Turn relevant findings into requirements or regression tests.

In parallel, inventory the [SMID website](https://savemyidentity.org/) pages, content, languages, forms and owners. Use a separate environment to compare low-code and custom web options for editing, accessibility, localization, maintenance and chat integration. Keep the platform choice open and use pilot feedback to decide how the chat fits into the future site.

Limit work to 1–2 hours a day. Start with Playground sessions, then work on one requirement and test pair at a time. If capacity allows, reserve a weekly website session. End each session by recording the outcome or next pending case. Set the pilot date based on acceptance evidence.
