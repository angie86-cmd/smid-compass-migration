# SMID Compass MVP specification / Especificación del MVP de SMID Compass

**Version / Versión:** 0.1 · **Status / Estado:** Draft for review / Borrador para revisión

## Scope / Alcance

El piloto de Linktree ofrecerá orientación sobre pasaportes venezolanos y talleres de SMID en español y alemán. La web institucional se trabaja en paralelo. Los requisitos describen el comportamiento esperado del piloto y las condiciones para autorizar su publicación.

The Linktree pilot will offer guidance on Venezuelan passports and SMID workshops in Spanish and German. Work on the organization website proceeds in parallel. The requirements describe expected pilot behavior and the conditions for authorizing release.

See [scope and use cases](scope-and-use-cases.md) and [DEV user testing](../../../modernization/agent-framework/validation/pruebas-de-usuario.md). / Ver [alcance y casos de uso](scope-and-use-cases.md) y [pruebas de usuario en DEV](../../../modernization/agent-framework/validation/pruebas-de-usuario.md).

## Proposed requirements / Requisitos propuestos

### User experience / Experiencia de usuario

| ID | Español | English |
| --- | --- | --- |
| FUN-001 | En español y alemán, las consultas sobre pasaportes y talleres reciben orientación pertinente, las consultas ajenas se redirigen y los seguimientos conservan el contexto pertinente. | In Spanish and German, passport and workshop requests receive relevant guidance, unrelated requests are redirected, and follow-ups retain relevant context. |
| FUN-002 | Si una consulta incluye varias solicitudes, Compass deberá distinguir las que puede atender de las que quedan fuera de alcance. Deberá indicar qué solicitudes válidas quedan pendientes si responde solo a una. | When a message contains multiple requests, Compass shall distinguish supported from out-of-scope requests. If it answers only one, it shall indicate which supported requests remain outstanding. |
| FUN-003 | Si una entrada llega vacía, contiene solo espacios o carece de una solicitud identificable, el sistema deberá rechazarla de forma controlada o pedir aclaración. | If input is empty, contains only whitespace, or has no identifiable request, the system shall reject it gracefully or ask for clarification. |

### AI safety / Seguridad de las respuestas

| ID | Español | English |
| --- | --- | --- |
| SAF-001 | Ante señales sintéticas de crisis, la respuesta evita contenido dañino y orienta hacia apoyo humano cuando corresponde, incluso en seguimientos. | For synthetic crisis signals, the response avoids harmful content and directs users to human support when appropriate, including in follow-ups. |
| SAF-002 | El cliente solo muestra contenido aprobado para el usuario. Un fallo del modelo, la validación o una herramienta activa una respuesta de contingencia segura. | The client displays only approved user-facing content. Model, validation, or tool failures trigger a safe fallback. |

### Privacy and security / Privacidad y seguridad

| ID | Español | English |
| --- | --- | --- |
| PRV-001 | Compass deberá excluir identificadores personales de las consultas enviadas al buscador. Si no puede formular una consulta sin esos datos, omitirá la búsqueda e indicará cualquier limitación que afecte a su respuesta. | Compass shall exclude personal identifiers from queries sent to search. If it cannot formulate a query without those data, it shall skip search and state any resulting limitation that affects its answer. |
| PRV-002 | Cada sesión deberá acceder únicamente al historial que le corresponde. | Each session shall access only its own conversation history. |
| PRV-003 | La telemetría y las evidencias deberán excluir mensajes completos e identificadores personales. Antes del piloto, SMID deberá documentar qué datos conserva, durante cuánto tiempo y quién puede acceder a ellos. | Telemetry and evidence shall exclude full messages and personal identifiers. Before the pilot, SMID shall document what data it retains, for how long, and who can access it. |
| PRV-004 | El acceso al piloto deberá ofrecer un aviso que explique el uso de datos y cómo contactar a SMID por consultas de privacidad. El formulario de feedback deberá permitir enviar comentarios sin proporcionar datos personales. | The pilot entry point shall provide a notice explaining data use and how to contact SMID about privacy. The feedback form shall allow users to submit comments without providing personal data. |
| SEC-001 | Los roles y herramientas efectivos tienen permisos mínimos. El contenido externo se trata como datos y carece de autoridad para alterar instrucciones o permisos. | Effective roles and tools have least privilege. External content is treated as data and has no authority to alter instructions or permissions. |

### Web search, evaluation and operations / Búsqueda web, evaluación y operación

| ID | Español | English |
| --- | --- | --- |
| WEB-001 | Las afirmaciones cambiantes consultadas en la web se respaldan con citas verificables y se priorizan fuentes oficiales pertinentes. Si la verificación falla, se comunica la limitación. | Changing claims retrieved from the web are backed by verifiable citations, with relevant official sources prioritized. If verification fails, the response states the limitation. |
| WEB-002 | Compass deberá recurrir a la búsqueda web cuando una consulta dentro de alcance dependa de información actual que la base de conocimiento no pueda confirmar, siempre que se cumpla PRV-001. | Compass shall use web search when an in-scope request depends on current information that the knowledge base cannot confirm, subject to PRV-001. |
| QUAL-001 | SMID deberá definir los criterios antes de evaluar y registrar una línea base con el modelo y prompts actuales. Las comparaciones usarán los mismos escenarios en español y alemán y cambiarán una variable por vez. La decisión registrará versiones, seguridad, privacidad, calidad, respaldo en fuentes y uso de herramientas. | SMID shall define criteria before evaluation and record a baseline for the current model and prompts. Comparisons shall use the same Spanish and German scenarios and vary one factor at a time. The decision shall record versions, safety, privacy, quality, grounding and tool use. |
| QUAL-002 | SMID deberá medir latencia, errores, tokens de entrada y salida, y coste estimado por consulta bajo carga normal y de estrés en DEV. La selección de un modelo más económico deberá respetar los criterios aprobados de seguridad, privacidad y calidad. | SMID shall measure latency, errors, input and output tokens, and estimated cost per request under normal and stress loads in DEV. Selection of a lower-cost model shall satisfy the approved safety, privacy and quality criteria. |
| OPS-001 | Los responsables deberán poder detectar fallos en DEV mediante telemetría que cumpla PRV-003. | Owners shall be able to detect failures in DEV using telemetry that meets PRV-003. |
| REL-001 | SMID solo deberá publicar el enlace de Linktree tras un GO explícito, con evidencia de los requisitos críticos aprobados, una persona responsable del piloto y un mecanismo para retirar el acceso. | SMID shall publish the Linktree link only after an explicit GO decision with evidence for critical requirements, a pilot owner, and a mechanism to withdraw access. |

## Decisions for review / Decisiones para revisión

| Español | English |
| --- | --- |
| Confirmar si el piloto responderá varias solicitudes válidas de una vez o atenderá una y ofrecerá continuar con las demás. | Confirm whether the pilot answers multiple supported requests in one turn or handles one and offers to continue with the others. |
| Aprobar los datos permitidos en registros, los plazos de retención y los roles autorizados. | Approve allowed log fields, retention periods, and authorized roles. |
| Acordar el volumen previsto del piloto, los límites de carga, latencia y coste, y los umbrales de evaluación antes de comparar modelos. | Agree on expected pilot traffic, load, latency and cost limits, and evaluation thresholds before comparing models. |

Esta versión reúne las propuestas para revisión por bloques. Los casos de prueba del MVP se redactarán y revisarán cuando se apruebe una versión estable de la especificación.

This version brings the proposals together for review by section. MVP test cases will be drafted and reviewed once a stable version of the specification is approved.
