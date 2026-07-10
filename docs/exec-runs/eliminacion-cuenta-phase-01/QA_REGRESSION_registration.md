# QA Regresión e2e — Inscripción (registration_patrol_test.dart)

Run: eliminacion-cuenta-phase-01
Timestamp (UTC): 2026-07-10T17:23:44Z

## Resultado

- Patrol: **PASS** (35/35 pasos, duración 3m 1s)
- Verificación BD: **PASS**

## Comando ejecutado

```
patrol test -t integration_test/registration_patrol_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --dart-define=TEST_EMAIL=qa1@gmail.com --dart-define=TEST_PASSWORD=Test123.
```

## Pasos

1. Pre-limpieza: `DELETE FROM "EventRegistration" ... WHERE email='qa1@gmail.com' AND status='PENDING'` → 0 filas borradas (no había inscripción previa).
2. Patrol ejecutado en emulator-5554. Flujo completo: login → tab Eventos → "Mi Evento" → detalle → "Inscribirme" → wizard (Personal → Médico [consentimiento Ley 1581 "Autorizar"] → Emergencia → Vehículo) → "Confirmar Inscripción" → waiver "Entiendo, inscribirme" → mensaje de éxito "Tu solicitud está siendo revisada por el organizador." Todos los 35 pasos en verde.
3. Verificación BD (post-run, antes de limpieza final):
   ```sql
   SELECT "medicalConsentVersion", "riskAcceptanceVersion"
   FROM "EventRegistration" er JOIN "Event" e ON er."eventId"=e.id
   WHERE e.name='Mi Evento' AND er.email='qa1@gmail.com' AND er.status='PENDING';
   ```
   Resultado: `medicalConsentVersion=v0.1-2026-06`, `riskAcceptanceVersion=v0.1-2026-06` (ambas NO nulas). El backend persistió correctamente el consentimiento y la aceptación de riesgo mostrados por la UI.
4. Limpieza final: mismo DELETE del paso 1 → 1 fila borrada (la creada en este run). Confirmado count=0 tras limpieza.

## Conclusión

Sin regresión. El flujo de inscripción end-to-end funciona correctamente y los datos de consentimiento/waiver se persisten en la base de datos del events-ms tal como los muestra la UI. No se detectaron gaps de cobertura ni fallas críticas en este test puntual.

Working tree: sin cambios de código realizados por este run (solo lectura/limpieza de BD y este reporte, bajo docs/exec-runs/).
