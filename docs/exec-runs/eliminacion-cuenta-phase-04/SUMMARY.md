# SUMMARY — eliminacion-cuenta-phase-04

_Tech Lead review generado: 2026-07-11T18:15:28Z_

## Objetivo

Cerrar dos huecos de la fase 1 de eliminación de cuenta: (a) qué pasa si el usuario cierra la app
a mitad del borrado y la reabre, y (b) que reintentar `DELETE /users/me` (una o varias veces, en
carrera o en serie) converja siempre al mismo estado final correcto, sin duplicar efectos ni dejar
estados parciales. No se rediseña la UI de borrado (fase 1) ni la lógica de negocio de
transferencia/anonimización (fase 3) — solo se endurece el manejo de errores/idempotencia
alrededor de contratos ya fijados.

## Qué cambió por área

**Backend (`rideglory-api`, repo separado — working tree sucio, humano commitea por submódulo):**

- `api-gateway/src/users/account-deletion.service.ts`: nuevo helper `isNotFoundRpcError(error)`
  (duck-typing sobre la forma real del error que cruza `ClientProxy`). `deleteAccount()` envuelve
  el `findUserByEmail` inicial en try/catch — si el error es "no encontrado", retorna temprano
  (éxito idempotente, el controller ya responde `204`); cualquier otro error se relanza sin tocar.
  Este es el hallazgo más importante de la fase (no estaba en el PRD original): sin este fix, un
  reintento tras un borrado ya completo fallaba con un **404 no documentado**, violando el
  contrato `204/409/401/502`.
- `api-gateway/src/auth/firebase-auth.service.ts`: `deleteUser(uid)` agrega catch específico de
  `error.code === 'auth/user-not-found'` → no-op idempotente; cualquier otro código se relanza.
- `users-ms/src/users/users.service.ts`: `hardDelete(id)` ya no hace `findOne(id)` como
  precondición (eso hacía inalcanzable el catch de `P2025` que pedía el PRD original). Ahora llama
  `delete` directo envuelto en catch específico de `Prisma.PrismaClientKnownRequestError` código
  `P2025` → no-op idempotente (`return null`); cualquier otro error se relanza.
- `vehicles-ms`, `maintenances-ms`, `events-ms`: **sin cambios de código de producción** — solo
  tests de regresión que confirman que `hardDeleteAllByOwner`, `softDeleteMaintenancesByUserId` y
  `anonymizeByUserId` ya eran idempotentes por diseño (`findMany`-condicional / `updateMany`).
- Specs actualizados/nuevos en los 3 servicios tocados (`account-deletion.service.spec.ts`,
  `firebase-auth.service.spec.ts`, `users.service.spec.ts`) cubriendo retry-tras-éxito-completo,
  carrera concurrente, y rethrow de errores no relacionados.

**Frontend (Rideglory, este repo):**

- `lib/core/http/firebase_auth_interceptor.dart`: en `onError`, si el refresh forzado de token
  lanza `FirebaseAuthException` con `.code` en `{'user-not-found', 'user-disabled',
  'user-token-expired'}`, llama `GetIt.instance<AuthCubit>().signOut()` (patrón defensivo
  try/catch, igual que `_crashReporter()`) y muestra un snackbar vía
  `AppRouter.scaffoldMessengerKey`. Cualquier otro código (incluido
  `network-request-failed`) sigue el `catch (_) {}` mudo original. El 401 original siempre se
  propaga (`handler.next(err)`).
- `lib/l10n/app_es.arb` (+ regenerado `app_localizations.dart`/`app_localizations_es.dart`): nueva
  key `auth_sessionEndedSnackbar` = "Tu sesión terminó, inicia sesión de nuevo." (copy neutral, no
  menciona borrado de cuenta).
- `lib/features/users/data/repository/user_repository_impl.dart`: comentario documentando que el
  `receiveTimeout` global de 60s ya cubre el estimado de 30-45s de la orquestación — sin cambio
  funcional.
- `docs/architecture/DIAGRAMS.md`: dos diagramas de secuencia nuevos (idempotencia de
  `DELETE /users/me` + logout forzado del cliente).
- `test/core/http/firebase_auth_interceptor_test.dart` (nuevo): 5 casos cubriendo los 3 códigos de
  sesión invalidada, el caso transitorio (`network-request-failed`) y el camino sin excepción.

## Archivos

Dentro del change map de esta fase (12 archivos, ver `handoffs/architect.md`):

- `rideglory-api/api-gateway/src/users/account-deletion.service.ts` (+ spec)
- `rideglory-api/api-gateway/src/auth/firebase-auth.service.ts` (+ spec)
- `rideglory-api/users-ms/src/users/users.service.ts` (+ spec)
- `rideglory-api/vehicles-ms/src/vehicles/vehicles.service.spec.ts` (solo test, sin tocar producción)
- `rideglory-api/events-ms/src/registrations/registrations.service.spec.ts` (solo test, sin tocar producción)
- `lib/core/http/firebase_auth_interceptor.dart`
- `lib/l10n/app_es.arb`, `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_es.dart`
- `lib/features/users/data/repository/user_repository_impl.dart`
- `test/core/http/firebase_auth_interceptor_test.dart` (nuevo)
- `docs/architecture/DIAGRAMS.md`

**Fuera del change map, presentes en el mismo working tree (ver "Riesgos/watchlist"):**
`lib/core/services/crash/crash_handler_setup.dart`, `lib/main.dart`,
`integration_test/registration_patrol_test.dart`,
`test/core/services/crash/crash_handler_setup_test.dart`,
`test/features/event_registration/presentation/registration_detail_page_test.dart`,
`test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart`,
`docs/exec-runs/eliminacion-cuenta-phase-02/QA_CHECKLIST.md` (+ artefactos QA nuevos),
`docs/exec-runs/eliminacion-cuenta-phase-03/QA_CHECKLIST.md` (+ artefactos QA nuevos).
Todos son residuos de corridas QA/regresión anteriores en el mismo working tree — no fueron
introducidos por esta fase, confirmado leyendo el diff (no tocan idempotencia de borrado de
cuenta) y por la nota explícita de QA en `handoffs/qa.md`.

## Pruebas

- Backend: baseline verde en los 5 submódulos afectados antes de tocar nada; tras los cambios,
  `api-gateway` 18/18 (suite acotada) + 148/156 en la suite completa (8 fallos preexistentes de
  `PlacesService`, confirmados sin relación vía `git stash`); `users-ms` 7/7; `vehicles-ms` 51/51;
  `maintenances-ms` 3/3; `events-ms` 56/56.
- Frontend: `flutter test` completo 1406/1406 (1401 baseline + 5 nuevos del interceptor);
  `dart analyze` 0 issues nuevos (15 preexistentes en archivos no tocados).
- QA re-ejecutó independientemente: `firebase_auth_interceptor_test.dart` 5/5, suite Flutter
  completa 1406/1406, y las suites backend acotadas mencionadas — verde, sin regresiones.
- Cada AC del PRD tiene cobertura automatizada donde es técnicamente posible desde este entorno
  (AC3, AC4, AC5-unit, AC7); AC1, AC2 y la verificación en BD real de AC5 quedan como pruebas
  manuales pendientes de staging — gap **aceptado explícitamente por el Architect** (no hay
  infraestructura de integración con socket real ni BD real en este entorno de agente), no una
  omisión de esta corrida.

## Riesgos / watchlist

1. **Working tree con residuos de otras fases/corridas.** Antes de commitear, separar en commits
   distintos: (a) los cambios de fase-04 (idempotencia + interceptor + l10n + diagrama), (b) el
   fix de la race de Mapbox en `crash_handler_setup.dart`/`main.dart`, (c) el ajuste del test
   Patrol de registro, y (d) las actualizaciones de `QA_CHECKLIST.md`/artefactos de fase-02/03.
   Mezclarlos en un solo commit de "fase-04" sería engañoso para el historial.
2. **Doble `signOut()`/doble snackbar** si dos 401 llegan casi simultáneamente — aceptado como
   no-bloqueante por el Architect (idempotente, solo ruido visual). No reportar como bug.
3. **Gaps de prueba manual pendientes** (AC1, AC2, verificación en BD real de AC5) — deben
   ejecutarse en staging antes de considerar la fase completamente cerrada extremo a extremo (ver
   `REVIEW_CHECKLIST.md`).
4. **Riesgo residual documentado y fuera de alcance:** un ID token cacheado sigue siendo válido
   criptográficamente hasta por 1h tras el borrado (no se usa `checkRevoked: true`) — el Architect
   lo dejó documentado como riesgo conocido, no como bug de esta fase.
5. **`.DS_Store` sin trackear** en `rideglory-api` (raíz, `docs/`, `terraform/`) — no relacionados
   con esta fase, no commitear.

## Mensaje de commit sugerido

Para el repo Flutter (este repo), acotado a los archivos de esta fase:

```
fix(auth,users): logout forzado ante sesión invalidada tras borrado de cuenta

Cierra el interceptor de Firebase Auth para forzar signOut() + snackbar neutral
cuando el refresh de token confirma que el usuario ya no existe (user-not-found,
user-disabled, user-token-expired) — nunca ante errores transitorios de red.
Documenta la conclusión del timeout Dio (60s > 30-45s estimado) y agrega
diagramas de secuencia de idempotencia de DELETE /users/me.

eliminacion-cuenta-phase-04
```

Para `rideglory-api` (por submódulo, coordinado por el humano):

```
fix(users,auth): idempotencia de DELETE /users/me ante reintento y carrera

findUserByEmail, hardDelete y FirebaseAuthService.deleteUser ahora tratan
"ya no existe" como éxito idempotente en vez de relanzar un error no
documentado. Sin cambio de contrato HTTP (204/409/401/502 intactos).

eliminacion-cuenta-phase-04
```
