# Regresión e2e permanente — Inscripción (con verificación de BD)

Fase: legal-privacidad-edad-fase7-organizador
Test: `integration_test/registration_patrol_test.dart`
Fecha (UTC): 2026-07-03T18:27:57Z — 2026-07-03T18:37:03Z

## Pasos ejecutados

1. Verificado que `integration_test/registration_patrol_test.dart` existe.
2. Pre-limpieza: `DELETE FROM "EventRegistration" ... WHERE e.name='Mi Evento' AND er.email='qa1@gmail.com' AND er.status='PENDING'` → `DELETE 0` (ya estaba limpio).
3. Backend local verificado arriba (`curl http://localhost:3000/api/health` → `{"status":"ok"}`; events-ms/users-ms/etc. escuchando en 3000/3001/3002).
4. `printenv TEST_EMAIL` / `printenv TEST_PASSWORD` → vacíos (no configurados en el entorno de esta corrida).
5. Corrido el Patrol SIN credenciales (comando exacto abajo). `bootstrapSession` usó el default `String.fromEnvironment` (`tu_email@ejemplo.com` / `tu_password`), el login falló silenciosamente (la app se quedó en el formulario de login) y el helper agotó el timeout de 30s esperando el bottom-nav "EVENTOS".
6. Limpieza final: repetido el mismo DELETE → `DELETE 0` (idempotente, sin residuos de qa1@gmail.com en "Mi Evento").

## Comando exacto corrido

```
patrol test -t integration_test/registration_patrol_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json
```

(No se agregaron `--dart-define=TEST_EMAIL=...`/`TEST_PASSWORD=...` porque no estaban presentes en el entorno, según instrucción de la fase.)

## Resultado

- **result: skip** — el test NO llegó a ejercitar el flujo de inscripción; falló en el bootstrap de sesión (login) por falta de credenciales reales (`TEST_EMAIL`/`TEST_PASSWORD` no configuradas en el entorno de esta corrida). No es una regresión del flujo de inscripción/consentimientos: el wizard, el sheet Ley 1581 y el waiver nunca se alcanzaron.
- Paso que falló: `bootstrapSession` → `waitUntilVisible` de "EVENTOS" (bottom-nav), tras 30s, porque el login con credenciales placeholder no autenticó.
- **dbVerification: skip** — no aplica: al no completarse el login no hubo inscripción que verificar. La BD se dejó limpia (pre y post limpieza ambas en 0 filas).

## Para reproducir con verificación real

Exportar `TEST_EMAIL=qa1@gmail.com` y `TEST_PASSWORD=<password real de qa1>` en el entorno antes de correr este mismo comando; entonces sí se podrá evaluar pass/fail real del wizard y la verificación de BD (`medicalConsentVersion`/`riskAcceptanceVersion` no nulos).
