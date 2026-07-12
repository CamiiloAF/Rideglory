# Frontend → eliminacion-cuenta-phase-04

Fecha: 2026-07-11T17:54:19Z

## Baseline

- `flutter test` (antes de cualquier cambio): 1401 tests, todos en verde (0 fallos, `All tests
  passed!`).

## Archivos cambiados

1. `lib/core/http/firebase_auth_interceptor.dart` — cambio funcional real. En `onError`, el
   refresh forzado de token ahora captura específicamente `FirebaseAuthException`. Si su
   `.code` está en `{'user-not-found', 'user-disabled', 'user-token-expired'}`:
   - Obtiene `AuthCubit` de GetIt de forma defensiva (`_authCubit()`, mismo patrón que
     `_crashReporter()` en `rest_client_functions.dart`) y llama `.signOut()`.
   - Muestra el snackbar vía `AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(...)`
     usando `RidegloryL10n.current.auth_sessionEndedSnackbar` (acceso a l10n sin
     `BuildContext`, ya que el interceptor no tiene uno).
   - Cualquier otro código (incluido `network-request-failed`) sigue el `catch (_) {}` mudo
     original, sin logout.
   - El 401 original siempre se propaga (`handler.next(err)`); no se resuelve como éxito.
   - No se tocó `app_router.dart` — el redirect a login ya reacciona solo al `signOut()` vía
     `GoRouterRefreshStream`.

2. `lib/l10n/app_es.arb` — nueva key `auth_sessionEndedSnackbar`: "Tu sesión terminó, inicia
   sesión de nuevo." (copy neutral, nunca menciona eliminación de cuenta).

3. `lib/l10n/app_localizations.dart` y `lib/l10n/app_localizations_es.dart` — regenerados con
   `flutter gen-l10n` a partir del nuevo key del ARB.

4. `lib/features/users/data/repository/user_repository_impl.dart` — comentario documentando
   que el `receiveTimeout` global de `AppDio` (60s) ya excede el estimado de 30-45s de la
   orquestación de 8 pasos del backend (`account-deletion.service.ts`). Sin cambio funcional.

5. `test/core/http/firebase_auth_interceptor_test.dart` (nuevo; la carpeta `test/core/http/`
   ya existía por `rest_client_functions_test.dart`, no hizo falta crearla). 5 casos con
   `mocktail` + `testWidgets` (se necesita un árbol de widgets real para
   `AppRouter.scaffoldMessengerKey` y para verificar el `SnackBar` mostrado):
   - Refresh sin `FirebaseAuthException` (token fresco `null`, i.e. camino "no hubo error de
     sesión invalidada") → nunca `signOut()`, sin snackbar, error original propagado.
   - Refresh falla con `user-not-found` → `signOut()` llamado 1 vez, snackbar mostrado, error
     original propagado.
   - Refresh falla con `user-disabled` → ídem.
   - Refresh falla con `user-token-expired` → ídem.
   - Refresh falla con `network-request-failed` → nunca `signOut()`, sin snackbar, error
     original propagado.

   Notas técnicas del test:
   - `ErrorInterceptorHandler.future` (getter `@protected` de `_BaseHandler`, no exportado
     públicamente) se usa para esperar el resultado del handler; se documenta con
     `// ignore: invalid_use_of_protected_member`.
   - El `Completer` interno rechaza con `InterceptorState<DioException>` (tipo interno de
     `dio`, oculto en el export del paquete), no con `DioException` directamente — el helper
     `awaitPropagatedError()` lo desenreda vía acceso dinámico a `.data`.
   - El primer caso ("refresh exitoso") deliberadamente evita ejercitar el camino de reintento
     real (`Dio().fetch(...)`, que abriría un socket real) devolviendo `null` como token
     fresco: lo relevante para esta fase es solo que la ausencia de `FirebaseAuthException` no
     dispare logout, no la mecánica de reintento (que ya existía y no cambió).

## Archivos que el plan mencionaba pero NO se tocaron (fuera de alcance de este agente)

Los cambios de `rideglory-api/**` (account-deletion.service.ts, users.service.ts,
firebase-auth.service.ts, y sus specs) y `docs/architecture/DIAGRAMS.md` corresponden al
agente Backend/Architect de esta fase, no al Frontend. No se tocó nada bajo
`rideglory-api/` ni `docs/architecture/`.

## Pruebas nuevas

- `test/core/http/firebase_auth_interceptor_test.dart` — 5 tests, cubren los 3 códigos de
  sesión invalidada + el caso transitorio (`network-request-failed`) + el caso sin excepción.

## Resultado final

- `dart analyze` (solo archivos tocados): 0 issues.
- `dart analyze` (repo completo): 15 issues, todos preexistentes (`curly_braces_in_flow_control_structures`,
  info-level, en archivos no tocados por esta fase) — ninguno nuevo introducido.
- `flutter test` (suite completa, tras los cambios): 1406 tests, 0 fallos, `All tests passed!`
  (1401 baseline + 5 nuevos de esta fase).

## Verificación manual

No aplica build/run manual en este ciclo (cambio acotado a un interceptor HTTP + l10n +
comentario de documentación). La verificación automatizada (unit/widget tests) cubre los 4
escenarios de códigos de Firebase Auth relevantes. Para verificación manual end-to-end se
necesitaría: forzar a mano un 401 desde el backend con un usuario ya eliminado (o deshabilitado
en Firebase Auth Console) y confirmar que la app muestra el snackbar "Tu sesión terminó, inicia
sesión de nuevo." y redirige a login — esto requiere coordinarse con QA/Backend ya que depende
de los fixes de idempotencia del backend de esta misma fase.

## Notas para QA

- Verificar que el snackbar de sesión terminada NUNCA aparece ante errores de red transitorios
  (modo avión, backend caído) — solo ante los 3 códigos específicos de Firebase Auth.
- Verificar que tras el logout forzado, el usuario aterriza en la pantalla de login (redirect
  automático del router) y no en una pantalla en blanco o con estado inconsistente.
- El copy del snackbar es deliberadamente neutral y NUNCA debe decir "tu cuenta fue eliminada"
  — es un guardrail del PRD para no filtrar el estado de borrado a un dispositivo con sesión
  antigua.
- No hay cambios de UI en `DeleteAccountConfirmationPage` ni en sus widgets asociados; esta
  fase es puramente de manejo de errores HTTP + reconciliación de sesión.
