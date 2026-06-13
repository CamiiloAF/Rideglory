# Fase 3 — Evidencia de validación prod-like

**Estado:** PENDIENTE — este archivo debe completarse con evidencia real ANTES de ejecutar el retiro de Crashlytics.

**Bloqueante para:** eliminación de `firebase_crash_reporter.dart`, `firebase_crashlytics` en `pubspec.yaml`, plugins Gradle/Xcode.

**Referencia:** criterio 12 del PRD, guardrail G1.

---

## Evidencias requeridas

Para autorizar el retiro de Crashlytics, este archivo debe incluir capturas o logs que demuestren los siguientes tres puntos con la integración Sentry activa en un entorno prod-like (build release con `config/prod.json` o `kSentryDevVerify=true` en debug):

### E1 — Crash no-fatal con stack simbolizado

- Disparar un crash no-fatal desde la app (e.g., llamar `getIt<CrashReporter>().recordError(Exception('test'), StackTrace.current, reason: 'qa-validation')`)
- Captura del evento en el dashboard de Sentry con:
  - Stack trace legible (símbolos resueltos, no ofuscados)
  - `environment` correcto (`prod` o `dev` según el flavor usado)
  - Sin campos PII expuestos (sin `authorization`, `password`, `email`, `placa`, `vin`)

**Evidencia:**
```
[ PENDIENTE — adjuntar captura de pantalla o URL del evento en Sentry ]
```

### E2 — Error 5xx con traceId correlacionado al backend

- Disparar un request que resulte en un 500 del backend (puede ser forzado via herramienta de testing)
- Captura del evento Sentry con:
  - `traceId` / `sentry-trace` visible en el evento
  - El mismo `traceId` visible en los logs del backend (gateway) correspondientes a ese request
  - Level `error` (no `warning` ni `info`)

**Evidencia:**
```
[ PENDIENTE — adjuntar captura del evento Sentry + log correspondiente del gateway ]
traceId: <valor>
```

### E3 — Error 4xx de negocio NO genera evento Sentry

- Disparar un request que resulte en un 400/401/404 (e.g., login fallido, recurso no encontrado)
- Verificar en el dashboard de Sentry que NO aparece ningún evento correspondiente a ese request
- El comportamiento esperado es que quede solo como breadcrumb (si aplica), no como error event

**Evidencia:**
```
[ PENDIENTE — adjuntar captura mostrando ausencia del evento en Sentry ]
```

---

## Checklist de autorización

- [ ] E1 completa (crash no-fatal simbolizado, sin PII)
- [ ] E2 completa (5xx con traceId correlacionado)
- [ ] E3 completa (4xx sin evento Sentry)
- [ ] `dart analyze` en verde con Sentry integrado
- [ ] `flutter test` en verde (incluyendo `sentry_crash_reporter_test.dart` y `pii_denylist_test.dart`)

**Una vez marcadas todas las casillas: el retiro de Crashlytics está autorizado.**

---

## Notas de ejecución

_Completar con fecha, flavor usado, y quién realizó la verificación._

```
Fecha: 
Flavor: 
Verificado por: 
Notas:
```
