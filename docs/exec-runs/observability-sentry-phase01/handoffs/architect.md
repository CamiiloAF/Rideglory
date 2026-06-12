# Architect handoff — observability-sentry-phase01

**Fecha (UTC):** 2026-06-11T19:21:19Z
**Status:** done
**Repo:** `/Users/cami/Developer/Personal/rideglory-api` (solo backend; Flutter no cambia)

---

## Decisiones

| # | ADR | Decisión |
|---|-----|----------|
| ADR-OBS-1 | Logger framework | `nestjs-pino` con `pino-pretty` en dev (`NODE_ENV !== 'production'`); JSON estructurado en prod. Un único `LoggerModule.forRootAsync()` por servicio. |
| ADR-OBS-2 | CLS provider | `nestjs-cls` con `ClsModule.forRootAsync()` en el gateway. Cada MS recibe el `traceId` por el envelope TCP, lo siembra en su propio `ClsModule` via interceptor RPC. |
| ADR-OBS-3 | Envelope TCP | `interface TcpMeta { traceId: string; [key: string]: unknown }` definida en `rideglory-common-lib/src/observability/tcp-meta.interface.ts`. Se inyecta en `data._meta` sin tocar `.send()` ni DTOs de contracts. La Fase 2 añade `sentryTrace`/`baggage` al mismo `_meta` sin rehacer el serializer. |
| ADR-OBS-4 | Serializer/deserializer | `TracingSerializer extends TcpClientProxy` (no es posible subclasear `JsonSerializer`; usar `CustomTransportStrategy` no aplica aquí). La forma correcta en NestJS 11 es registrar `serializer` en la opción del `ClientsModule.register` en cada módulo gateway. El deserializer se registra como opción `deserializer` en `NestFactory.createMicroservice`. Ambas clases viven en `common-lib/observability/`. |
| ADR-OBS-5 | PII redaction | Dos capas: (a) `redact` nativo de pino vía `pinoHttp({ redact: PII_REDACT_PATHS })` — aplica a request/response de pino-http; (b) `PiiRedactInterceptor` (NestJS `NestInterceptor`) aplica allowlist antes de serializar la respuesta al cliente. La denylist compartida `PII_SENSITIVE_FIELDS` vive en `common-lib/observability/pii-denylist.ts`. |
| ADR-OBS-6 | traceId en errores | `RpcCustomExceptionFilter` del gateway añade `traceId` al cuerpo de error **solo** si está disponible en el CLS. Nunca expone stack trace ni mensaje de sistema. |
| ADR-OBS-7 | Piloto first | Implementar patrón completo en `users-ms` primero (el más simple: un único módulo `UsersModule`). Validar correlación e2e antes de replicar a los otros 4 MS y los 9 módulos gateway. |
| ADR-OBS-8 | `NODE_ENV` | No se añade a joi validation en esta fase (PRD §3, "No entra"). El `LoggerModule` detecta `process.env.NODE_ENV === 'production'` directamente. La validación joi queda para Fase 2. |
| ADR-OBS-9 | WebSocket | `/tracking/ws` queda fuera de alcance core. Documentar la limitación en `tracking.gateway.ts` con un comentario `// TODO(observability-phase2): ...`. Sin código nuevo. |

---

## Change map

### `rideglory-common-lib` (nueva carpeta `src/observability/`)

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `src/observability/tcp-meta.interface.ts` | create | Define `TcpMeta` extensible para el envelope | low |
| `src/observability/tracing-serializer.ts` | create | Inyecta `_meta.traceId` en payload TCP saliente | med |
| `src/observability/tracing-deserializer.ts` | create | Extrae `_meta.traceId` en payload TCP entrante; tolera ausencia de `_meta` | med |
| `src/observability/cls-rpc.interceptor.ts` | create | NestJS `NestInterceptor` para MS: siembra `traceId` desde `context.args[0]._meta` en CLS | med |
| `src/observability/pii-denylist.ts` | create | `PII_SENSITIVE_FIELDS: string[]` + `PII_REDACT_PATHS: string[]` centralizados | low |
| `src/observability/pii-redact.interceptor.ts` | create | Interceptor de respuesta HTTP (gateway) que aplica allowlist antes de devolver al cliente | med |
| `src/observability/logger-options.factory.ts` | create | Factory `pinoHttpOptions(serviceName)` reutilizable por los 6 servicios | low |
| `src/observability/index.ts` | create | Barril: exporta los 6 símbolos anteriores | low |
| `src/index.ts` | modify | Añade `export * from './observability';` | low |

### `api-gateway`

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `package.json` | modify | Añadir `nestjs-pino`, `pino-http`, `pino-pretty`, `nestjs-cls`, `uuid` (si no está) | low |
| `src/main.ts` | modify | `app.useLogger(app.get(Logger))` de pino; añadir `ClsModule` bootstrap hook si necesario | low |
| `src/app.module.ts` | modify | Importar `LoggerModule.forRootAsync()`, `ClsModule.forRootAsync()` (genera/continúa traceId de `x-request-id`/`sentry-trace`); eliminar `HttpLoggerMiddleware` del `configure()`; importar `PiiRedactInterceptor` como global | high |
| `src/common/middleware/http-logger.middleware.ts` | delete | Reemplazado por `nestjs-pino` + interceptor de logging | low |
| `src/common/exceptions/rpc-custom-exception.filter.ts` | modify | Añadir `traceId` al cuerpo de error; añadir header `x-trace-id` en respuesta | med |
| `src/common/interceptors/http-logging.interceptor.ts` | create | Nuevo interceptor: emite método, ruta, status, latencia, `traceId` por request | low |
| `src/users/users.module.ts` | modify | Registrar `serializer: new TracingSerializer(clsService)` en `ClientsModule.register` | med |
| `src/events/events.module.ts` | modify | Ídem | med |
| `src/vehicles/vehicles.module.ts` | modify | Ídem | med |
| `src/maintenances/maintenances.module.ts` | modify | Ídem | med |
| `src/home/home.module.ts` | modify | Ídem | med |
| `src/tracking/tracking.module.ts` | modify | Ídem | med |
| `src/registrations/registrations.module.ts` | modify | Ídem | med |
| `src/notifications/notifications.module.ts` | modify | Ídem | med |
| `src/scheduler/notification-scheduler.module.ts` | modify | Ídem | med |
| `src/tracking/tracking.gateway.ts` | modify | Añadir comentario TODO(observability-phase2) para WS | low |

### `users-ms` (piloto — implementar primero)

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `package.json` | modify | Añadir `nestjs-pino`, `pino-http`, `pino-pretty`, `nestjs-cls` | low |
| `src/main.ts` | modify | `app.useLogger(app.get(Logger))`; registrar `deserializer: new TracingDeserializer()` en `createMicroservice` options | med |
| `src/app.module.ts` | modify | Importar `LoggerModule.forRootAsync()`, `ClsModule.forRoot({ generateId: false })`, `ClsRpcInterceptor` como global | med |

### `events-ms`

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `package.json` | modify | Ídem | low |
| `src/main.ts` | modify | Ídem users-ms | med |
| `src/app.module.ts` | modify | Ídem users-ms | med |

### `vehicles-ms`

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `package.json` | modify | Ídem | low |
| `src/main.ts` | modify | Ídem | med |
| `src/app.module.ts` | modify | Ídem | med |

### `maintenances-ms`

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `package.json` | modify | Ídem | low |
| `src/main.ts` | modify | Ídem | med |
| `src/app.module.ts` | modify | Ídem | med |

### `notifications-ms`

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `package.json` | modify | Ídem | low |
| `src/main.ts` | modify | Ídem | med |
| `src/app.module.ts` | modify | Ídem | med |

### Tests

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `rideglory-common-lib/src/observability/pii-denylist.spec.ts` | create | Test unitario: ningún campo sensible pasa la denylist; añadir campo nuevo → fallo | low |
| `rideglory-common-lib/src/observability/tracing-serializer.spec.ts` | create | Verifica que `_meta.traceId` se inyecta correctamente | low |
| `rideglory-common-lib/src/observability/tracing-deserializer.spec.ts` | create | Verifica extracción + tolerancia a envelope sin `_meta` | low |
| `api-gateway/test/observability.e2e-spec.ts` | create | Integración e2e: propagación traceId gateway→MS, header `x-trace-id`, campo en error body | high |

---

## Contratos rideglory-api

Esta fase no introduce nuevos endpoints HTTP ni message patterns. Los contratos de `@rideglory/contracts` **no cambian**. El único contrato nuevo es el envelope interno TCP:

```typescript
// rideglory-common-lib/src/observability/tcp-meta.interface.ts
export interface TcpMeta {
  traceId: string;
  [key: string]: unknown; // extensible para Fase 2 (sentryTrace, baggage)
}

// Shape del envelope enriquecido en el wire (solo interno; nunca expuesto al cliente)
// { pattern: string, data: { ...payload, _meta: TcpMeta } }
```

Header de respuesta HTTP (gateway → cliente):
```
x-trace-id: <uuid-v4>
```

Campo en cuerpo de error (gateway):
```json
{ "statusCode": 4xx/5xx, "message": "...", "traceId": "<uuid-v4>" }
```

---

## Datos / migraciones

**Sin cambios en Prisma ni en base de datos.** No se requiere `analysis/MIGRATION_PLAN.md`.

---

## Env

Ver `docs/exec-runs/observability-sentry-phase01/analysis/ENV_DELTA.md`.

Variables nuevas requeridas en cada servicio (gateway + 5 MS):

| Variable | Servicio | Descripción | Ejemplo | Requerida |
|----------|----------|-------------|---------|-----------|
| `NODE_ENV` | todos | Controla formato de logs (`production` → JSON, cualquier otro → pino-pretty) | `production` / `development` | No (sin joi validation en fase 1; default = legible) |

`NODE_ENV` ya existe en el ambiente Docker/EC2 del equipo. No se requiere añadirlo a los archivos `.env`; solo verificar que el runtime lo exponga. La validación joi de `NODE_ENV` se hace en Fase 2 (PRD constraint).

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| El `serializer` de `ClientsModule` recibe el mensaje ya serializado por el transport interno — necesita inyección de `ClsService` en tiempo de construcción del módulo, lo que fuerza `ClsModule` a estar en los providers del módulo gateway antes de `ClientsModule`. Verificar orden de imports en `AppModule`. | Usar `forwardRef` si hay circularidad; documentar en el piloto. |
| `nestjs-cls` no propaga automáticamente el contexto a callbacks asíncronos dentro de handlers de MessagePattern (`firstValueFrom`/`.toPromise()`). Si los MS llaman a otros servicios internos de forma asíncrona, el traceId puede perderse. | Alcance v1: solo el traceId se propaga en el mensaje TCP; los MS no necesitan CLS para propagar más. La correlación se logra por el traceId fijo en el log de cada handler. |
| Blast radius: los 9 módulos gateway se modifican en paralelo. Si el piloto `users-ms` tiene un bug de serialization, todos los MS fallarán idénticamente. | Validar e2e users-ms antes de abrir el resto. Guardrail en PRD §6. |
| `pino-pretty` no debe correr en producción (performance). | La factory `loggerOptions(serviceName)` usa `process.env.NODE_ENV === 'production'` para omitir `transport: { target: 'pino-pretty' }`. El build Docker de producción puede no tener `pino-pretty` instalado si se mueve a devDependency — anotado en ENV_DELTA. |
| `rideglory-common-lib` debe rebuildearse antes que cada MS consuma el nuevo export. | Guardrail explícito en PRD §6: `npm run build` en lib + reinstall en cada MS. Build agent debe seguir este orden. |
| El test e2e de propagación requiere que los 6 servicios estén corriendo. En CI, usar `docker-compose up` o mocks del ClientProxy. | Para CI sin Docker: usar `@nestjs/testing` con `MicroserviceTestingModule` y un transport custom que capture el payload. |

---

## Orden de implementación

1. **`rideglory-common-lib/src/observability/`** — 7 archivos nuevos + `index.ts` + modificar `src/index.ts`. Luego `npm run build` en la lib.
2. **Tests unitarios de common-lib** — denylist, serializer, deserializer.
3. **Reinstall en todos los consumidores** — `pnpm install` en gateway + 5 MS (consume el nuevo dist de common-lib).
4. **`api-gateway` piloto** — `package.json`, `main.ts`, `app.module.ts`, eliminar `http-logger.middleware.ts`, nuevo `http-logging.interceptor.ts`, modificar `rpc-custom-exception.filter.ts`, modificar `users.module.ts` únicamente.
5. **`users-ms` piloto** — `package.json`, `main.ts`, `app.module.ts`.
6. **Validación e2e users-ms** — levantar gateway + users-ms, enviar request, verificar traceId idéntico en ambos logs y en header de respuesta.
7. **Replicar a los 8 módulos gateway restantes** — `events`, `vehicles`, `maintenances`, `home`, `tracking`, `registrations`, `notifications`, `scheduler`.
8. **Replicar a los 4 MS restantes** — `events-ms`, `vehicles-ms`, `maintenances-ms`, `notifications-ms`.
9. **Test e2e gateway completo** — `api-gateway/test/observability.e2e-spec.ts`.
10. **Smoke de arranque ×6** — verificar que los 6 servicios arrancan sin errores de DI ni import.
11. **Comentario WS TODO** — `tracking.gateway.ts`.

---

## Superficie de regresión

- **`@rideglory/contracts`**: ningún cambio — diff no debe tocar esos archivos.
- **~66 message patterns**: ningún cambio de firma — el `_meta` va en el campo `data` como propiedad adicional; los handlers de MS leen `data.someField` igual que antes.
- **Arranque ×6**: si cualquier servicio falla en el startup, la fase no pasa.
- **PII**: el test de denylist debe fallar si un campo sensible aparece en claro en logs o respuesta.
- **Backwards compatibility del deserializer**: request sin header `x-request-id` → genera traceId nuevo; envelope TCP sin `_meta` → no lanza excepción, `traceId` queda undefined (log sin traceId pero sin crash).
- **Sin Sentry**: `grep -r '@sentry/' rideglory-api/` debe devolver 0 resultados tras la fase.

---

## Fuera de alcance

- Sentry (`@sentry/*`, `SentryModule`, `instrument.ts`) → Fase 2.
- Validación joi de `NODE_ENV` y `SENTRY_DSN` → Fase 2.
- WebSocket `/tracking/ws` tracing → best-effort; solo comentario TODO en Fase 1.
- Cambios en Flutter (`lib/`) → Fase 3.
- Modificar `@rideglory/contracts` o DTOs de contracts.
- Tracing distribuido full (OpenTelemetry spans, trace context W3C) → fuera de las 3 fases actuales.
