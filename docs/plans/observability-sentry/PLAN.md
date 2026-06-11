# Plan: observability-sentry

> Estado: BORRADOR — revision humana pendiente. Generado: 2026-06-10T22:35:05Z

## Overview

Reconstrucción de la observabilidad end-to-end de Rideglory (móvil + backend) en 4 fases: núcleo secuencial 1→2→3 más una Fase 4 incremental mayormente independiente. Casi sin UI nueva (único contacto visible: tile opt-out de analytics ya existente). Objetivo transversal: seguir un request por su traceId desde Flutter→gateway→microservicios, ver crashes y 5xx correlacionados en Sentry SOLO en prod, retirar Crashlytics sin ventana sin cobertura, y nunca filtrar PII ni secretos. Decisión arquitectónica clave ya cerrada: el traceId viaja por TCP con Serializer/Deserializer custom del ClientProxy + nestjs-cls (AsyncLocalStorage), NO envolviendo cada payload en {data,meta}, dejando en cero los cambios a @rideglory/contracts y a los ~56 message patterns (baja R1 de Alta a Media). De las 5 decisiones originalmente delegadas al Architect, 2 ya quedan cerradas por este plan (shape TCP y proyecto-vs-tag); el gate pre-ejecución aplica solo a las 3 restantes: sampling, gestión de DSN por flavor/CI y allowlist/denylist exacta de PII. Regla de oro transversal: dev→consola, prod→Sentry; jamás PII. Documento de síntesis en docs/plans/observability-sentry/05-sintesis.md.

## Fases

- Fase 1 [FULL]: [Fase 1 — Backend: traceId distribuido por TCP + logs estructurados sin PII](phases/phase-01-backend-traceid-distribuido-por-tcp-logs-estruct.md)
- Fase 2 [FULL]: [Fase 2 — Backend: errores 5xx en Sentry con traza distribuida](phases/phase-02-backend-errores-5xx-en-sentry-con-traza-distribu.md)
- Fase 3 [FULL]: [Fase 3 — Flutter: Sentry reemplaza Crashlytics, enlazado al backend](phases/phase-03-flutter-sentry-reemplaza-crashlytics-enlazado-al.md)
- Fase 4 [LITE]: [Fase 4 — Insights de producto: taps, screen_view y catálogo documentado](phases/phase-04-insights-de-producto-taps-screen-view-y-catalogo.md)

## Supuestos

- Las interfaces `CrashReporter` y `AnalyticsService` ya existen y son Dart puro → la migración Flutter es de implementación + init + deps + retiro de Crashlytics, de bajo riesgo arquitectónico.
- Los DSN de prod y `NODE_ENV` se inyectan por configuración existente (`config/<flavor>.json` / `--dart-define` en Flutter; `.env`/secret manager en backend); no se exponen en el repo.
- La app aún no tiene usuarios reales → se puede retirar Crashlytics de forma agresiva siempre que los tests pasen y no quede ventana sin reporte de crashes.
- No se requiere histórico de Crashlytics; se acepta empezar limpio en Sentry.
- Cuota free de Sentry (5k errores/mes) es suficiente con filtrado de 4xx de negocio + sampling configurable.
- La tríada serializer/deserializer/cls vive en `rideglory-common-lib`; aplica el gotcha de rebuild (`npm run build` + reinstalar en cada MS).

## Riesgos

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

Antes de abrir cada `rg-exec`, cerrar la decisión que aplica a esa fase (solo quedan 3 abiertas, no 5):
- **Fase 1:** allowlist/denylist exacta de PII (fuente compartida + test).
- **Fase 2:** sampling (`tracesSampleRate`) y gestión de DSN backend (secret manager / `.env`).
- **Fase 3:** gestión de DSN por flavor + upload de símbolos en CI.

## Como ejecutar una fase

> Cada fase se implementa con rg-exec en el NIVEL recomendado (ver el [LITE/NORMAL/FULL] del titulo y la seccion "Ejecucion recomendada" de cada fase):
>
> ```js
> Workflow({ name: 'rg-exec', args: { source: 'docs/plans/observability-sentry/phases/phase-01-backend-traceid-distribuido-por-tcp-logs-estruct.md', mode: '<lite|normal|full>' } })
> ```
>
> lite = mecanico/bajo riesgo; normal = feature acotada; full = complejo/riesgoso (contratos, migraciones, seguridad).
