# Pruebas de usuario — Hosted Agent `smid-compass-agent-framework`

Este documento cubre dos aspectos de validación distintos y complementarios:

1. **Validación automática por CLI** (`validation/run_suite.py`) — reproducible, corre los 6 casos bilingües de siempre contra el workflow.
2. **Pruebas de usuario manuales** — se hacen a mano en el Playground web de Foundry, pregunta por pregunta, para confirmar que la experiencia real del usuario final (no solo el CLI) funciona.

## Incidente corregido (2026-11-23)

El Hosted Agent funcionaba por CLI y por VS Code, pero fallaba siempre en el **Playground web** con `Native workflow input validation failed`. Causa real (confirmada leyendo el código fuente de `agent_framework_foundry_hosting`): el Playground manda opciones de modelo (`temperature`, `tool_choice`, `parallel_tool_calls`) que el CLI no manda, y esas opciones deben coincidir exactamente con `default_options` de cada agente interno — los nuestros solo tenían `store: False`. Se corrigió en `src/smid_compass/host.py` agregando el hook `prepare_options` para descartar las opciones del llamador (no se tocó el YAML ni los agentes). Desplegado y confirmado en la versión 5. Detalle completo del diagnóstico al final de este documento.

## Lista de pruebas manuales (Playground web)

Repetir cada pregunta tal cual, en una **conversación nueva** salvo que se indique lo contrario. Marcar el estado después de probar.

### A. Pasaporte

- [x] **A1.** `como hago para sacar el pasaporte?` — Debe enrutar a `passport`, responder con guía completa (SAIME, cita biométrica, etc.). **Resultado: ✅ PASS (2026-11-23, versión 5)**
- [ ] **A2.** `Perdi mi pasaporte en Alemania, que hago?` — Debe enrutar a `passport`, mencionar denuncia policial + trámite de reposición.
- [ ] **A3.** `Wie kann ich einen Reisepass beantragen?` (alemán) — Debe enrutar a `passport` y responder en alemán.

### B. Taller / Workshop

- [ ] **B1.** `Quiero inscribirme en un taller de integracion laboral` — Debe enrutar a `workshop`, mencionar el enlace de inscripción y el costo.
- [ ] **B2.** `Wie kann ich mich für einen Workshop anmelden?` (alemán) — Debe enrutar a `workshop` y responder en alemán.

### C. Fuera de alcance

- [ ] **C1.** `Cual es la capital de Francia?` — Debe enrutar a `out_of_scope`, responder con el mensaje de redirección, sin pasar por Safety.
- [ ] **C2.** `Was ist die Hauptstadt von Frankreich?` (alemán) — Debe enrutar a `out_of_scope` igual que C1.

### D. Continuación de conversación (mismo chat, sin recargar)

- [ ] **D1.** Primero preguntar A1, luego en el mismo chat: `Y si tambien perdi mi cedula?` — Debe responder manteniendo el contexto de pasaporte.
- [ ] **D2.** Primero preguntar C1, luego en el mismo chat: `y la de Alemania?` — Debe seguir fuera de alcance o reencauzar correctamente, sin error.

### E. Casos límite

- [x] **E1.** Mensaje vacío o solo espacios — confirmar que no rompe el agente (puede responder pidiendo aclaración). **Resultado (CLI, 2026-11-25, versión 5):** cadena vacía `""` → la propia CLI (`azd ai agent invoke`) la rechaza antes de enviarla (`ERROR: a message argument or --input-file is required`, exit 1) — **BLOCKED**, ninguna petición llega al servicio. Cadena de solo espacios `"   "` → sí llega al servicio, rutea a `out_of_scope` con razón explícita `"User input is empty or unclear, no specific request identified."`, responde con el mensaje estándar, sin error — **PASS**. Consulta de control (`como hago para sacar el pasaporte?`) confirmó que el agente está accesible — **PASS**. Pendiente repetir ambas entradas manualmente en el Playground web.
- [ ] **E2.** Mensaje muy largo (varias líneas, mezcla de los dos temas) — confirmar que enruta a uno de los dos temas válidos sin error.

## Validación automática (CLI) — referencia

| Caso | Idioma | Ruta esperada | Estado |
|---|---|---|---|
| a1_passport_es | ES | passport | ✅ PASS |
| a2_passport_de | DE | passport | ✅ PASS |
| b1_workshop_es | ES | workshop | ✅ PASS |
| b2_workshop_de | DE | workshop | ✅ PASS |
| c1_oos_es | ES | out_of_scope | ✅ PASS |
| c2_oos_de | DE | out_of_scope | ✅ PASS |

Comando: `PYTHONPATH="src" PYTHONUTF8=1 PYTHONIOENCODING=utf-8 .venv/Scripts/python validation/run_suite.py`

## Clientes confirmados funcionando (versión 5)

| Cliente | Resultado |
|---|---|
| Playground web (Foundry) | ✅ Funciona |
| CLI (`azd ai agent invoke`) | ✅ Funciona |
| VS Code (Foundry Toolkit) | ✅ Funciona |

## Pendiente

Completar el resto de la lista de pruebas manuales (A2–E2) en el Playground web.

---

## Anexo — diagnóstico completo del incidente

**Síntoma:** primera consulta en cualquier conversación nueva del Playground web fallaba siempre con:
```
Error Native workflow input validation failed. Validate the typed input and current
scoped continuation, or start a fresh workflow lineage.
```

**Por qué el CLI y VS Code no mostraban el problema:** el Playground web, el CLI y VS Code llaman al mismo endpoint `/responses`, pero no mandan el mismo cuerpo de petición. El Playground incluye opciones de generación de modelo que una invocación simple por CLI no incluye.

**Pasos de diagnóstico:**
1. El mensaje del Playground es genérico — no indica la excepción real.
2. Se reprodujo por CLI (conversación nueva y continuación): ambas funcionaron, descartando problemas de continuación o de tipo de dato.
3. Con `azd ai agent sessions list` y `azd ai agent monitor --session-id <id> --type console` se recuperaron los logs reales de la sesión exacta del Playground que falló. Solo mostraban:
   ```
   ERROR agent_framework_foundry_hosting._workflow_responses: Native Responses workflow
   failed during input validation (ValueError).
   ```
   sin traceback ni mensaje real.
4. Intentos intermedios que no fueron la causa real:
   - `resilient_background=True`: quitó una advertencia relacionada pero no corrigió el error, y generó una petición colgada (`409 Conflict`). Se revirtió.
   - Log propio en `parse_response` confirmó que el texto de entrada (`turn.input`) era un string válido — se descartó el contenido del mensaje como causa.
5. Se interceptó temporalmente el logger de la librería para imprimir el traceback completo, revelando:
   ```
   File ".../agent_framework_foundry_hosting/_workflow_source.py", line 208, in prepare_workflow_kwargs
       raise ValueError(
           "RawAgent workflow generation overrides must be materialized in the fresh factory defaults."
       )
   ```
6. **Causa raíz**, confirmada leyendo el código fuente instalado: `prepare_workflow_kwargs` convierte cualquier campo del request que no esté en una lista corta de "campos controlados por el host" en una opción de generación de modelo efectiva (ej. `parallel_tool_calls` → `allow_multiple_tool_calls`). Esas opciones deben coincidir exactamente con `default_options` de cada agente nativo del workflow. Nuestros agentes solo declaran `default_options={"store": False}`, así que cualquier opción extra que mande el llamador no coincide y la librería lo rechaza.

**Corrección:** en `src/smid_compass/host.py`, función `discard_caller_model_options` registrada como el hook `prepare_options` de `ResponsesHostServer`, que descarta las opciones de modelo del llamador antes de que lleguen a esa comparación. Seguro porque el comportamiento real de cada agente ya está configurado del lado de Foundry en cada PromptAgent existente — esta capa de orquestación no los controla. No se tocó el YAML del workflow ni los agentes.

**Validado antes de desplegar:** suite de 6 casos (6/6 PASS, sin regresión) y prueba local directa simulando exactamente el request del Playground (`store: true` + `parallel_tool_calls`, `temperature`, `tool_choice`) — respuesta completa y correcta.

## English — DEV user testing

The CLI runner covers six bilingual routing cases. The Foundry Playground checks the actual user experience. Use a new conversation for each case except D1 and D2. Record the host version, date, observations and outcome.

| ID | Prompt or action | Expected outcome | Recorded status |
| --- | --- | --- | --- |
| A1 | `como hago para sacar el pasaporte?` | Passport route and guidance including SAIME and the biometric appointment. | PASS, 2026-11-23, version 5 |
| A2 | `Perdi mi pasaporte en Alemania, que hago?` | Passport route and guidance about reporting the loss to police and applying for a replacement. | Pending |
| A3 | `Wie kann ich einen Reisepass beantragen?` | Passport route and answer in German. | Pending |
| B1 | `Quiero inscribirme en un taller de integracion laboral` | Workshop route, registration link and cost. | Pending |
| B2 | `Wie kann ich mich für einen Workshop anmelden?` | Workshop route and answer in German. | Pending |
| C1 | `Cual es la capital de Francia?` | Out-of-scope redirect. | Pending |
| C2 | `Was ist die Hauptstadt von Frankreich?` | Out-of-scope redirect in German. | Pending |
| D1 | Ask A1, then `Y si tambien perdi mi cedula?` in the same conversation. | Retains the passport context. | Pending |
| D2 | Ask C1, then `y la de Alemania?` in the same conversation. | Remains out of scope or redirects appropriately without an error. | Pending |
| E1 | Empty or whitespace-only input. | Handles input gracefully, for example by asking for clarification. Record if the client prevents submission. | CLI, 2026-11-25, version 5: empty string "" is rejected by the `azd` CLI itself before any request is sent (`a message argument or --input-file is required`, exit 1) — BLOCKED. Whitespace-only "   " reaches the service and routes to `out_of_scope` with an explicit "input is empty or unclear" reason, no error — PASS. Control query confirmed the agent is reachable. Manual Playground run still pending. |
| E2 | A long, multiline message combining passport and workshop topics. | Routes to a supported topic without an error. | Pending |

The six ES/DE CLI cases previously passed. Version 5 was confirmed in Foundry Playground, CLI and VS Code. The remaining manual cases are pending.

### Resolved Playground issue

On November 23, new Playground requests failed with `Native workflow input validation failed` while CLI and VS Code calls worked. The underlying adapter required caller model options to match workflow agent defaults. Playground requests included temperature and tool options, while internal agents declared only `store: False`. The `prepare_options` hook in the host discards caller model overrides, and the live PromptAgents retain their server-side settings. The fix was verified with the six CLI cases and a local Playground-shaped request and was confirmed in Hosted Agent version 5.
