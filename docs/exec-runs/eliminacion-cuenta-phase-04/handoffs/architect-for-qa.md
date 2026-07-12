> Slim handoff — read this before handoffs/architect.md

# Architect → QA — eliminacion-cuenta-phase-04

## Test commands

- Flutter: `flutter test test/core/http/firebase_auth_interceptor_test.dart`, luego `flutter test`
  completo y `dart analyze`.
- Backend (por microservicio afectado): `npm test` en `api-gateway`, `users-ms`; smoke en
  `vehicles-ms`, `maintenances-ms`, `events-ms` para los tests de regresión de idempotencia
  agregados ahí.

## Trazabilidad de criterios de aceptación

| AC | Qué verificar | Cómo | Automatizable |
|---|---|---|---|
| 1. App cerrada antes de que la petición llegue | Reabrir app → sigue autenticado, puede reintentar borrado desde cero | Manual (matar app antes de tap en confirmar) — no hay cambio de código que probar, es comportamiento ya existente de `AuthCubit.checkAuthState()` | Manual |
| 2. App cerrada durante la petición en vuelo | Backend completa los 8 pasos en BD aunque el socket se cierre | Backend: test de integración desconectando el socket a mitad de `deleteAccount()`, o documentado como manual/staging si no hay infraestructura de integración | Backend (unit/integration) o manual si no aplica |
| 3. Borrado completo + primer 401 → logout automático + mensaje + redirect a login | Verificar snackbar "Tu sesión terminó, inicia sesión de nuevo." + navegación a `AppRoutes.login` sin intervención manual | Widget/unit test del interceptor (mockeando 401 + `FirebaseAuthException`) + smoke manual en staging con usuario real borrado | Automatizable (unit) + manual (e2e end-to-end con backend real) |
| 4. Reintentar `DELETE /users/me` nunca produce 500 ni estado parcial | Doble llamada (secuencial, tras error o tras éxito) → mismo estado final, siempre 204 | Backend unit tests (`account-deletion.service.spec.ts`, `users.service.spec.ts`, `firebase-auth.service.spec.ts`) | Automatizable |
| 5. Dos llamadas superpuestas (carrera), mismo `uid` → ambas 204, sin duplicados/huérfanos | Test de concurrencia backend (`Promise.all` de dos `deleteAccount()`), y verificación en BD real (no confiar solo en el mock) | Backend unit + verificación manual en BD de staging (usuarios de prueba, no producción) | Automatizable (unit) + manual (verificación BD) |
| 6. Timeout de 60s > 30-45s estimado | Confirmar `receiveTimeout` en `app_dio.dart` sigue en 60s; si hay evidencia real de staging de que no alcanza, debe estar documentada explícitamente, no solo asumida | Revisión de código + (opcional) medición real contra staging si el equipo lo pide | Manual (revisión de código) |
| 7. Interceptor no dispara logout ante errores de red transitorios | 401 con `FirebaseAuthException(code: 'network-request-failed')` no debe llamar `signOut()` | Unit test del interceptor | Automatizable |

## Guardrails a vigilar en QA

- El copy del snackbar debe ser exactamente neutral — nunca "tu cuenta fue eliminada" ni similar.
- La lista de códigos que disparan logout debe seguir acotada a
  `{user-not-found, user-disabled, user-token-expired}` — cualquier ampliación (p. ej.
  `network-request-failed`) es un bug de esta fase, no una mejora.
- El contrato de `DELETE /users/me` debe seguir siendo exactamente `204/409/401/502` — un `404` u
  otro código nuevo filtrándose es una regresión de esta fase, no un caso nuevo aceptable.
- No debe aparecer ningún nuevo endpoint, tabla de estado de borrado, ni mecanismo de polling.

## Usuarios de prueba

Usar `qa1@gmail.com` (rider) para el flujo de borrado — **no** `qa2@gmail.com` (organizador de "Mi
Evento", tiene precondición 409 bloqueante por diseño, útil solo para probar ESA precondición, no
esta fase). Verificar en BD (no solo UI) que tras el borrado no quedan filas huérfanas.

> Full detail: handoffs/architect.md
