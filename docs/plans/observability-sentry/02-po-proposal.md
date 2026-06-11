# 02 — PO Proposal — observability-sentry

- **Generado (UTC):** 2026-06-10T22:08:24Z
- **Autor:** Product Owner
- **Insumos:** `00-intake.md`, `01-scan.md`
- **Repos:** Flutter `/Users/cami/Developer/Personal/Rideglory` + backend `/Users/cami/Developer/Personal/rideglory-api`

## Resumen

Reconstrucción de la observabilidad de extremo a extremo. Aunque casi no hay UI nueva, cada fase entrega
una capacidad operable y deja **ambas apps funcionando** (sin perder reporte de crashes ni romper requests).
El orden respeta la única dependencia dura: el `traceId` end-to-end (Fase 1) es prerrequisito del tracing
distribuido en Sentry (Fases 2 y 3). Regla de oro transversal en todas las fases: **dev → consola,
prod → Sentry; jamás PII ni secretos**.

## Fases propuestas

| id | title | goal | summary |
|----|-------|------|---------|
| 1 | Backend: logs legibles + traceId de punta a punta | Operación y soporte pueden seguir un request por su `traceId` desde el gateway hasta cada microservicio con logs estructurados y sin PII. | Reemplazar `HttpLoggerMiddleware` por `nestjs-pino` (`pino-pretty` en dev, JSON en prod) encapsulando el `Logger` de Nest. Generar `traceId`/`correlationId` en el gateway (o continuarlo si llega), devolverlo al cliente por header, y propagarlo a los 5 MS por el payload de los message patterns TCP (decisión de shape `{data, meta:{traceId}}` la fija el Architect, coordinando `@rideglory/contracts`). Interceptor de request/response con método, ruta, status, latencia y `traceId`; redacción por denylist (Authorization, ID token, password, email, teléfono, SOAT, placa, VIN) + allowlist. Sin Sentry todavía: deja la base de correlación lista. |
| 2 | Backend: errores en Sentry con traza distribuida | El equipo ve crashes y errores 5xx del backend en Sentry, correlacionados por `traceId` y `service`, sin ruido de 4xx de negocio. | `instrument.ts` + `SentryModule.forRoot()` por servicio (6) gated por `NODE_ENV==='production'`; integrar `@SentryExceptionCaptured()`/`SentryGlobalFilter` en los filtros existentes (`RpcCustomExceptionFilter`, `RpcAllExceptionsFilter`). Añadir `NODE_ENV` y `SENTRY_DSN` al joi de los 6 `config/envs.ts`. Loguear también 4xx (hoy solo ≥500) y devolver `traceId` al cliente en el cuerpo de error. El gateway continúa el `sentry-trace` que llega de Flutter y lo propaga. Patrón replicable ×6 (candidato a abstracción en `rideglory-common-lib`); decisión proyecto-por-servicio vs. tag `service` la fija el Architect. |
| 3 | Flutter: Sentry reemplaza Crashlytics, conectado al backend | Los crashes y errores de red de la app móvil llegan a Sentry (solo en prod), enlazados a la traza del backend, sin doble reporte ni fuga de PII. | Añadir `sentry_flutter` + `sentry_dio`; nueva impl `SentryCrashReporter` reusando la interface `CrashReporter`; `SentryFlutter.init` en `main.dart` con DSN vacío en dev, `environment` por flavor, `beforeSend→null` en dev, revisando el doble reporte con `crash_handler_setup.dart` + `runZonedGuarded`. `dio.addSentry()` al final de `AppDio` con `tracePropagationTargets` restringido a la API Rideglory para cerrar el trace móvil→backend. Mapear la matriz G5 (`network_error_classifier.dart`) a `level`/`fingerprint`/filtrado (no reportar 4xx de negocio) + breadcrumbs en auth/submit. Retirar por completo `firebase_crashlytics` (pubspec, `firebase_module.dart`, piezas nativas iOS/Android) sin dejar ventana sin reporte de crashes. |
| 4 | Insights de producto: embudos y taps con eventos documentados | Producto entiende mejor el comportamiento real (taps clave, `screen_view` consistente, drop-off por step) con un catálogo de eventos documentado. | Expandir lo ya instrumentado (~61 eventos, opt-out, route observer): añadir taps de botones clave, `screen_view` consistente combinando `SentryNavigatorObserver` + GA4, eventos de drop-off faltantes por step en los embudos (creación de evento, registro, auth) y features más usadas. No-PII, cardinalidad baja con catálogo hardcoded. Entregar documentación de eventos. PostHog fuera de alcance. Fase incremental, no fundacional. |

## Supuestos

- Las decisiones arquitectónicas abiertas del intake (shape del payload TCP para `traceId`, proyecto-Sentry-por-servicio vs. tag `service`, sampling, gestión de DSN por flavor/CI, allowlist/denylist exacta) las resuelve el **Architect** en el paso siguiente; la planeación PO no las prejuzga.
- Las interfaces `CrashReporter` y `AnalyticsService` ya existen y son Dart puro, por lo que la migración Flutter es de implementación + init + deps + retiro de Crashlytics, de bajo riesgo arquitectónico.
- Los DSN de prod y `NODE_ENV` se inyectan por configuración existente (`config/<flavor>.json` / `--dart-define` en Flutter; `.env`/secret manager en backend); no se exponen en el repo.
- El cambio de shape de los message patterns TCP se coordina con `@rideglory/contracts` (gotcha de rebuild en memoria: `npm run build` + reinstalar en cada MS).
- La app aún no tiene usuarios reales, así que se puede retirar Crashlytics de forma agresiva siempre que los tests pasen y no quede ventana sin reporte de crashes.
- No se requiere histórico de Crashlytics; se acepta empezar limpio en Sentry (a confirmar con el usuario).
- Cuota free de Sentry (5k errores/mes) es suficiente con filtrado de 4xx de negocio + sampling; si no, se ajusta con `beforeSend`/rate-limiting (decisión del Architect).

## Riesgos

- **Propagación TCP del `traceId` (mayor riesgo):** tocar el shape de todos los message patterns puede romper contratos entre gateway y MS si la migración no es atómica y coordinada con `@rideglory/contracts`. Mitigar con shape envolvente retrocompatible y rebuild disciplinado de contracts.
- **Doble reporte de crashes en Flutter:** la coexistencia de `SentryFlutter.init`, `crash_handler_setup.dart` y `runZonedGuarded` puede duplicar eventos. Mitigar revisando los handlers al integrar y testeando el gating debug/prod.
- **Fuga de PII/secretos en logs o eventos Sentry:** denylist incompleta podría filtrar Authorization, email, teléfono, placa, VIN, SOAT. Mitigar con redacción por denylist + allowlist y revisión explícita antes de habilitar prod.
- **Ventana sin reporte de crashes durante la migración Crashlytics→Sentry:** retirar Crashlytics antes de validar Sentry dejaría la app sin cobertura. Mitigar integrando Sentry y validándolo antes de remover las piezas nativas.
- **Replicación ×6 del patrón Sentry backend:** divergencia entre servicios si se copia-pega en lugar de abstraer. Mitigar con utilidad compartida en `rideglory-common-lib`.
- **Consumo de cuota Sentry:** sin filtrado/sampling adecuado, 4xx ruidosos o trazas agotarían la cuota free. Mitigar con filtrado de 4xx de negocio y sampling configurable.
- **Cardinalidad de eventos de analytics:** parámetros de alta cardinalidad inflarían GA4 y dificultarían el análisis. Mitigar con catálogo hardcoded de baja cardinalidad.

## Criterios de éxito globales

- Un request se puede seguir por su `traceId` desde Flutter → gateway → MS, visible en logs y como tag/traza en Sentry.
- En prod, crashes y errores 5xx de backend y de la app móvil llegan a Sentry correlacionados; en dev todo va a consola y nada a Sentry.
- Los 4xx de negocio no generan ruido en Sentry; los logs sí registran 4xx con su `traceId`.
- Ningún log ni evento Sentry contiene PII ni secretos (denylist verificada).
- Crashlytics queda totalmente retirado (pubspec, DI, nativo) sin ventana sin reporte de crashes; la interface `CrashReporter` sigue siendo el único punto de acoplamiento.
- Firebase Analytics cubre embudos clave con taps, `screen_view` consistente y drop-off por step, con catálogo de eventos documentado.
- `dart analyze` limpio y `flutter test` en verde; backend con build y tests existentes pasando tras cada fase.
- Cada fase deja ambas apps funcionales y desplegables.
