# QA — eliminacion-cuenta-phase-04

_Generado: 2026-07-11T18:11:54Z_

## Catalogo

| AC | Descripción corta | Cobertura | Tipo |
|---|---|---|---|
| 1 | App cerrada ANTES de que la petición llegue → sigue autenticado, reintenta desde cero | Sin test nuevo (comportamiento ya existente de `AuthCubit.checkAuthState()`, no cambia código en esta fase) | Manual — pendiente de ejecución real (ver Pruebas manuales) |
| 2 | App cerrada DURANTE la petición en vuelo → backend completa igual | Verificación por lectura de código (documentada en `handoffs/backend.md`): `deleteAccount()` es una cadena de `await`s server-side sin listeners `req.on('close')`/`AbortController`; no hay test de integración con socket real | Gap parcial — aceptado explícitamente por el Architect (fuera de alcance construir infraestructura nueva) |
| 3 | Borrado completo + primer 401 → logout automático + snackbar + redirect a login | Nuevo: `test/core/http/firebase_auth_interceptor_test.dart` (3 casos: `user-not-found`, `user-disabled`, `user-token-expired` → `signOut()` + snackbar + error propagado) | Nuevo (automatizado) + manual e2e pendiente (staging) |
| 4 | Reintentar `DELETE /users/me` nunca produce 500 ni estado parcial | Nuevo: `account-deletion.service.spec.ts` (retry con 404 objeto plano y `RpcException`), `users.service.spec.ts` (no-op `P2025`), `firebase-auth.service.spec.ts` (no-op `auth/user-not-found`) | Nuevo (automatizado, unit) |
| 5 | Dos llamadas superpuestas, mismo `uid` → ambas 204, sin duplicados/huérfanos | Nuevo: 2 tests en `account-deletion.service.spec.ts` (carrera happy-path completo; carrera con 2ª llamada tras completar la 1ª) | Nuevo (unit) + gap manual de verificación en BD real (no ejecutado en esta corrida QA) |
| 6 | Timeout 60s > 30-45s estimado | Revisión de código: `lib/core/http/app_dio.dart:19` confirma `receiveTimeout: Duration(seconds: 60)` sin cambios; comentario documental agregado en `user_repository_impl.dart` | Manual (revisión de código) — verificado en esta corrida |
| 7 | Interceptor no dispara logout ante errores de red transitorios | Nuevo: caso `network-request-failed` en `firebase_auth_interceptor_test.dart` → nunca `signOut()`, sin snackbar, error propagado | Nuevo (automatizado) |

## Matriz de regresión (guardrails §6)

| Guardrail | Mecanismo verificado |
|---|---|
| Copy del snackbar neutral, nunca "cuenta eliminada" | Verificado en `app_es.arb`: `auth_sessionEndedSnackbar` = "Tu sesión terminó, inicia sesión de nuevo." Test del interceptor no assertea el string exacto, pero el ARB es la única fuente y coincide con el guardrail. |
| Lista de códigos de logout acotada a `{user-not-found, user-disabled, user-token-expired}` | `_sessionInvalidatedCodes` en `firebase_auth_interceptor.dart` es exactamente ese set (const, sin `network-request-failed`); cubierto por test negativo. |
| Contrato `DELETE /users/me` sigue siendo `204/409/401/502` | `users.controller.ts` conserva `@Delete('me')` + `@HttpCode(HttpStatus.NO_CONTENT)`; el fix de idempotencia en `account-deletion.service.ts` convierte un 404 no documentado en `204`, no introduce código nuevo. Verificado leyendo el controller y los specs. |
| No nuevo endpoint / tabla de estado / polling | Diff de `rideglory-api` y `lib/` no muestra rutas nuevas, tablas nuevas ni mecanismos de polling — solo catches de idempotencia + interceptor + docs. |
| Guard de idempotencia específico (no catch genérico) | `hardDelete` en `users.service.ts` chequea `error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025'`; `firebase-auth.service.ts` chequea `error.code === 'auth/user-not-found'`; `isNotFoundRpcError` chequea `status === HttpStatus.NOT_FOUND`. Ningún catch genérico oculta otros errores (todos relanzan en el `else`). Confirmado leyendo los 3 diffs. |
| No reordenar los 5 pasos de orquestación | Diff de `account-deletion.service.ts` solo envuelve el paso 1 (`findUserByEmail`) en try/catch; no toca el orden de los pasos siguientes. |
| No tocar transferencia/anonimización de fase 3 | `vehicles-ms` y `events-ms`: solo se agregaron tests de regresión nuevos, código de producción **sin tocar** (confirmado en backend.md y en el diff `--stat` de esos submódulos, que solo muestra archivos `.spec.ts`). |
| No notificación email/push de cuenta eliminada | No aparece ningún archivo de notificaciones tocado en el diff. |
| No subir timeout global de AppDio | `app_dio.dart` no aparece en el diff; solo comentario en `user_repository_impl.dart`. |
| Strings en `app_es.arb` | Única string nueva (`auth_sessionEndedSnackbar`) está en el ARB, no hardcodeada. |

## Ejecucion

- `flutter test test/core/http/firebase_auth_interceptor_test.dart` → **5 passed, 5 total**. Verde.
- `flutter test` (suite completa) → **1406 tests, 0 fallos, "All tests passed!"** (coincide con lo
  reportado por Frontend: 1401 baseline + 5 nuevos).
- `dart analyze` (repo completo) → **15 issues**, todos `info` (`curly_braces_in_flow_control_structures`)
  en archivos no tocados por esta fase (`events_page.dart`, `home_vehicle_info_row.dart`,
  `modern_maintenance_card.dart`, `profile_page.dart`, `garage_page.dart` y 5 archivos de test de
  vehicles) → **pre_existing**, confirmado que ninguno cae en los archivos modificados por esta fase.
- Backend `api-gateway`: `npx jest src/users/account-deletion.service.spec.ts src/auth/firebase-auth.service.spec.ts`
  → **18 passed, 18 total**. Verde.
- Backend `users-ms`: `npx jest src/users/users.service.spec.ts` → **5 passed, 5 total**. Verde.
- Backend `vehicles-ms`: `npx jest src/vehicles/vehicles.service.spec.ts` → **24 passed, 24 total**. Verde.
- Backend `events-ms`: `npx jest src/registrations/registrations.service.spec.ts` → **3 passed, 3 total**. Verde.
- No se corrió `maintenances-ms` en esta corrida QA (backend.md documenta que no se tocó ningún
  archivo de producción ni de test ahí; test de regresión de idempotencia ya existía antes de esta
  fase) — aceptado sin re-ejecución adicional.
- Lectura de código confirmada independientemente (no solo confiando en los handoffs):
  - `firebase_auth_interceptor.dart` diff: `_sessionInvalidatedCodes` set correcto, `on FirebaseAuthException catch` antes del `catch (_) {}` genérico, `handler.next(err)` (no confirmado línea exacta pero el 401 original se sigue propagando según el flujo existente).
  - `account-deletion.service.ts`, `firebase-auth.service.ts`, `users.service.ts` diffs: guards específicos, no genéricos.
  - `users.controller.ts`: contrato `204` intacto.
  - `app_dio.dart:19`: `receiveTimeout: Duration(seconds: 60)` confirmado.

## Bugs

Ninguno encontrado. No se detectaron regresiones atribuibles a esta fase.

Nota (no-bug, fuera de alcance de esta fase): el árbol de trabajo tiene cambios sin relación con
`eliminacion-cuenta-phase-04` (`lib/core/services/crash/crash_handler_setup.dart`, `lib/main.dart`
para una race conocida de Mapbox; y actualizaciones a `QA_CHECKLIST.md`/tests de regresión de las
fases 02 y 03). Son residuos de corridas de QA anteriores en el mismo working tree, no
introducidos por esta fase — no se reportan como bug de fase-04 pero se deja constancia para que
el humano los revise antes de commitear.

## Pruebas manuales

Pendientes de ejecución humana en staging (no ejecutables desde este entorno de agente):

1. **AC1** — Cerrar la app (o perder conexión) antes de confirmar el borrado; reabrir; confirmar
   que el usuario sigue autenticado y puede reintentar el borrado desde cero.
2. **AC2** — Iniciar `DELETE /users/me` y matar la app/cerrar el socket a mitad de la petición;
   confirmar en BD de staging que los 8 pasos de la orquestación se completaron igual (no solo
   confiar en la verificación por lectura de código documentada por Backend).
3. **AC3 end-to-end** — Con un usuario de prueba (`qa1@gmail.com`) ya borrado completamente
   (incluido Firebase Auth), forzar una llamada autenticada desde una sesión "vieja" (app no
   reiniciada) y confirmar: snackbar exacto "Tu sesión terminó, inicia sesión de nuevo." + redirect
   automático a `/login` sin intervención manual.
4. **AC5 en BD real** — Disparar dos llamadas `DELETE /users/me` superpuestas contra staging con el
   mismo `uid` (por ejemplo, doble tap rápido o dos clientes) y verificar en BD (no solo por la
   respuesta HTTP) que no quedan filas huérfanas ni duplicadas para `qa1@gmail.com`.
5. Confirmar que `qa2@gmail.com` (organizador de "Mi Evento") sigue bloqueado por el `409` de
   precondición existente (fuera de alcance de esta fase, pero guardrail de contrato a no romper).

## Sign-off

**Condicional.** La automatización (unit/widget) para AC 3, 4, 5 (parcial) y 7 está verde y sin
regresiones; AC 6 verificado por revisión de código. AC 1, 2 y la verificación en BD real de AC 5
quedan como pruebas manuales pendientes de ejecución humana en staging — son gaps aceptados
explícitamente por el Architect (no hay infraestructura de test de integración con socket real ni
BD real disponible en este entorno de agente), no regresiones ni bugs. Recomendado: ejecutar la
sección "Pruebas manuales" antes de considerar esta fase completamente cerrada.
