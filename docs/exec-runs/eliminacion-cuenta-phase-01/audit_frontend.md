# Auditoría Frontend — eliminacion-cuenta-phase-01

_Auditor Opus · 2026-07-10T16:49:41Z_

## Veredicto: NO APROBADO (score 46/100)

La fase queda **incompleta**: la pieza central de la fase (el flujo de UI de eliminación de
cuenta) no se implementó. El agente Frontend documenta 8 intentos, todos bloqueados por el MCP de
Pencil (`get_editor_state → MCP error -32603: A file needs to be open in the editor`). Correctamente
**no** inventó un mockup HTML alternativo (regla cero-tolerancia `feedback_pencil_mcp_block.md`).
El bloqueo es legítimo y externo al agente, pero como auditor no puedo certificar cumplidos los
criterios de aceptación cuando la mayoría depende de la pantalla ausente.

## Lo entregado (scaffolding domain/data/cubit/l10n/analytics) — DEFENDIBLE y de buena calidad

- `DeleteAccountUseCase` (`@injectable`, delega al repo) — limpio.
- `UserRepositoryImpl.deleteMyAccount()` — `executeService` + `Nothing`, sin BuildContext. Correcto.
- `UserService.deleteMyAccount()` — `@DELETE(ApiRoutes.me)`, sin URL hardcodeada (`ApiRoutes.me = '/users/me'`).
- `DeleteAccountCubit extends Cubit<ResultState<Nothing>>` — sin flags booleanos, guard de doble-tap
  (`if (state is Loading<Nothing>) return;`). Cumple el patrón del proyecto.
- 3 eventos de analytics sin PII, ≤40 chars, snake_case — verificados por `analytics_taxonomy_no_pii_test`.
- 14 claves `profile_deleteAccount_*` en `app_es.arb`.
- Constante de ruta `AppRoutes.deleteAccount` (sin `GoRoute` todavía).
- `dart analyze` sobre archivos tocados: **No issues found**.
- Tests nuevos (use case, repo impl, cubit incl. guard de doble-tap): corrida focalizada
  **269 tests, All tests passed**. Fallarían sin el cambio (mockean el método nuevo y la máquina de estados).

## Criterios de aceptación

| AC | Estado |
|----|--------|
| AC1 item→página | ❌ no implementado (sin item en `ProfileActionsList`, sin página) |
| AC2 lista completa de qué se borra | ❌ (claves l10n existen pero sin UI que las consuma) |
| AC3 botón deshabilitado hasta switch | ❌ |
| AC4 loading + guard doble-tap | ⚠️ parcial — guard en cubit + test ✅; UI ausente |
| AC5 éxito limpia cubits + `goAndClearStack` | ❌ |
| AC6 estado error + retry manual | ⚠️ cubit emite `error` ✅; UI/banner/retry ausentes |
| AC7 orden 5 pasos backend | (backend — fuera de este agente) |
| AC10 strings vía `context.l10n` | ❌ claves declaradas pero no accedidas (sin UI) |
| AC11 dart analyze / un widget por archivo | ✅ para lo entregado (no hay widgets nuevos) |

## Higiene del working tree (para el humano, no del agente)

El diff mezcla cambios ajenos a esta fase (eliminación de drafts/events: `my_drafts_*`,
`event_card_draft_badge`, `eventsDraftSaved`, `event_saveDraft`, `draft_myDrafts*`, tracking ws,
tecnomecánica, home, `rideglory.pen` ±11k líneas, decenas de tests/Patrol nuevos). No son de este
agente pero contaminan el commit de la fase. Separar antes de commitear.

## Requerido para aprobar

1. Desbloquear Pencil (humano abre `rideglory.pen` con editor activo), diseñar la pantalla, aprobar.
2. Implementar `DeleteAccountConfirmationPage` + 4 widgets hijos (uno por archivo, sin `_buildX()`),
   `GoRoute` en `app_router.dart`, item destructivo en `profile_actions_list.dart`, y los call sites
   de los 3 eventos de analytics.
3. Wiring de éxito: limpiar `AuthCubit`/`VehicleCubit`/`ProfileCubit` + `context.goAndClearStack(login)`.
4. Tests de widget que ejerciten AC3 (switch habilita botón), AC4 (spinner + no 2ª llamada),
   AC5 (navegación/limpieza), AC6 (banner error + retry).
