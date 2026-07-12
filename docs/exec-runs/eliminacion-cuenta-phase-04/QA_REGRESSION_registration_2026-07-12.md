# QA Regresión e2e — Inscripción (con verificación de BD)

Fase: eliminacion-cuenta-phase-04
Fecha (UTC): 2026-07-12T03:13:00Z
Test: `integration_test/registration_patrol_test.dart`
Device: `emulator-5554` (Android)
Usuario: qa1@gmail.com (rider) inscribiéndose a "Mi Evento" (owner qa2@gmail.com)

## Resultado

- **result: pass**
- **dbVerification.result: pass**

## Comando ejecutado

```
patrol test -t integration_test/registration_patrol_test.dart -d emulator-5554 \
  --flavor dev --dart-define-from-file=config/dev.json \
  --dart-define=TEST_EMAIL=qa1@gmail.com --dart-define=TEST_PASSWORD=Test123.
```

No había `TEST_EMAIL`/`TEST_PASSWORD` en el entorno (`printenv`), así que se usaron las
credenciales fijas indicadas en el prompt.

## Pasos

1. Confirmado que `integration_test/registration_patrol_test.dart` existe.
2. Pre-limpieza: `DELETE` de inscripciones `PENDING` de qa1@gmail.com en "Mi Evento" antes de
   correr el test → 0 filas afectadas (ya estaba limpio), confirmado con `SELECT` (0 rows).
3. Patrol test corrido contra `emulator-5554`: **34/34 pasos OK**, wizard completo (Personal →
   Médico con consentimiento Ley 1581 "Autorizar" → Emergencia → Vehículo), confirmación y sheet
   de waiver de riesgos ("Entiendo, inscribirme"), SnackBar de éxito
   ("Tu solicitud está siendo revisada por el organizador."). Duración: 2m 12s.
   Reporte HTML: `build/app/reports/androidTests/connected/debug/flavors/dev/index.html`.
4. Interpretación: **pass** (sin fallas de aserción/flujo).
5. Verificación de BD (events-ms, tabla `EventRegistration` JOIN `Event`, filtro
   `name='Mi Evento' AND email='qa1@gmail.com' AND status='PENDING'`):

   ```
   medicalConsentVersion | riskAcceptanceVersion | status
   -----------------------+-----------------------+---------
   v0.1-2026-06          | v0.1-2026-06          | PENDING
   ```

   Ambas columnas de consentimiento NO nulas → **dbVerification: pass**. El backend persistió
   correctamente el consentimiento médico y la aceptación de riesgo, no solo la UI mostró éxito.
6. Limpieza final: mismo `DELETE` de la inscripción `PENDING` de qa1@gmail.com en "Mi Evento" →
   `DELETE 1`, confirmado con `SELECT count(*) = 0`. BD queda idempotente para la próxima corrida.
   No se tocó ninguna inscripción de qa2 (owner) ni de otros usuarios.

## Notas

- No se modificó código de producción (`lib/`, `src/`) ni se hicieron commits.
- El working tree del repo Flutter tenía cambios preexistentes de otras fases/agentes en curso
  (no generados por esta corrida); no se tocaron.
- No se generaron ni editaron archivos de test; solo se ejecutó el Patrol test ya existente y se
  hicieron operaciones de datos de prueba (DELETE) vía psql, dentro de la excepción autorizada
  para esta fase.
