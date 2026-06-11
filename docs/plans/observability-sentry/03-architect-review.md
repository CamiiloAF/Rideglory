# 03 — Architect Review — observability-sentry

- **Generado (UTC):** 2026-06-10T22:09:58Z
- **Autor:** Architect
- **Insumos:** `00-intake.md`, `01-scan.md`, `02-po-proposal.md`, inspección directa de `rideglory-api`
- **Veredicto:** `ok_con_ajustes`
- **Repos:** Flutter `/Users/cami/Developer/Personal/Rideglory` + backend `/Users/cami/Developer/Personal/rideglory-api`

## Resumen del juicio

Las 4 fases son técnicamente viables sobre el stack existente y mapean limpio al gap. **No se replantea ninguna fase.** El orden es correcto: la Fase 1 (traceId end-to-end) es prerrequisito duro de la correlación distribuida en Fases 2–3. El mayor punto de diseño —y donde el PO delegó explícitamente la decisión— es **cómo propagar el traceId por TCP sin romper contratos**. La inspección del backend confirma que existe un camino que evita por completo tocar los ~56 message patterns y los DTOs de `@rideglory/contracts`: un **Serializer/Deserializer custom en el `ClientProxy`** alimentado por **AsyncLocalStorage (nestjs-cls)**. Esto degrada el "mayor riesgo" del plan de alto a medio y es la decisión arquitectónica que fija este documento.

## Validacion por fase

### Fase 1 — Backend: logs legibles + traceId de punta a punta — **viable, complejidad media-alta**

**Por qué media-alta:** greenfield total de correlación (grep confirmó cero `traceId`/`x-request-id`/`sentry-trace` en `src`), toca los 6 servicios y coordina con `@rideglory/contracts`. Lo que la baja de "alta" a "media-alta" es que el camino correcto **no** modifica contratos.

**Decisión arquitectónica (resuelve Pregunta abierta #4 del intake):**
- **NO** envolver el payload de cada `.send(pattern, payload)` en `{data, meta:{traceId}}`. Esto tocaría las ~56 llamadas del gateway (`home.controller.ts`, `maintenances.controller.ts`, etc.), todos los `@MessagePattern` handlers de los 5 MS y los DTOs de contracts → invasivo, error-prone y dispara el gotcha de rebuild de contracts ×N.
- **SÍ** usar el punto de extensión nativo de NestJS microservices:
  1. `nestjs-cls` (AsyncLocalStorage) en el gateway: un middleware/interceptor genera el `traceId` (o continúa el `x-request-id`/`sentry-trace` entrante) y lo guarda en el contexto de la request.
  2. **Custom `Serializer`** en cada `ClientProxy` del gateway: lee el `traceId` del CLS y lo inyecta en el envelope del mensaje TCP (campo reservado, p.ej. `_meta`), **sin tocar ni una sola llamada `.send()` ni un DTO**.
  3. **Custom `Deserializer`** + interceptor en cada MS: extrae `_meta.traceId`, lo siembra en el CLS del MS para que `nestjs-pino` lo emita en cada línea de log.
- Esta tríada (serializer/deserializer/cls-setup) es el candidato natural a vivir en `rideglory-common-lib` y registrarse ×6 — evita copy-paste y divergencia.

**Logging:**
- Reemplazar `HttpLoggerMiddleware` por `nestjs-pino` (`pino-pretty` en dev, JSON en prod). `nestjs-pino` envuelve el `Logger` de Nest, así que los `logger.log/error` existentes en los filtros siguen funcionando y heredan el `traceId` vía `customProps`/CLS.
- `genReqId` del gateway = generar/continuar el `traceId`; queda en cada línea HTTP automáticamente.
- Redacción: usar la opción nativa `redact` de pino (paths) **además** de un interceptor de request/response con allowlist. Denylist confirmada por intake: `Authorization`, ID token, `password`, `email`, teléfono, SOAT, placa, VIN. La redacción de pino opera por path (rápida, declarativa); el interceptor cubre cuerpos.
- Devolver el `traceId` al cliente por header de respuesta (p.ej. `x-trace-id`) desde el gateway (esto habilita que Flutter lo muestre/loguee y enlace soporte).

**Sin Sentry todavía** (correcto): Fase 1 deja la base de correlación lista.

### Fase 2 — Backend: errores en Sentry con traza distribuida — **viable, complejidad media**

**Por qué media:** patrón replicable ×6 con SDK maduro, pero con dos sutilezas reales (tracing TCP y filtrado 4xx) y la coordinación de DSN/joi.

- `instrument.ts` con `Sentry.init(...)` **importado en la primera línea** de cada `main.ts` (requisito del SDK NestJS v8: la instrumentación debe cargar antes que cualquier módulo). Gated por `NODE_ENV==='production'` → DSN vacío/`enabled:false` en dev.
- `SentryModule.forRoot()` por servicio + `SentryGlobalFilter` / `@SentryExceptionCaptured()` integrado en los filtros **existentes** (`RpcCustomExceptionFilter` en gateway, `RpcAllExceptionsFilter` en common-lib). No crear filtros nuevos: extender los actuales.
- **Filtrado 4xx (clave para la cuota free 5k/mes):** capturar solo ≥500 en Sentry; loguear 4xx por pino pero **no** enviarlos. Mapear desde la lógica de status que ya tienen los filtros.
- **Tracing distribuido sobre TCP (sutileza real):** el SDK de Sentry continúa traza por `sentry-trace`/`baggage` **solo en HTTP**. Sobre TCP no es automático. Solución: reusar el **mismo envelope `_meta`** de la Fase 1 para transportar también `sentry-trace`/`baggage` (o derivar el span del `traceId` propio). Esto confirma que el serializer/deserializer de Fase 1 debe diseñarse para llevar un mapa de metadatos extensible, no solo un string.
- **Decisión proyecto-Sentry-por-servicio vs. tag `service` (Pregunta #1):** recomendar **un solo proyecto Sentry con tag `service`** (gateway/users-ms/…). Razón: con cuota free (Pregunta #2) y volumen actual (sin usuarios reales), un proyecto simplifica la correlación por `traceId` cruzando servicios y la gestión de DSN (un solo `SENTRY_DSN`). Reevaluar a proyecto-por-servicio solo si el ruido por servicio lo exige.
- joi: añadir `NODE_ENV` y `SENTRY_DSN` a los 6 `config/envs.ts`. `SENTRY_DSN` opcional (`.optional()`) para no romper dev local.

### Fase 3 — Flutter: Sentry reemplaza Crashlytics — **viable, complejidad media**

**Por qué media (no baja):** las interfaces (`CrashReporter`, `AnalyticsService`) ya existen y son Dart puro, así que el riesgo *arquitectónico* es bajo; pero el riesgo de *build/config/nativo* es real (dSYM/ProGuard, DSN por flavor, doble reporte, retiro nativo de Crashlytics iOS+Android).

- `SentryCrashReporter implements CrashReporter`, registrada `@Injectable(as: CrashReporter)`. Mantener `NoOpCrashReporter` para debug/test. La interface sigue siendo el único punto de acoplamiento (criterio de éxito del PO).
- `SentryFlutter.init` en `main.dart`: convive con `runZonedGuarded` + `crash_handler_setup.dart`. **Riesgo de doble reporte** (FlutterError.onError + PlatformDispatcher.onError + handler de Sentry). Mitigación: dejar que Sentry instale sus handlers y que `registerCrashHandlers` delegue en la interface sin re-enganchar los mismos hooks, o gatear para que solo una cadena reporte. Validar con test de gating debug/prod.
- Gating: DSN vacío en dev → no envía; `beforeSend → null` en debug; `environment` por flavor (`config/<flavor>.json` / `--dart-define`). Coherente con `setEnabled(!kDebugMode)` actual.
- `dio.addSentry()` **al final** de la cadena de interceptors en `AppDio.create` (después de `FirebaseAuthInterceptor`), con `tracePropagationTargets` restringido al host de la API Rideglory → cierra el trace móvil→gateway (el header `sentry-trace` que continúa el gateway en Fase 2).
- Mapear `network_error_classifier.dart` (matriz G5, ya tiene `shouldReport`/`category`/`httpStatus`) a `level`/`fingerprint`/filtrado: no reportar 4xx de negocio ni `FirebaseAuthException` esperadas (denylist ya existe). Breadcrumbs en auth/submit.
- **Retiro de Crashlytics:** secuencia segura = (1) integrar+validar Sentry, (2) recién entonces remover `firebase_crashlytics` de pubspec, `firebase_module.dart` (incluye quitar la dependencia del provider `dio(...)` a `FirebaseCrashlytics` y su `setCustomKey('api_base_url')` → reemplazar por `Sentry.configureScope`/tag), y piezas nativas iOS/Android. Sin usuarios reales → retiro agresivo OK si tests pasan y no queda ventana sin reporte.
- Sentry para Flutter requiere subir **dSYM (iOS)** y **mapping ProGuard (Android)** para símbolos legibles en prod; impacta el pipeline de build/CI (alcance DevOps, no bloqueante para dev).

### Fase 4 — Insights de producto — **viable, complejidad baja-media, incremental**

**Por qué baja-media:** la base ya existe (~61 eventos, opt-out `analytics_consent_cubit`, `analytics_route_observer`). Es expansión, no fundación.

- Añadir taps de botones clave + drop-off por step en los 3 embudos (creación de evento, registro, auth). Reusar `analytics_events.dart`/`analytics_params.dart` con **catálogo hardcoded de baja cardinalidad** (evita inflar GA4).
- `screen_view` consistente combinando `SentryNavigatorObserver` + el `AnalyticsRouteObserver`/GA4 existente. Ambos observers conviven en go_router sin conflicto.
- Entregable de documentación: catálogo de eventos (no-PII). Sugerencia: que viva en `docs/features/` o `docs/analytics/` y se mantenga con la regla de "actualizar docs de feature" en memoria.
- PostHog fuera de alcance (correcto).

## Contratos

| Aspecto | Impacto | Decisión |
|---|---|---|
| **`@rideglory/contracts` (DTOs/patterns)** | **Ninguno si se usa serializer custom.** El traceId viaja en el envelope TCP, fuera de los DTOs de payload. | No modificar contratos para traceId. Evita el gotcha de rebuild ×N. Si por alguna razón se cae al wrapper `{data, meta}`, entonces sí coordinar rebuild (`npm run build` + reinstalar en cada MS). |
| **Message patterns TCP (~56)** | Cero cambios de firma. Serializer/Deserializer operan en el transporte, no en los handlers. | Mantener `@MessagePattern('createEvent', payload)` intactos. |
| **HTTP gateway (cliente Flutter)** | Aditivo: nuevo header de respuesta `x-trace-id`; el cuerpo de error añade `traceId`. Continúa `sentry-trace`/`x-request-id` entrante si llega. | Compatible hacia atrás; Flutter lo consume opcionalmente. |
| **`rideglory-common-lib`** | Nueva superficie compartida: serializer/deserializer/cls-setup + integración Sentry en `RpcAllExceptionsFilter`. Rebuild + reinstalar en los MS que la consumen. | Abstracción intencional (evita divergencia ×6). Mismo gotcha de rebuild que contracts. |
| **Migraciones de datos / Prisma** | **Ninguna.** Observabilidad no toca el esquema de datos. | N/A |
| **Code-gen** | Flutter: tras añadir `sentry_flutter`/`sentry_dio` y nueva impl `@Injectable(as: CrashReporter)` → `dart run build_runner build --delete-conflicting-outputs` para regenerar DI. Sin cambios de DTO/freezed. | Backend NestJS no usa code-gen. |
| **Plataforma (iOS/Android)** | Retiro nativo de Crashlytics (Podfile/Gradle/Info.plist/plugins) + config de upload de símbolos Sentry (dSYM/ProGuard). DSN por flavor vía `config/<flavor>.json`. | Coordinar con la config de flavors dev/prod ya existente. |
| **WebSocket (`/tracking/ws`, `WsAdapter`)** | El tracing HTTP no cubre el canal WS. Los handlers `trackingStartSession`/`trackingUpdateLocation` van por TCP al MS → heredan el traceId del envelope **solo si** la sesión WS siembra un traceId en el CLS por conexión/mensaje. | Tratar el tracing WS como **best-effort fuera del alcance core** de Fases 1–2 (la correlación crítica es HTTP request→MS). Documentar la limitación; no bloquear. |

## Riesgos

| # | Riesgo | Sev | Mitigación |
|---|---|---|---|
| R1 | **Propagación TCP del traceId** rompe contratos si se hace por wrapping de payload. | Alta→**Media** | Adoptar serializer/deserializer custom + CLS (no tocar payloads ni DTOs). Probar un MS extremo a extremo antes de replicar ×6. |
| R2 | **Doble reporte de crashes en Flutter** (FlutterError + PlatformDispatcher + handlers Sentry + runZonedGuarded). | Media | Que Sentry instale sus hooks y `crash_handler_setup` delegue sin re-enganchar; test de gating debug/prod que cuente reportes. |
| R3 | **Fuga de PII/secretos** en logs o eventos Sentry (denylist incompleta). | Alta | `redact` de pino por path + interceptor con allowlist + `beforeSend`/`beforeBreadcrumb` en Sentry; revisión explícita de la denylist (Authorization, ID token, password, email, teléfono, SOAT, placa, VIN) antes de habilitar prod. |
| R4 | **Ventana sin reporte de crashes** durante migración Crashlytics→Sentry. | Media | Secuencia estricta: integrar+validar Sentry → recién entonces retirar Crashlytics (pubspec, DI, nativo). |
| R5 | **Divergencia ×6** del patrón Sentry/serializer entre servicios. | Media | Abstraer en `rideglory-common-lib`; rebuild + reinstalar disciplinado en cada MS (gotcha de memoria). |
| R6 | **Cuota free Sentry (5k/mes)** se agota con 4xx ruidosos o trazas. | Media | Filtrar 4xx de negocio (no enviar, solo loguear); `tracesSampleRate` configurable por env; un solo proyecto con tag `service`. |
| R7 | **Orden de import de `instrument.ts`** mal hecho → instrumentación NestJS incompleta/silenciosa. | Baja | `import './instrument'` como **primera línea** de cada `main.ts`, antes de `@nestjs/core`. Verificar con un error de prueba por servicio. |
| R8 | **Tracing distribuido HTTP↔TCP no automático** en Sentry (solo HTTP). | Media | Transportar `sentry-trace`/`baggage` en el mismo envelope `_meta`; diseñar el meta como mapa extensible desde Fase 1, no string suelto. |
| R9 | **Símbolos ilegibles en prod** sin dSYM/ProGuard upload. | Baja | Config de upload en CI (alcance DevOps); no bloquea desarrollo. |
| R10 | **WS no correlacionado** por traceId. | Baja | Declarado best-effort/fuera de alcance core; documentar. |

## Ajustes

1. **Fase 1 — fijar el mecanismo de propagación:** usar **Serializer/Deserializer custom del `ClientProxy` + `nestjs-cls` (AsyncLocalStorage)**, NO wrapping `{data, meta:{traceId}}` de cada payload. Resultado: **cero cambios en `@rideglory/contracts` y en los ~56 message patterns**. Esto cierra la Pregunta abierta #4 del intake y degrada R1 de Alta a Media.

2. **Fase 1 — diseñar el envelope de meta como mapa extensible** (no un solo string `traceId`), porque la Fase 2 reutilizará ese mismo canal para `sentry-trace`/`baggage`. Decisión tomada ahora para no rehacer el serializer en Fase 2.

3. **Fase 1 — redacción en dos capas:** `redact` nativo de pino (por path, declarativo) **+** interceptor request/response con allowlist. No depender de una sola capa.

4. **Fase 1 — devolver `traceId` al cliente por header** (`x-trace-id`) además del cuerpo de error, para que soporte/Flutter lo enlacen sin parsear el body.

5. **Fase 2 — un solo proyecto Sentry con tag `service`** (no proyecto-por-servicio), dado el volumen actual y la cuota free; reevaluar si el ruido lo exige. Cierra Pregunta #1.

6. **Fase 2 — `SENTRY_DSN` opcional en joi** y gating por `NODE_ENV==='production'`, para no romper el arranque de dev local sin DSN.

7. **Fase 2 — extender los filtros existentes** (`RpcCustomExceptionFilter`, `RpcAllExceptionsFilter`), no crear filtros nuevos; integrar la captura Sentry solo para ≥500.

8. **Fase 2 — abstraer en `rideglory-common-lib`** la tríada serializer/deserializer/cls + el bootstrap de Sentry, registrándola ×6 (evita R5). Recordar rebuild + reinstalar la lib en cada MS.

9. **Fase 3 — secuencia anti-ventana:** integrar y **validar** Sentry en Flutter **antes** de retirar cualquier pieza de Crashlytics (pubspec, `firebase_module.dart`, nativo). Reemplazar el `crashlytics.setCustomKey('api_base_url')` del provider `dio(...)` por un tag/scope de Sentry.

10. **Fase 3 — añadir a CI el upload de dSYM (iOS) y mapping ProGuard (Android)** como subtarea explícita (alcance DevOps); sin ello los crashes de prod salen sin símbolos.

11. **WebSocket fuera del alcance core de correlación:** documentar el tracing del canal `/tracking/ws` como best-effort; no bloquear Fases 1–2 por ello.

12. **Sin reordenar fases.** La dependencia dura (Fase 1 → 2 → 3) se mantiene; la Fase 4 es independiente e incremental y puede ir en paralelo o al final.
