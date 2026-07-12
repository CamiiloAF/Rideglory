# QA Automator — eliminacion-cuenta-phase-04

_Generado: 2026-07-12T03:14:10Z_

## Resumen

11 casos evaluados. 9 confirmados en verde vía tests existentes (5 Flutter unit + 4
backend jest, ya escritos por Frontend/Backend en esta misma fase — cumplen "reusa
patrones existentes", no se duplicó ningún test). 2 casos son `no-auto`: uno por revisión
textual de código (no requiere test, ya lo cubre 6.6/6.4 directamente) — en realidad las
verificaciones textuales (6.4, 6.5) se resolvieron por lectura de archivo, no por test, y
se marcan como `auto-pass` con evidencia textual, tal como indica el playbook para
`run-existing`/revisión de código. El único caso genuinamente no automatizable es 3.3
(redirect visual multi-pantalla tras logout forzado por 401 real), que requiere un usuario
ya borrado en Firebase Auth contra un backend real — no reproducible con mocks ni con la
infraestructura Patrol actual sin ese fixture.

No se escribió ningún test nuevo: los 5 casos Flutter y los 6 casos backend/run-existing ya
tenían cobertura suficiente (creada por los agentes Frontend/Backend de esta misma fase,
ver `handoffs/frontend.md` y `handoffs/backend.md`). El trabajo de este agente fue: (a)
ejecutar y confirmar en verde cada suite relevante, (b) verificar por lectura de código los
2 guardrails textuales (6.4, 6.5), y (c) clasificar honestamente 3.3 como no-auto.

## Comandos ejecutados

```bash
# Flutter
flutter test test/core/http/firebase_auth_interceptor_test.dart
dart analyze test/core/http/firebase_auth_interceptor_test.dart
grep -rn "auth_sessionEndedSnackbar" lib/l10n/app_es.arb
grep -rln "Tu sesión terminó" lib/
sed -n '1,30p' lib/core/http/app_dio.dart
grep -n "sessionInvalidatedCodes\|user-not-found\|user-disabled\|user-token-expired" lib/core/http/firebase_auth_interceptor.dart

# Backend (rideglory-api)
cd api-gateway && npx jest src/users/account-deletion.service.spec.ts src/auth/firebase-auth.service.spec.ts
cd users-ms && npx jest src/users/users.service.spec.ts
```

## Resultados por caso

| ID | Estado | Evidencia |
|---|---|---|
| 3.1 | auto-pass | `flutter test test/core/http/firebase_auth_interceptor_test.dart` → 5/5 verde, incluye los 3 códigos de sesión invalidada disparando `signOut()`. |
| 3.2 | auto-pass | Mismo archivo: assert de `SnackBar` mostrado vía `AppRouter.scaffoldMessengerKey`; texto confirmado además por lectura directa de `app_es.arb` línea 1381 (`auth_sessionEndedSnackbar` = "Tu sesión terminó, inicia sesión de nuevo.", sin mención a "cuenta eliminada"). |
| 3.3 | no-auto | Requiere navegación real multi-pantalla (`GoRouterRefreshStream`) tras un 401 real contra un usuario efectivamente borrado en Firebase Auth + backend real. No hay fixture de "usuario ya borrado en Firebase" disponible en este entorno de agente ni infraestructura Patrol que simule el 401 exacto sin un backend real. Confirmado no forzable con mocks sin tocar producción. Coincide con lo documentado en `handoffs/qa.md` como pendiente de staging. |
| 4.2 | auto-pass | `npx jest src/users/account-deletion.service.spec.ts src/auth/firebase-auth.service.spec.ts` (api-gateway) → 18/18 verde; incluye retry-after-full-completion (404 objeto plano y RpcException) resolviendo sin error. `npx jest src/users/users.service.spec.ts` (users-ms) → 5/5 verde, incluye no-op P2025. |
| 4.3 | auto-pass | Mismo run de api-gateway: los 2 tests de carrera concurrente (`concurrent race: two overlapping...`, `concurrent race: second call arrives after the first fully completed...`) pasan; ambas llamadas resuelven `fulfilled`/sin excepción. |
| 5A.1 | auto-pass | Caso `network-request-failed` en `firebase_auth_interceptor_test.dart` (parte de la corrida 5/5): confirma que NO se llama `signOut()` ni se muestra snackbar, error original propagado sin alteración. |
| 6.2 | auto-pass | Log de consola capturado durante `npx jest account-deletion.service.spec.ts`: línea `[AccountDeletionService] deleteAccount: user for email already deleted, treating as idempotent success` — confirma resolución idempotente sin error 500/404 no controlado. |
| 6.3 | auto-pass | Test `concurrent race: second call arrives after the first fully completed...` asserta explícitamente `expect(mockFirebaseAuthService.deleteUser).toHaveBeenCalledTimes(1)` — Firebase `deleteUser` no se invoca doble para el mismo uid. |
| 6.4 | auto-pass | Lectura directa de `lib/core/http/app_dio.dart` línea 19: `receiveTimeout: Duration(seconds: 60)`, sin overrides ni cambios respecto al valor documentado. |
| 6.5 | auto-pass | Lectura directa de `lib/l10n/app_es.arb`: key `auth_sessionEndedSnackbar` = "Tu sesión terminó, inicia sesión de nuevo." (copy exacto, neutral). `grep -rln "Tu sesión terminó" lib/` solo devuelve el ARB y sus dos archivos generados (`app_localizations.dart`, `app_localizations_es.dart`) — sin hardcodeo duplicado en widgets. |
| 6.6 | auto-pass | Lectura de `firebase_auth_interceptor.dart` líneas 17-20: `_sessionInvalidatedCodes = {'user-not-found', 'user-disabled', 'user-token-expired'}`, exactamente 3 códigos, sin `network-request-failed`. Confirmado además por el test negativo de 3.1/5A.1 en la misma suite (5/5 verde).

## Archivos tocados por este agente

Ninguno bajo `test/**` ni `integration_test/**` — no se escribió test nuevo porque ya
existía cobertura suficiente para todos los casos automatizables. Único archivo nuevo:
este reporte (`docs/exec-runs/eliminacion-cuenta-phase-04/QA_AUTO_REPORT.md`).

## Nota sobre el working tree

El working tree del repo Flutter ya estaba sucio antes de esta corrida (cambios de
Frontend de esta misma fase + residuos no relacionados de fases 02/03, documentados en
`handoffs/qa.md`). Este agente no modificó ningún archivo bajo `lib/`, `test/` ni
`integration_test/`. El repo backend (`rideglory-api`) tampoco fue tocado por este agente;
su estado sucio corresponde al trabajo ya reportado por el agente Backend de esta fase.
