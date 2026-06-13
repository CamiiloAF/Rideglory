# 05 — Síntesis final (Product Owner) — observability-sentry

- **Generado (UTC):** 2026-06-10T22:15:33Z
- **Autor:** Product Owner (consolidación)
- **Insumos:** `02-po-proposal.md`, `03-architect-review.md`, `04-plan-review.md`
- **Repos:** Flutter `/Users/cami/Developer/Personal/Rideglory` + backend `/Users/cami/Developer/Personal/rideglory-api`
- **Veredicto consolidado:** aprobado con los ajustes del Architect y del Plan Reviewer integrados.

## Overview

Reconstrucción de la observabilidad de extremo a extremo de Rideglory (móvil + backend) en **4 fases secuenciales en su núcleo** (1 → 2 → 3) más una **Fase 4 incremental** mayormente independiente. Casi no hay UI nueva: el único punto de contacto visible es el tile de opt-out de analytics que **ya existe**. El objetivo transversal es: poder seguir un request por su `traceId` desde Flutter → gateway → microservicios, ver crashes y errores 5xx correlacionados en Sentry **solo en prod**, retirar Crashlytics sin ventana sin cobertura, y nunca filtrar PII ni secretos.

La decisión arquitectónica de mayor peso ya está cerrada: el `traceId` viaja por TCP mediante un **Serializer/Deserializer custom del `ClientProxy` + `nestjs-cls` (AsyncLocalStorage)**, NO envolviendo cada payload en `{data, meta}`. Esto deja en **cero los cambios a `@rideglory/contracts` y a los ~56 message patterns**, y baja el riesgo R1 de Alta a Media.

Regla de oro en todas las fases: **dev → consola, prod → Sentry; jamás PII ni secretos**.

## Cambios aplicados

Integrados desde el Architect (`03`) y el Plan Reviewer (`04`):

**Fase 1 (backend traceId + logs):**
- Propagación del `traceId` por **Serializer/Deserializer custom del `ClientProxy` + `nestjs-cls`**, sin tocar payloads, DTOs ni los ~56 message patterns.
- Envelope `_meta` diseñado como **mapa extensible** (no solo el string `traceId`), porque la Fase 2 reusará ese canal para `sentry-trace`/`baggage`.
- Redacción PII en **dos capas**: `redact` nativo de pino por path + interceptor request/response con allowlist. Denylist: Authorization, ID token, password, email, teléfono, SOAT, placa, VIN.
- Devolver el `traceId` al cliente por header `x-trace-id` además del cuerpo de error.
- Reencuadre: el núcleo de esfuerzo/riesgo es el `traceId` distribuido por TCP, no pino. El shape del envelope lo fija el Architect antes de ejecutar; sub-entregas opcionales si el alcance crece.

**Fase 2 (backend Sentry):**
- **Proyecto Sentry de backend independiente** (`rideglory-backend`, separado de `rideglory-flutter`), con los 6 MS distinguidos por tag `service` (no un proyecto por MS). **Revisado 2026-06-12** (antes era "un solo proyecto compartido app+backend"): la cuota de errores es a nivel de organización, así que separar no la multiplica, pero separar da triage/alertas/release-health limpios por plataforma; el trazado distribuido sigue funcionando entre proyectos de la misma org.
- `SENTRY_DSN` opcional en joi + gating por `NODE_ENV==='production'` para no romper dev local.
- Extender los filtros existentes (`RpcCustomExceptionFilter`, `RpcAllExceptionsFilter`): ≥500 → `captureException` (*error event* con alerta); 4xx → `Sentry.logger.warn` (structured log con `traceId`/`service`, `enableLogs: true`) — contexto sin alerta, usa cuota de logs (5 GB) no la de errores (5k). Los 4xx también siguen en pino. **Decisión del usuario.**
- Abstraer en `rideglory-common-lib` la tríada serializer/deserializer/cls + bootstrap Sentry (`instrument.ts` + `SentryModule` + joi), registrada ×6, como **criterio de aceptación** (evita divergencia). Recordar rebuild + reinstalar la lib en cada MS.

**Fase 3 (Flutter Sentry):**
- **Orden interno explícito anti-ventana:** (a) deps + `SentryCrashReporter` + `SentryFlutter.init` gated → (b) validar reporte en prod-like → (c) `dio.addSentry()` + `tracePropagationTargets` → (d) recién entonces retirar Crashlytics (pubspec, `firebase_module.dart`, nativo iOS/Android). Reemplazar `crashlytics.setCustomKey('api_base_url')` por tag/scope de Sentry.
- Documentar la decisión de **doble reporte** (handlers globales ↔ `runZonedGuarded` ↔ integración Sentry) con test de gating debug/prod (Sentry no inicializa en debug/test; `NoOpCrashReporter` activo).
- Añadir a CI el **upload de dSYM (iOS) y mapping ProGuard (Android)** como subtarea explícita (DevOps).

**Fase 4 (insights):**
- Respetar el switch unificado (`AppSwitchTile`) y texto oscuro sobre primario en el tile opt-out existente.
- Instrumentar taps en `AppButton`/`AppTextButton`/Cubits sin GestureDetectors extra ni helpers que retornen widgets; sin pantallas nuevas; catálogo de eventos como doc markdown.

**Transversal:**
- Centralizar la **denylist PII** en una sola fuente compartida en Flutter y en backend, con test que falle si un campo aparece sin redactar.
- El `traceId` que vuelve al cliente **nunca** aparece como copy visible; los mensajes de error siguen en español desde `rest_client_functions.dart`; el `traceId` es metadato técnico (tag/breadcrumb Sentry).
- WebSocket `/tracking/ws`: tracing best-effort fuera del alcance core; documentar la limitación, no bloquear.
- **Sin reordenar fases:** la dependencia dura 1 → 2 → 3 se mantiene; la Fase 4 es incremental (ver nota de dependencia abajo).

### Estado de las decisiones del Architect (reconciliación)

De las 5 decisiones originalmente delegadas al Architect, **2 ya quedan cerradas por este plan**:

1. **Shape de propagación del `traceId` por TCP** → CERRADA: serializer/deserializer custom + `nestjs-cls`, envelope `_meta` extensible, sin tocar contracts.
2. **Proyecto-Sentry-por-servicio vs. tag `service`** → CERRADA: un solo proyecto con tag `service`.

Quedan **3 decisiones por cerrar como gate previo** a la ejecución de la fase que las consume (no son 5 abiertas):

3. **Sampling** (`tracesSampleRate` por env) → cerrar antes de Fase 2.
4. **Gestión de DSN por flavor / CI** (backend `.env`/secret manager; Flutter `config/<flavor>.json`/`--dart-define`; upload de símbolos) → cerrar antes de Fase 2 (backend) y Fase 3 (Flutter).
5. **Allowlist/denylist exacta de PII** (fuente compartida + test) → cerrar antes de Fase 1.

## Lista final de fases

| id | Título | dependsOn | Nivel | Por qué (tier) |
|----|--------|-----------|-------|----------------|
| 1 | Backend: traceId distribuido por TCP + logs estructurados sin PII | — | **full** | Cross-cutting sobre los 6 servicios, redacción PII central (Authorization, ID token, email, teléfono, SOAT, placa, VIN), nueva superficie compartida en `rideglory-common-lib` y alto blast radius si el envelope `_meta` se diseña mal. Aunque el serializer custom evita tocar contratos, es infraestructura fundacional difícil de revertir y prerrequisito de 2–3. |
| 2 | Backend: errores 5xx en Sentry con traza distribuida | 1 | **full** | Toca el manejo global de errores de los 6 servicios (extiende `RpcCustomExceptionFilter`/`RpcAllExceptionsFilter`), filtrado PII en `beforeSend`, abstracción ×6 en `rideglory-common-lib` como criterio de aceptación y gating prod. Cross-cutting + seguridad/PII + alto blast radius. |
| 3 | Flutter: Sentry reemplaza Crashlytics, enlazado al backend | 2 | **full** | Cambios nativos iOS/Android (Podfile, `project.pbxproj`, Gradle) difíciles de revertir, retiro de crash reporting con riesgo de ventana sin cobertura, denylist PII central, doble reporte con `runZonedGuarded`, DSN por flavor y upload de símbolos en CI. Alto roce de build + seguridad. |
| 4 | Insights de producto: taps, `screen_view` y catálogo documentado | — (ver nota) | **lite** | Expansión incremental sobre base existente (~61 eventos, opt-out, route observer): añadir call sites de taps, taxonomía de baja cardinalidad, drop-off por step y un doc markdown. Una sola área (analytics Flutter), sin contratos, sin migraciones, reversible, sin PII nueva, reusa el tile opt-out existente. |

### Detalle de fases

**Fase 1 — Backend: traceId distribuido por TCP + logs estructurados sin PII**
Goal: operación/soporte pueden seguir un request por su `traceId` desde el gateway hasta cada microservicio, con logs estructurados y sin PII.
Resumen: reemplazar `HttpLoggerMiddleware` por `nestjs-pino` (`pino-pretty` dev, JSON prod). `nestjs-cls` en el gateway genera/continúa el `traceId` (a partir de `x-request-id`/`sentry-trace` entrante si llega) y lo guarda en CLS. Serializer custom del `ClientProxy` inyecta el `traceId` en el envelope TCP `_meta` (mapa extensible) sin tocar `.send()` ni DTOs; Deserializer + interceptor en cada MS lo siembra en su CLS para que pino lo emita por línea. Interceptor request/response con método, ruta, status, latencia y `traceId`; redacción en dos capas (pino `redact` por path + allowlist). Devolver `traceId` por header `x-trace-id`. Sin Sentry aún.

**Fase 2 — Backend: errores 5xx en Sentry con traza distribuida**
Goal: el equipo ve crashes y errores 5xx del backend en Sentry como *error events* (alerta), correlacionados por `traceId` y tag `service`; los 4xx aparecen como structured logs (contexto sin alerta).
Resumen: `instrument.ts` (import en primera línea de cada `main.ts`) + `SentryModule.forRoot()` gated por `NODE_ENV==='production'`; en los filtros existentes ≥500 → `captureException` y 4xx → `Sentry.logger.warn` (structured log con `traceId`/`service`, `enableLogs: true`); los 4xx también siguen en pino. Reusar el envelope `_meta` para transportar `sentry-trace`/`baggage` y cerrar el trace HTTP↔TCP. Un solo proyecto Sentry con tag `service`. `NODE_ENV` + `SENTRY_DSN` (opcional) en los 6 joi. Abstraer la tríada serializer/deserializer/cls + bootstrap Sentry en `rideglory-common-lib` (criterio de aceptación), con rebuild + reinstalación disciplinada ×6.

**Fase 3 — Flutter: Sentry reemplaza Crashlytics, enlazado al backend**
Goal: crashes y errores de red de la app llegan a Sentry (solo prod), enlazados a la traza del backend, sin doble reporte ni fuga de PII y sin ventana sin cobertura.
Resumen: orden estricto — (a) `sentry_flutter`+`sentry_dio`, `SentryCrashReporter implements CrashReporter` (`@Injectable(as: CrashReporter)`, `NoOpCrashReporter` en debug/test), `SentryFlutter.init` gated (DSN vacío dev, `beforeSend→null` debug, `environment` por flavor); (b) validar reporte en prod-like; (c) `dio.addSentry()` al final de `AppDio` con `tracePropagationTargets` restringido a la API; (d) retirar Crashlytics (pubspec, `firebase_module.dart`, nativo iOS/Android), reemplazando `setCustomKey('api_base_url')` por tag/scope Sentry. Mapear `network_error_classifier.dart` a `level`/`fingerprint`/filtrado (no reportar 4xx de negocio). Documentar la decisión de doble reporte con test de gating. CI: upload de dSYM + ProGuard (DevOps).

**Fase 4 — Insights de producto: taps, `screen_view` y catálogo documentado**
Goal: producto entiende mejor el comportamiento real (taps clave, `screen_view` consistente, drop-off por step) con un catálogo de eventos documentado.
Resumen: expandir lo instrumentado añadiendo taps en `AppButton`/`AppTextButton`/Cubits (sin GestureDetectors ni helpers que retornen widgets), `screen_view` consistente combinando `SentryNavigatorObserver` + GA4, eventos de drop-off faltantes por step (creación de evento, registro, auth), catálogo hardcoded de baja cardinalidad sin PII, doc markdown del catálogo. Respetar `AppSwitchTile` y texto oscuro sobre primario en el opt-out existente. Sin pantallas nuevas. PostHog fuera de alcance.

### Nota de dependencia de la Fase 4 (resolución de la dependencia blanda sobre Fase 3)

La Fase 4 figura con `dependsOn: []` porque la mayor parte de su valor (taps GA4, `screen_view` vía el `AnalyticsRouteObserver` existente, eventos de drop-off y el catálogo markdown) **es paralelizable y no requiere Sentry**. La **única subtarea acoplada** es el cableado de `SentryNavigatorObserver`: ese observer **solo funciona si la Fase 3 ya entregó `SentryFlutter.init`**. Regla operativa para quien ejecute la Fase 4 en paralelo: implementar la parte GA4 sin bloqueo, pero **cablear `SentryNavigatorObserver` únicamente después de que la Fase 3 esté completa**; si la Fase 3 aún no entregó la init, dejar esa subtarea pendiente en lugar de añadir un observer que no reportará nada.

## Supuestos y riesgos

### Supuestos
- Las interfaces `CrashReporter` y `AnalyticsService` ya existen y son Dart puro → la migración Flutter es de implementación + init + deps + retiro de Crashlytics, de bajo riesgo arquitectónico.
- Los DSN de prod y `NODE_ENV` se inyectan por configuración existente (`config/<flavor>.json` / `--dart-define` en Flutter; `.env`/secret manager en backend); no se exponen en el repo.
- La app aún no tiene usuarios reales → se puede retirar Crashlytics de forma agresiva siempre que los tests pasen y no quede ventana sin reporte de crashes.
- No se requiere histórico de Crashlytics; se acepta empezar limpio en Sentry.
- Cuota free de Sentry (5k errores/mes) es suficiente con filtrado de 4xx de negocio + sampling configurable.
- La tríada serializer/deserializer/cls vive en `rideglory-common-lib`; aplica el gotcha de rebuild (`npm run build` + reinstalar en cada MS).

### Riesgos (heredados del Architect, severidad ya mitigada)
- **R1 — Propagación TCP del traceId (Alta→Media):** mitigado por serializer/deserializer custom + CLS (no toca payloads ni DTOs); probar un MS extremo a extremo antes de replicar ×6.
- **R2 — Doble reporte de crashes en Flutter (Media):** Sentry instala sus hooks y `crash_handler_setup` delega sin re-enganchar; test de gating que cuente reportes.
- **R3 — Fuga de PII/secretos (Alta):** `redact` de pino + interceptor con allowlist + `beforeSend`/`beforeBreadcrumb`; denylist centralizada con test, revisada antes de prod.
- **R4 — Ventana sin reporte de crashes (Media):** secuencia estricta integrar+validar Sentry → recién entonces retirar Crashlytics.
- **R5 — Divergencia ×6 del patrón (Media):** abstraer en `rideglory-common-lib` como criterio de aceptación; rebuild + reinstalar disciplinado.
- **R6 — Cuota free Sentry (Media):** 4xx como structured logs (cuota de logs 5 GB, no la de 5k errores), `tracesSampleRate` por env, un solo proyecto con tag `service`.
- **R7 — Orden de import de `instrument.ts` (Baja):** `import './instrument'` como primera línea de cada `main.ts`; verificar con error de prueba.
- **R8 — Tracing HTTP↔TCP no automático (Media):** transportar `sentry-trace`/`baggage` en el envelope `_meta` extensible desde Fase 1.
- **R9 — Símbolos ilegibles en prod (Baja):** upload de dSYM/ProGuard en CI (DevOps).
- **R10 — WS no correlacionado (Baja):** declarado best-effort/fuera de alcance core; documentar.

### Gate de decisiones previo a ejecución
Antes de abrir cada `rg-exec`, cerrar la decisión que aplica a esa fase (recordatorio: solo quedan 3 abiertas, no 5):
- **Fase 1:** allowlist/denylist exacta de PII (fuente compartida + test).
- **Fase 2:** sampling (`tracesSampleRate`) y gestión de DSN backend (secret manager / `.env`).
- **Fase 3:** gestión de DSN por flavor + upload de símbolos en CI.
