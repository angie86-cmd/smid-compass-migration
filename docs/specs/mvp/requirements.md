# Draft MVP requirements / Borrador de requisitos del MVP

The following acceptance criteria are proposed for review. / Los siguientes criterios de aceptación están propuestos para revisión.

| ID | Español | English |
| --- | --- | --- |
| FUN-001 | En español y alemán, las consultas sobre pasaportes y talleres reciben orientación pertinente, las consultas ajenas se redirigen y los seguimientos conservan el contexto pertinente. | In Spanish and German, passport and workshop requests receive relevant guidance, unrelated requests are redirected, and follow-ups retain relevant context. |
| SAF-001 | Ante señales sintéticas de crisis, la respuesta evita contenido dañino y orienta hacia apoyo humano cuando corresponde, incluso en seguimientos. | For synthetic crisis signals, the response avoids harmful content and directs users to human support when appropriate, including in follow-ups. |
| SAF-002 | El cliente solo muestra contenido aprobado para el usuario. Un fallo del modelo, la validación o una herramienta activa una respuesta de contingencia segura. | The client displays only approved user-facing content. Model, validation, or tool failures trigger a safe fallback. |
| PRV-001 | Las sesiones están aisladas. Los marcadores sensibles ficticios quedan fuera de las consultas web, la telemetría y las evidencias. Se documentan la retención y el acceso. | Sessions are isolated. Synthetic sensitive markers stay out of web queries, telemetry, and evidence. Retention and access are documented. |
| SEC-001 | Los roles y herramientas efectivos tienen permisos mínimos. El contenido externo se trata como datos y carece de autoridad para alterar instrucciones o permisos. | Effective roles and tools have least privilege. External content is treated as data and has no authority to alter instructions or permissions. |
| WEB-001 | Las afirmaciones cambiantes consultadas en la web se respaldan con citas verificables y se priorizan fuentes oficiales pertinentes. Si la verificación falla, se comunica la limitación. | Changing claims retrieved from the web are backed by verifiable citations, with relevant official sources prioritized. If verification fails, the response states the limitation. |
| QUAL-001 | La decisión sobre el modelo registra versiones, resultados bilingües y métricas de seguridad, calidad, grounding, herramientas, coste y latencia. | The model decision records versions, bilingual results, and measures of safety, quality, grounding, tool use, cost, and latency. |
| OPS-001 | Los responsables pueden detectar fallos en DEV mediante telemetría que cumple PRV-001. | Owners can detect failures in DEV using telemetry that meets PRV-001. |
