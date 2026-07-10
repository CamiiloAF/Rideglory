# Auditoría de cobertura de pruebas — eliminacion-cuenta-phase-01

**Fecha:** 2026-07-10T16:56:30Z
**Auditor:** Opus (test-coverage)
**Veredicto:** NO APROBADO (score 55) — cobertura sólida en lo implementado, pero 5+ AC sin
ninguna prueba que fallaría sin el cambio, por el bloqueo de UI (Pencil MCP caído).

## Método

Para cada AC de §5 se verificó que exista al menos una prueba con aserción no trivial que fallaría
si el cambio se revirtiera. Se leyó el código fuente además del test para confirmar que la aserción
es load-bearing (no un test vacío/verde-falso).

## AC → cobertura

| AC | Prueba | ¿Fallaría sin el cambio? | Estado |
|----|--------|--------------------------|--------|
| AC1 | — | — | GAP — sin item en `profile_actions_list.dart`, sin test |
| AC2 | — | — | GAP — página no existe |
| AC3 | — | — | GAP — `AppSwitchTile` gate no existe, sin widget test |
| AC4 | `delete_account_cubit_test.dart` (guard doble-tap) | Sí — dos calls concurrentes; sin `if (state is Loading) return;` el mock se invocaría 2 veces y `.called(1)` fallaría | CUBIERTO |
| AC5 | — | — | GAP — sin wiring de limpieza (Auth/Vehicle/Profile) ni `goAndClearStack`, sin test |
| AC6 | `delete_account_cubit_test.dart` (loading→error) | Parcial — el estado `error` a nivel cubit sí falla sin el fold; pero mensaje en español + retry manual en UI no se testean | PARCIAL |
| AC7 | `account-deletion.service.spec.ts` (3 tests) | Sí — `callOrder` exacto + corte en 404 (paso1) + corte en fallo de hardDelete que nunca llama Firebase. Verificado en `.ts`: sin try/catch que trague el error del paso 4 | CUBIERTO |
| AC8 | `users.service.spec.ts` + `users.controller.spec.ts` (users-ms) | Sí — `hardDelete` usa `prisma.user.delete`; regresión: `remove()` usa `update({isDeleted:true})` y nunca `delete`; controller enruta a patrones distintos | CUBIERTO |
| AC9 | — | — | GAP — login post-borrado; e2e/manual diferido, sin prueba automatizada |
| AC10 | grep de 13 claves l10n en `app_es.arb`; `analytics_taxonomy_no_pii_test.dart` (eventos) | No para UI — las 13 claves existen pero sin call site; ningún test asegura cero strings hardcodeados en la página | PARCIAL/N-A (página no existe) |
| AC11 | `dart analyze` (ejecutado) | Parcial — analyze limpio, pero "un widget por archivo/sin `_buildX()`" es N/A: no se crearon widgets de página | PARCIAL |

## Aspectos positivos (no inflar el score, pero reconocerlos)

- Los 3 AC de backend/orquestación (AC4 lógica de guard, AC7, AC8) tienen tests de secuencia
  observables y regresión explícita — exactamente lo que pide el guardrail §6 (verificar orden con
  test, no solo revisión). Son las partes de mayor blast radius y están bien cubiertas.
- `users.controller.spec.ts` (api-gateway) cubre además el guardrail de `uid` desde token (nunca de
  params/body) con un request "envenenado" — buena defensa aunque no sea un AC numerado.

## Cambios requeridos (cobertura faltante)

1. **AC1** — falta widget test de `ProfileActionsList` que verifique navegación a
   `DeleteAccountConfirmationPage` (no `ConfirmationDialog`). Bloqueado: el item no existe.
2. **AC2** — falta widget test de `DeleteAccountConfirmationPage` que verifique que renderiza la
   lista completa (incluidos ítems fase 2/3). Bloqueado: página no existe.
3. **AC3** — falta widget test: botón de confirmación deshabilitado hasta activar el `AppSwitchTile`.
   Bloqueado: widget no existe.
4. **AC5** — falta test (widget o de integración del cubit+router) que verifique limpieza de
   `AuthCubit`/`VehicleCubit`/`ProfileCubit` y `goAndClearStack(login)` en éxito. Hoy el cubit solo
   emite `data(Nothing())`; nada prueba el efecto post-éxito.
5. **AC6** — falta widget test de la capa UI: banner de error con mensaje en español + botón de
   retry manual que re-dispara `deleteAccount()` (el cubit está cubierto; la UI no).
6. **AC9** — falta prueba (e2e con cuenta desechable o test de contrato contra el endpoint) de que
   el login posterior falla. Diferido correctamente, pero sigue siendo cobertura ausente.
7. **AC10** — falta call site en widgets y su test; imposible auditar "cero strings hardcodeados"
   hasta que la página exista.

## Conclusión

Ninguno de los gaps es un bug ni imputable a los agentes: son consecuencia del bloqueo de Pencil MCP
(regla cero-tolerancia del proyecto). Pero desde la lente de cobertura de pruebas la fase no puede
aprobarse como cerrada: más de la mitad de los AC (1,2,3,5,9 y las mitades UI de 6,10,11) no tienen
ninguna prueba que fallaría sin el cambio. Se recomienda no marcar la fase como "hecha" y abrir una
fase de seguimiento que desbloquee Pencil, implemente la página y sus widgets, y agregue los tests
arriba antes de considerar el flujo demostrable end-to-end.
