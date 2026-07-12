# Regresión e2e — Inscripción (Patrol) con verificación de BD

**Fecha (UTC):** 2026-07-11T15:00:47Z
**Test:** `integration_test/registration_patrol_test.dart`
**Device:** emulator-5554 (Pixel_9a AVD, flavor dev)
**Comando:**
```
patrol test -t integration_test/registration_patrol_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --dart-define=TEST_EMAIL=qa1@gmail.com --dart-define=TEST_PASSWORD=Test123.
```

## Resultado Patrol: FAIL (con matiz)

Los primeros dos intentos fallaron por inestabilidad del emulador (instrumentation process
crashed / colgado en `isPermissionDialogVisible`, ambos con logs de Play Store/Finsky/AiAiEcho
consumiendo recursos — ruido de entorno, no del app). Al tercer intento el wizard de inscripción
completó **todos sus pasos exitosamente**:

- Contacto de emergencia -> Siguiente (ok)
- Selección de vehículo (ok)
- Confirmar Inscripción (ok)
- Aceptar consentimiento médico/riesgo ("Entiendo, inscribirme") (ok)
- Aparece el texto "Tu solicitud está siendo revisada por el organizador." (ok, éxito visible en UI)

Inmediatamente después de ese último paso exitoso, el test global fue marcado `FAILED` por Gradle/UTP
debido a una excepción NO relacionada con el flujo de inscripción, capturada por el framework de
Flutter test:

```
PlatformException(Throwable, java.lang.Throwable: Source 'rg-route-source' is not in style, ...)
  at com.mapbox.maps.mapbox_maps.StyleController.setStyleSourceProperties(StyleController.kt:424)
  ...
  at StyleManager.setStyleSourceProperties (package:mapbox_maps_flutter/src/pigeons/map_interfaces.dart:7969:7)
```

Esto ocurre en un widget de mapa (Mapbox) que intenta actualizar una fuente de ruta (`rg-route-source`)
en un estilo que ya no está cargado/disponible (probablemente un rebuild/dispose tardío tras la
navegación de vuelta desde el wizard). No guarda relación aparente con `eliminacion-cuenta-phase-03`
(bloqueo de organizador / anonimización); es un problema de timing de Mapbox que hace que el test
termine en estado FAILED aunque el flujo de negocio bajo prueba (inscripción + consentimientos) sí
se ejecutó y persistió correctamente (ver verificación de BD abajo).

## Verificación de BD (hecha igualmente, pese al FAIL de Patrol, para diagnosticar)

```sql
SELECT "medicalConsentVersion", "riskAcceptanceVersion", status
FROM "EventRegistration" er JOIN "Event" e ON er."eventId"=e.id
WHERE e.name='Mi Evento' AND er.email='qa1@gmail.com';
```
Resultado: `medicalConsentVersion=v0.1-2026-06`, `riskAcceptanceVersion=v0.1-2026-06`, `status=PENDING`.
Ambas columnas de consentimiento NO nulas -> la inscripción y sus consentimientos SÍ persistieron
correctamente en el backend.

## Limpieza

Se ejecutó el DELETE de datos de prueba (inscripción PENDING de qa1@gmail.com en "Mi Evento") antes
y después de la corrida. Estado final: BD limpia, sin inscripción de prueba pendiente.

## Recomendación

- No es una regresión de `eliminacion-cuenta-phase-03`; el flujo de negocio bajo prueba (inscripción
  + persistencia de consentimientos) funciona correctamente.
- Hay un bug real, separado, digno de investigar por el humano: excepción no capturada de Mapbox
  (`Source 'rg-route-source' is not in style`) que hace fallar el test Patrol de inscripción incluso
  cuando el flujo de negocio es exitoso. Sugerido para `rg-exec` (lite) en un fix futuro relacionado
  con el ciclo de vida del mapa de tracking/ruta, no con esta fase.
