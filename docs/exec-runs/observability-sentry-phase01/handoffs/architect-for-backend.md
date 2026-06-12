> Slim handoff — lee esto antes de docs/exec-runs/observability-sentry-phase01/handoffs/architect.md

# Architect → Backend — observability-sentry-phase01

**Repo:** `/Users/cami/Developer/Personal/rideglory-api`
**Flutter:** sin cambios en esta fase.

---

## Nuevas dependencias (instalar en cada servicio afectado)

```bash
npm install nestjs-pino pino-http nestjs-cls uuid
npm install --save-dev pino-pretty
```
Aplicar en: `api-gateway`, `users-ms`, `events-ms`, `vehicles-ms`, `maintenances-ms`, `notifications-ms`.
También añadir `nestjs-pino`, `pino-http`, `nestjs-cls` a `peerDependencies` de `rideglory-common-lib` (no a dependencies directas de la lib).

---

## 1. `rideglory-common-lib/src/observability/` — crear 7 archivos + barril

### `tcp-meta.interface.ts`
```typescript
export interface TcpMeta {
  traceId: string;
  [key: string]: unknown; // Fase 2 añadirá sentryTrace, baggage
}
```

### `tracing-serializer.ts`
- Implementa `Serializer` de `@nestjs/microservices`.
- En `serialize(value)`: lee `traceId` del `ClsService`; si existe, añade `value.data._meta = { traceId }` antes de `JSON.stringify`.
- Constructor recibe `ClsService` (inyectado en el módulo gateway).

### `tracing-deserializer.ts`
- Implementa `Deserializer` de `@nestjs/microservices`.
- En `deserialize(value)`: parsea JSON; extrae `data._meta?.traceId`; devuelve el mensaje sin modificar el campo `data` (los handlers lo leen normalmente). Retorna `{ pattern, data }` incluyendo `_meta` en `data` para que el interceptor RPC lo extraiga.
- Si no hay `_meta`: no lanza; continúa normalmente.

### `cls-rpc.interceptor.ts`
- `@Injectable() ClsRpcInterceptor implements NestInterceptor`
- En `intercept(context, next)`: si `context.getType() === 'rpc'`, lee `context.getArgByIndex(0)._meta?.traceId`; si existe, llama `cls.set('traceId', traceId)`.
- Registrar como global en `AppModule` de cada MS.

### `pii-denylist.ts`
```typescript
export const PII_SENSITIVE_FIELDS = [
  'authorization', 'password', 'email', 'phone', 'phoneNumber',
  'soatNumber', 'licensePlate', 'vin', 'idToken', 'token',
  'firebaseToken', 'fcmToken',
];
export const PII_REDACT_PATHS = [
  'req.headers.authorization',
  'req.body.password',
  'req.body.email',
  'req.body.phone',
  'req.body.phoneNumber',
  'req.body.licensePlate',
  'req.body.vin',
  'res.body.email',
];
```

### `pii-redact.interceptor.ts`
- `@Injectable() PiiRedactInterceptor implements NestInterceptor` (solo gateway).
- Intercepta la respuesta HTTP; elimina cualquier campo de `PII_SENSITIVE_FIELDS` del body antes de enviarlo.
- Registrar como `APP_INTERCEPTOR` en `AppModule` del gateway.

### `logger-options.factory.ts`
```typescript
export function pinoHttpOptions(context: string): Params {
  const isProd = process.env.NODE_ENV === 'production';
  return {
    pinoHttp: {
      name: context,
      level: isProd ? 'info' : 'debug',
      redact: { paths: PII_REDACT_PATHS, censor: '[REDACTED]' },
      ...(isProd ? {} : { transport: { target: 'pino-pretty' } }),
    },
  };
}
```

### `index.ts` (barril)
```typescript
export * from './tcp-meta.interface';
export * from './tracing-serializer';
export * from './tracing-deserializer';
export * from './cls-rpc.interceptor';
export * from './pii-denylist';
export * from './pii-redact.interceptor';
export * from './logger-options.factory';
```

Modificar `src/index.ts`:
```typescript
export * from './observability'; // añadir esta línea
```

Luego: `npm run build` en `rideglory-common-lib` + `pnpm install` en cada consumidor.

---

## 2. `api-gateway` — cambios clave

### `src/app.module.ts`
```typescript
// Añadir imports:
import { LoggerModule } from 'nestjs-pino';
import { ClsModule } from 'nestjs-cls';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { pinoHttpOptions, PiiRedactInterceptor } from '@rideglory/common-lib';

// En @Module.imports — agregar:
LoggerModule.forRootAsync({
  useFactory: () => pinoHttpOptions('ApiGateway'),
}),
ClsModule.forRoot({
  global: true,
  middleware: {
    mount: true,
    generateId: true,
    idGenerator: (req) =>
      (req.headers['x-request-id'] as string) ||
      (req.headers['sentry-trace'] as string)?.split('-')[0] ||
      crypto.randomUUID(),
  },
}),

// En @Module.providers — agregar:
{ provide: APP_INTERCEPTOR, useClass: PiiRedactInterceptor },

// En configure(consumer): ELIMINAR HttpLoggerMiddleware
// Eliminar el archivo http-logger.middleware.ts
```

### `src/main.ts`
```typescript
import { Logger } from 'nestjs-pino';
// En bootstrap(), después de NestFactory.create:
app.useLogger(app.get(Logger));
```

### `src/common/interceptors/http-logging.interceptor.ts` (nuevo)
```typescript
@Injectable()
export class HttpLoggingInterceptor implements NestInterceptor {
  constructor(private readonly logger: Logger, private readonly cls: ClsService) {}
  intercept(context: ExecutionContext, next: CallHandler) {
    const req = context.switchToHttp().getRequest();
    const { method, url } = req;
    const traceId = this.cls.get('traceId');
    const start = Date.now();
    return next.handle().pipe(
      tap(() => {
        const res = context.switchToHttp().getResponse();
        res.setHeader('x-trace-id', traceId ?? '');
        this.logger.log({ method, url, status: res.statusCode, ms: Date.now() - start, traceId });
      }),
    );
  }
}
```
Registrar como `APP_INTERCEPTOR` en `AppModule`.

### `src/common/exceptions/rpc-custom-exception.filter.ts`
En `catch()`: recuperar `traceId` de `ClsService`; añadir al body de error y como header `x-trace-id`.

### 9 módulos gateway con `ClientsModule`
En cada uno, modificar `ClientsModule.register` para añadir `serializer`:
```typescript
// Inyectar ClsService en el módulo y pasarlo al serializer
// options: { ..., serializer: new TracingSerializer(clsService) }
```
Nota: `ClsModule` debe estar importado a nivel `AppModule` con `global: true` para que `ClsService` esté disponible sin importarlo en cada módulo.

---

## 3. Cada MS (users-ms piloto primero)

### `src/main.ts`
```typescript
import { Logger } from 'nestjs-pino';
// En createMicroservice options:
options: {
  host: '0.0.0.0',
  port: envs.port,
  deserializer: new TracingDeserializer(),
},
// Después de crear la app:
app.useLogger(app.get(Logger));
```

### `src/app.module.ts`
```typescript
import { LoggerModule } from 'nestjs-pino';
import { ClsModule } from 'nestjs-cls';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { pinoHttpOptions, ClsRpcInterceptor } from '@rideglory/common-lib';

// imports:
LoggerModule.forRootAsync({ useFactory: () => pinoHttpOptions('UsersMicroservice') }),
ClsModule.forRoot({ global: true, middleware: { mount: false } }),

// providers:
{ provide: APP_INTERCEPTOR, useClass: ClsRpcInterceptor },
```

---

## Orden de ejecución mandatorio

1. Build + export de `rideglory-common-lib`
2. Reinstall en todos los servicios
3. Gateway (app.module + main + interceptors + 1 módulo: users.module)
4. users-ms (main + app.module)
5. Validar e2e users-ms (traceId idéntico gateway + MS + header)
6. Replicar 8 módulos gateway restantes
7. Replicar 4 MS restantes
8. Smoke de arranque ×6

---

## Guardrails

- `grep -r '@sentry/' .` → 0 resultados (sin Sentry en esta fase)
- `git diff --name-only | grep contracts` → 0 resultados (no tocar contracts)
- Cada servicio arranca sin errores en stderr

> Full detail: docs/exec-runs/observability-sentry-phase01/handoffs/architect.md
