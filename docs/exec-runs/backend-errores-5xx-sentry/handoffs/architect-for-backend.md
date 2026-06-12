> Slim handoff — lee esto antes de docs/exec-runs/backend-errores-5xx-sentry/handoffs/architect.md

# Architect → Backend: backend-errores-5xx-sentry

## Scope

100% backend. No hay cambios Flutter. Todos los cambios van en `rideglory-api/`.

## Secuencia obligatoria (respetar orden)

1. `rideglory-common-lib` — implementar primero, `npm run build`
2. Reinstalar common-lib en los 6 MS (`pnpm install` en el workspace raíz o por servicio)
3. api-gateway → users-ms → events-ms → vehicles-ms → maintenances-ms → notifications-ms
4. Tests
5. Smoke test de arranque sin `SENTRY_DSN`

## Paquetes nuevos

- `rideglory-common-lib/package.json`: `@sentry/node` como `peerDependency` + `devDependency`
- `api-gateway/package.json`: `@sentry/nestjs`, `@sentry/node`
- Cada MS `package.json`: `@sentry/node`

## Archivos nuevos a crear

### rideglory-common-lib/src/sentry/

**`init-sentry.ts`** — función `initSentry(service: string, dsn?: string, opts?: { tracesSampleRate?: number })`
- Gate: si `NODE_ENV !== 'production' && process.env.SENTRY_DEV_VERIFY !== 'true'` → return sin init
- Si `!dsn` → return sin init
- Llama `Sentry.init({ dsn, tracesSampleRate: opts?.tracesSampleRate ?? 0.1, enableLogs: true, beforeSend, beforeSendLog, beforeBreadcrumb, initialScope: { tags: { service } } })`
- Importa `beforeSend`, `beforeSendLog`, `beforeBreadcrumb` desde `./pii-filter`

**`pii-filter.ts`** — implementa los 3 hooks usando `PII_SENSITIVE_FIELDS` de `../observability/pii-denylist`
- `beforeSend(event)`: scrubea `event.request?.headers`, `event.request?.data`, `event.extra`, `event.exception.values[].value` (regex sobre campos de la denylist)
- `beforeSendLog(log)`: scrubea `log.attributes`
- `beforeBreadcrumb(breadcrumb)`: scrubea `breadcrumb.data`

**`sentry.module.ts`** — `@Global() @Module({}) export class SentryModule {}` (stub documental)

**`index.ts`** — `export * from './init-sentry'; export * from './pii-filter'; export * from './sentry.module'`

### Cada MS: `src/instrument.ts`

```typescript
// Debe ser PRIMER import en main.ts — antes de dotenv/config
import { initSentry } from '@rideglory/common-lib';
import { envs } from './config/envs';
initSentry('<service-name>', envs.sentryDsn, { tracesSampleRate: envs.sentryTracesSampleRate });
```

(api-gateway usa `import * as Sentry from '@sentry/nestjs'` dentro de `initSentry`; los 5 MS usan `@sentry/node`)

## Archivos a modificar

### rideglory-common-lib/src/index.ts
Agregar `export * from './sentry';`

### rideglory-common-lib/src/filters/rpc-all-exceptions.filter.ts
Extensión aditiva en el bloque `catch()`:
- Leer `traceId` de `process.env` o pasar como constructor arg (recomendado: constructor opcional `(service?: string)`)
- Rama `status >= 500`: agregar `Sentry.captureException(exception, { tags: { service: this.service }, extra: { traceId } });`
- Rama 4xx (HttpException con status < 500 o RpcException 4xx): agregar `Sentry.logger.warn('4xx error', { service: this.service, status, traceId, message });`
- No alterar el `super.catch()` ni el flujo de re-throw

### api-gateway/src/common/exceptions/rpc-custom-exception.filter.ts
En el método `catch()`:
- Después de `const traceId: string | undefined = this.cls?.get?.('traceId');`
- Agregar: si `normalized.status >= 500` → `Sentry.captureException(exception, { tags: { service: 'api-gateway' }, extra: { traceId } });`
- Si `normalized.status < 500` → `Sentry.logger.warn('4xx gateway error', { service: 'api-gateway', status: normalized.status, traceId, message: normalized.message });`
- La respuesta HTTP `{ statusCode, message, traceId? }` no cambia

### api-gateway/src/main.ts
Primera línea absoluta:
```typescript
import './instrument';
import 'dotenv/config';  // <-- ya existía, ahora es segunda línea
```

### Cada MS src/main.ts — misma primera línea `import './instrument';`

### config/envs.ts en cada servicio — agregar:
```typescript
// En EnvVars interface:
SENTRY_DSN?: string;
SENTRY_TRACES_SAMPLE_RATE?: number;
SENTRY_DEV_VERIFY?: string;

// En joi schema:
SENTRY_DSN: joi.string().uri().optional(),
SENTRY_TRACES_SAMPLE_RATE: joi.number().min(0).max(1).optional(),
SENTRY_DEV_VERIFY: joi.string().optional(),

// En objeto envs exportado:
sentryDsn: envVars.SENTRY_DSN,
sentryTracesSampleRate: envVars.SENTRY_TRACES_SAMPLE_RATE,
sentryDevVerify: envVars.SENTRY_DEV_VERIFY,
```

## Env vars nuevas (todas opcionales)

| Variable | Descripción |
|----------|-------------|
| `SENTRY_DSN` | DSN del proyecto Sentry único |
| `SENTRY_TRACES_SAMPLE_RATE` | Default `0.1`. Fracción de traces enviados |
| `SENTRY_DEV_VERIFY` | `'true'` activa Sentry en dev/staging para verificación |

## Tests requeridos

- `rideglory-common-lib/src/sentry/pii-filter.spec.ts` — verifica `beforeSend` no filtra PII; verifica `captureException` no se llama para 4xx
- `rideglory-common-lib/src/filters/rpc-all-exceptions.filter.spec.ts` — `captureException` para ≥500; `Sentry.logger.warn` para 400/404; flujo re-throw intacto
- `api-gateway/src/common/exceptions/rpc-custom-exception.filter.spec.ts` — misma batería + tag `service: 'api-gateway'`
- `api-gateway/src/instrument.spec.ts` — sin `NODE_ENV=production` y sin `SENTRY_DEV_VERIFY`, `Sentry.init` no se llama

## Limitación documentada (WebSocket)

El canal `/tracking/ws` (`api-gateway/src/tracking/tracking.gateway.ts`) no participa del CLS HTTP middleware. La correlación `traceId` en WS requiere propagación manual fuera del alcance de esta fase. Documentar como comentario `// Sentry WS tracing: fuera de alcance fase 2 — ver PRD §3 No entra`.

> Full detail: docs/exec-runs/backend-errores-5xx-sentry/handoffs/architect.md
