# QA handoff — eliminacion-cuenta-phase-01

**Date:** 2026-07-10T15:59:52Z
**Status:** done (bloqueado por diseño — ver Sign-off)

## Contexto crítico para lectores futuros

Esta fase quedó **PARCIAL**: la pieza de UI (`DeleteAccountConfirmationPage`, sus 4 widgets hijos,
el `GoRoute`, y el ítem "Eliminar cuenta" en `ProfileActionsList`) **no se implementó** porque el
Pencil MCP estuvo caído/sin archivo abierto durante toda la corrida (regla cero-tolerancia:
`feedback_pencil_mcp_block.md` — no se inventan mockups alternativos). Confirmado en este QA con
grep directo:
- `profile_actions_list.dart`: cero menciones de "Eliminar cuenta"/`deleteAccount`.
- `app_router.dart`: sin `GoRoute` para `deleteAccount`.
- `app_routes.dart`: sí tiene la constante `deleteAccount = '/profile/delete-account'`, sin uso.

Lo que **sí** se completó y verificó en esta corrida: backend completo (`DELETE /users/me`,
orquestación de 5 pasos, `hardDeleteUser`), y en Flutter la capa domain/data/cubit/l10n/analytics
scaffolding (sin conectar a ninguna pantalla visible). No hay ningún punto de entrada end-to-end
en la app todavía — coherente con lo reportado por Backend y Frontend.

## Catalogo (AC §5 → cobertura)

| AC | Descripción | Cobertura | Estado |
|----|-------------|-----------|--------|
| AC1 | Ítem "Eliminar cuenta" navega a página dedicada (no `ConfirmationDialog`) | — | **GAP — no implementado** (bloqueo diseño); no existe ítem en `profile_actions_list.dart` |
| AC2 | Lista completa de qué se borra, incluye fase 2/3 | — | **GAP — no implementado**; página no existe |
| AC3 | Botón deshabilitado hasta activar `AppSwitchTile` | — | **GAP — no implementado**; widget no existe |
| AC4 | Segundo tap en `loading` no dispara 2ª llamada HTTP | `test/features/profile/presentation/cubit/delete_account_cubit_test.dart` | **Cubierto (nuevo)** — guard `if (state is Loading<Nothing>) return;` verificado con blocTest de dos llamadas concurrentes |
| AC5 | Éxito limpia `AuthCubit`/`VehicleCubit`/`ProfileCubit`, navega con `goAndClearStack` sin dejar pantalla en stack | — | **GAP — no implementado**; sin página ni wiring de limpieza post-éxito |
| AC6 | Error → estado `error`, mensaje en español, retry manual, sin loop automático | Parcial: `delete_account_cubit_test.dart` cubre `loading → error` a nivel cubit | **Parcial** — falta la capa de UI (banner + botón retry) que consume ese estado |
| AC7 | 5 pasos en orden fijo, Firebase `deleteUser` siempre último, fallo en paso 4 no invoca paso 5 | `account-deletion.service.spec.ts` (api-gateway) | **Cubierto (nuevo)** — 3 tests: orden exacto observable, corte en 404 (paso 1), corte en error paso 4 (nunca llega a paso 5). Verificado leyendo el código fuente: sin try/catch que trague errores del paso 4. |
| AC8 | `hardDeleteUser` borra fila (`prisma.user.delete`); `removeUser` intacto para sus llamadores | `users.service.spec.ts` + `users.controller.spec.ts` (users-ms) | **Cubierto (nuevo)** — regresión explícita: `remove()` sigue usando `update({isDeleted:true})`, nunca `delete`. Grep confirma **cero llamadores activos** de `removeUser` fuera de su propia definición (`users.controller.ts:41`) — el "sigue funcionando" es trivialmente cierto por ausencia de callers, tal como anotó Architect. |
| AC9 | Login post-borrado falla (usuario ya no existe) | — | **Manual/e2e, no ejecutado** — requiere stack local + cuenta desechable; correctamente diferido, nunca contra `qa1@gmail.com`/`qa2@gmail.com` ni usuarios reales |
| AC10 | Cero strings hardcodeados en la página nueva | `analytics_taxonomy_no_pii_test.dart` (eventos); grep de la página | **N/A esta corrida** — la página no existe aún, no hay strings de UI que auditar. Las 14 claves l10n sí están en `app_es.arb` (verificado), pero sin call site en widgets |
| AC11 | `dart analyze` limpio; un widget por archivo; sin `_buildX()` | `dart analyze` (ejecutado en este QA) | **Cubierto** — 15 issues, todos pre-existentes (`curly_braces_in_flow_control_structures`, info-level), 0 en archivos tocados por esta fase |

## Matriz de regresión (guardrails §6)

| Guardrail | Mecanismo | Verificado |
|-----------|-----------|------------|
| `removeUser` no se modifica ni elimina; llamadores actuales siguen pasando | `users.service.spec.ts`/`users.controller.spec.ts` (regresión explícita) + grep directo (`grep -rn removeUser` → solo la definición, 0 callers) | Sí — código fuente inspeccionado, `remove()` intacto |
| `hardDeleteUser` es `MessagePattern` nuevo y separado, nunca reemplaza `removeUser` | Lectura de `users.controller.ts`: dos `@MessagePattern` distintos coexistiendo | Sí |
| Orden fijo de 5 pasos, Firebase `deleteUser` último; fallo en paso 4 no invoca paso 5 | `account-deletion.service.spec.ts` — 3 tests con orden observable y cortes de cadena | Sí — leído el `.ts` fuente, sin try/catch que trague el error del paso 4 |
| Pasos 2 y 3 no-ops explícitos comentados, no placeholder que bloquee | Lectura directa de `account-deletion.service.ts` (`// TODO fase 2` / `// TODO fase 3`, sin código) | Sí |
| `uid` resuelto siempre de `request.user`, nunca de params/body | `users.controller.spec.ts` (api-gateway) — test explícito con params/body "envenenados" según Backend | Confiado en reporte de Backend; no releí el spec línea por línea, pero `npx jest` en verde para ese archivo |
| No probar hard-delete contra usuarios reales / qa1 / qa2 | Ningún test de este QA ejecutó el flujo real contra ningún usuario — todo verificado vía specs con mocks | Sí — cumplido, ningún flujo E2E real fue ejercitado |
| Doble-tap durante `loading` no dispara 2ª llamada HTTP | `delete_account_cubit_test.dart` (guard en cubit) | Sí — cubierto a nivel cubit; el guard de UI (deshabilitar botón visualmente) no aplica aún porque no hay UI |
| `dart analyze` sin violaciones nuevas; 1 widget/archivo, sin `_buildX()` | `dart analyze` ejecutado en este QA | Sí — 0 nuevas; no aplica regla de widgets porque no se crearon widgets de página todavía |
| Todo copy en `app_es.arb` vía `context.l10n` | Grep de las 14 claves nuevas en `app_es.arb` | Sí — claves existen, sin uso todavía (no hay UI que las consuma) |

## Ejecucion

- `dart analyze`: **15 issues, todos info-level pre-existentes** (`curly_braces_in_flow_control_structures`), 0 en archivos tocados por esta fase (`lib/features/users/**`, `lib/features/profile/presentation/cubits/**`, `lib/shared/router/app_routes.dart`, `lib/core/services/analytics/analytics_events.dart`).
- `flutter test`: **1382 tests, all passed** (0 fallos). Coincide con lo reportado por Frontend (1375 baseline + 7 nuevos de esta fase).
- `users-ms` (`npx jest --silent`): **2 suites, 6 tests, all passed**.
- `api-gateway` (`npx jest --silent`): **16 suites passed / 1 failed, 129 tests passed / 8 failed**. El suite fallido es `places.service.iter3.spec.ts` (feature `places`, no tocado en esta fase) — confirmado **pre_existing**, mismo conteo de fallos que reportó Backend como baseline antes de sus cambios.
- Integration tests (Patrol): **no ejecutados** — no hay pantalla nueva que ejercitar (AC1-3, 5, 6, 9 son gaps por bloqueo de diseño); el resto del suite Patrol existente no fue tocado por esta fase y no se re-corrió por no haber cambios de UI en su superficie.
- Cómo correr todo: `dart analyze && flutter test` (Flutter) + `npx jest --silent` en `api-gateway/` y `users-ms/` (rideglory-api).

## Bugs filed

Ninguno. No se encontraron regresiones ni defectos en el código efectivamente implementado. Los
gaps de AC1/AC2/AC3/AC5/AC6(parcial)/AC9/AC10(parcial) **no son bugs** — son trabajo diferido por el
bloqueo documentado y reconocido de Pencil MCP (política del proyecto: detener, no inventar
mockups alternativos).

## Pruebas manuales

- **No ejecutadas.** No hay ninguna superficie de UI nueva para ejercitar manualmente (la página de
  confirmación no existe). AC9 (login post-borrado falla) requiere stack local completo + cuenta
  desechable; queda pendiente hasta que exista la UI para disparar el flujo completo end-to-end, o
  hasta que se decida ejercitarlo directamente contra el endpoint con un cliente HTTP manual en un
  entorno de prueba (recomendación de Backend, no ejecutada en este QA por no ser el foco: validar
  el contrato vía tests automatizados fue suficiente para las garantías de esta fase).
- Verificación en BD: no aplica en este QA — no se ejecutó ningún hard-delete real (correcto,
  conforme al guardrail de no tocar usuarios reales/QA sin necesidad).

## Sign-off

- **Criterios de aceptación cubiertos por tests automatizados y verificados en este QA:** AC4, AC7,
  AC8, AC11 (verde, sin regresiones).
- **Parcial:** AC6 (cubit cubierto, falta capa UI), AC10 (l10n scaffolding cubierto, sin call site UI).
- **Gap explícito y reconocido (bloqueo de diseño, no bug):** AC1, AC2, AC3, AC5, AC9.
- **Regresiones encontradas:** ninguna. `removeUser` intacto y sin callers activos (grep + specs).
  `flutter test` y `users-ms` en verde total; `api-gateway` con los mismos 8 fallos pre-existentes
  de baseline (`places`), no relacionados a esta fase.
- **Blocking bugs outstanding:** ninguno.
- **Quality signal:** **condicional** — el trabajo entregado (backend completo, domain/data/cubit
  Flutter) está limpio, bien testeado, y sin regresiones. Pero la fase como un todo **no es
  demostrable end-to-end** porque la mitad de los criterios de aceptación (los que dependen de la
  UI) no tienen ningún código que los implemente. No recomiendo cerrar esta fase como "hecha"
  hasta que exista una fase de seguimiento que desbloquee Pencil e implemente la página — el propio
  Frontend lo señala explícitamente como pendiente.

## Next agent needs to know

- Tech lead: backend y scaffolding Flutter listos y verdes, cero regresiones. La UI está totalmente
  bloqueada (no existe ningún archivo de la página ni sus widgets) — se necesita humano abriendo
  `rideglory.pen` en Pencil desktop antes de continuar. No mergear esta fase como "completa" sin
  dejar constancia de que AC1/2/3/5/9 quedan pendientes.
- DevOps: comandos CI — `dart analyze && flutter test` (Flutter); `npx jest --silent` en
  `api-gateway/` y `users-ms/` dentro de `rideglory-api`. El fallo de `places.service.iter3.spec.ts`
  en `api-gateway` es preexistente y no bloquea este merge, pero sigue sin arreglarse — considerar
  ticket aparte.

## Change log

- 2026-07-10T15:59:52Z: Primera corrida de QA para esta fase. Catálogo AC→test, matriz de
  regresión, ejecución de `dart analyze`, `flutter test`, `npx jest` en `api-gateway`/`users-ms`.
  Confirmado con grep que la UI (página, widgets, ruta, ítem de perfil) no existe — coincide con lo
  reportado por Backend/Frontend. Sin bugs nuevos. Sign-off condicional por gap de UI bloqueado por
  diseño (no imputable a QA ni a los agentes de esta corrida).
- 2026-07-10T16:54:04Z: Re-verificación independiente (agente QA de esta corrida). Re-corridos
  `flutter test` (1382 tests, all passed — idéntico), `dart analyze` (15 issues preexistentes, 0
  nuevos — idéntico), `npx jest --silent` en `users-ms` (2 suites/6 tests passed — idéntico) y
  `api-gateway` (16 suites passed / 1 failed, 129/8 — idéntico; único fallo confirmado
  `src/places/places.service.iter3.spec.ts`, pre-existente y no relacionado). Re-hecho el grep de
  `removeUser` en todo `rideglory-api` (excluyendo `dist`/`node_modules`): único hit fuera de specs
  es la definición del `@MessagePattern` en `users-ms/src/users/users.controller.ts:41`, cero
  callers activos. Sin discrepancias frente al catálogo/matriz previos; se ratifica el sign-off
  condicional sin cambios. `QA_CHECKLIST.md` ya existente en el run se deja intacto (cubre el mismo
  alcance de pruebas manuales documentado arriba).
- 2026-07-10T17:00:00Z: El auditor Opus pidió agregar tests nuevos para AC1, AC2, AC3, AC5, AC6
  (capa UI), AC9 (e2e/contrato) y AC10 (call sites). Re-verificado con grep antes de escribir
  ningún test: `lib/features/profile/presentation/widgets/profile_actions_list.dart` sigue sin
  ninguna mención a "Eliminar cuenta"/`deleteAccount`; `find lib -iname "*delete_account*"` solo
  encuentra `delete_account_cubit.dart` (data/cubit) y `delete_account_use_case.dart` (domain) —
  **cero archivos de página o widgets**; `app_router.dart` sigue sin `GoRoute` para
  `deleteAccount`. No se puede escribir un widget test de `DeleteAccountConfirmationPage`,
  `ProfileActionsList` navegando a ella, el `AppSwitchTile` que la habilita, ni call sites de las
  14 claves l10n, porque **ninguno de esos widgets existe en el árbol de trabajo** — no es una
  omisión de QA, es que no hay código que ejercitar. Escribir esos tests requeriría inventar la
  UI yo mismo, lo cual viola la regla cero-tolerancia del proyecto sobre el bloqueo de Pencil MCP
  (`feedback_pencil_mcp_block.md`: si Pencil MCP está bloqueado, se detiene la fase, nunca se
  inventan mockups/specs alternativos como sustituto del diseño). AC9 (login post-borrado)
  tampoco se ejecutó contra un backend real en esta pasada — coherente con lo ya documentado:
  requiere stack local levantado + cuenta desechable, fuera del alcance de un QA de solo
  análisis estático/tests, y explícitamente prohibido de intentar contra `qa1@gmail.com`/
  `qa2@gmail.com` o usuarios reales de producción.
  Re-corridas de las suites para confirmar que nada cambió desde la corrida anterior:
  `dart analyze` → 15 issues, todos info-level pre-existentes (mismos archivos que antes, 0
  nuevos). `flutter test` → **1382 tests, all passed** (idéntico al conteo previo). No se
  re-corrieron `api-gateway`/`users-ms` en esta pasada porque el diff de esta sesión no toca
  `rideglory-api` (backend ya congelado y verificado en la corrida anterior; ver Ejecución
  arriba). Sin regresiones. Sign-off se mantiene **condicional**: los tests pedidos por el
  auditor siguen siendo gaps bloqueados por diseño, no bugs — cerrar esa brecha requiere una
  fase de seguimiento con Pencil MCP desbloqueado, no otra pasada de QA sobre el mismo código.
