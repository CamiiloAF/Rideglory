> Slim handoff — lee esto antes de docs/exec-runs/observability-sentry-phase01/handoffs/architect.md

# Architect → QA — observability-sentry-phase01

**Repo:** `/Users/cami/Developer/Personal/rideglory-api`
**Flutter:** sin cambios — no correr `flutter test`.

---

## Criterios de aceptación (trazabilidad con PRD §5)

| # | Criterio | Cómo verificar |
|---|----------|---------------|
| AC-1 | `traceId` idéntico en log del gateway y en log del MS | Levantar gateway + users-ms; enviar `POST /api/users/...`; comparar `traceId` en stdout de ambos procesos. |
| AC-2 | `x-request-id` entrante se continúa como `traceId` | `curl -H "x-request-id: test-123" <endpoint>`; verificar que `traceId: "test-123"` aparece en los logs. |
| AC-3 | Header `x-trace-id` en respuesta HTTP | Verificar con `curl -I` que la respuesta incluye `x-trace-id: <uuid>`. |
| AC-4 | Logs dev son legibles; logs prod son JSON | Levantar con `NODE_ENV=production`; verificar que stdout es JSON one-line. Levantar sin `NODE_ENV`; verificar pino-pretty. |
| AC-5 | PII no aparece en logs ni en cuerpo de respuesta | Enviar request con `Authorization: Bearer secret`; verificar que en los logs aparece `[REDACTED]`. |
| AC-6 | Message patterns sin cambio de firma | `git diff -- rideglory-contracts/ && git diff -- '**/message-patterns*'` → 0 líneas de cambio. |
| AC-7 | `observability/` solo en common-lib | No deben existir copias de `TcpMeta`, `TracingSerializer`, etc. fuera de `rideglory-common-lib/src/observability/`. |
| AC-8 | `HttpLoggerMiddleware` eliminado | `grep -r 'HttpLoggerMiddleware' api-gateway/src/` → 0 resultados. |
| AC-9 | Interceptor gateway emite método, ruta, status, latencia, `traceId` | Revisar stdout del gateway; cada request debe producir una línea con esos 5 campos. |
| AC-10 | Sin Sentry | `grep -r '@sentry/' rideglory-api/` → 0 resultados. |
| AC-11 | Arranque ×6 sin errores | `node dist/main` (o `npm run start:prod`) en cada servicio → no debe haber `ERROR` ni `Exception` en los primeros 5 segundos. |

---

## Tests a correr tras la implementación

### `rideglory-common-lib`
```bash
cd rideglory-common-lib
npm run build
npm test
# Debe pasar:
# - pii-denylist.spec.ts (campo sensible → [REDACTED]; campo nuevo sin denylist → fallo)
# - tracing-serializer.spec.ts (_meta.traceId inyectado)
# - tracing-deserializer.spec.ts (extrae traceId; envelope sin _meta no lanza)
```

### `api-gateway`
```bash
cd api-gateway
npm test             # unit tests existentes no deben regresar
npm run test:e2e     # observability.e2e-spec.ts nuevo
```

### Cada MS
```bash
cd users-ms && npm test
cd events-ms && npm test
cd vehicles-ms && npm test
cd maintenances-ms && npm test
cd notifications-ms && npm test
```

---

## Guardrails automáticos (anti-regresión)

- **denylist.spec.ts:** falla si se añade un campo sensible nuevo que no esté en `PII_SENSITIVE_FIELDS`.
- **deserializer.spec.ts:** falla si envelope sin `_meta` lanza excepción.
- **e2e:** falla si `x-trace-id` no aparece en la respuesta HTTP.
- **grep check:** `grep -r '@sentry/' .` dentro del repo → debe retornar vacío.

---

## Fuera de alcance QA en esta fase

- Tests de Flutter (`flutter test`) — no aplica.
- Tests de WebSocket tracking — fuera de alcance core.
- Tests de performance de pino vs Logger de NestJS.

> Full detail: docs/exec-runs/observability-sentry-phase01/handoffs/architect.md
