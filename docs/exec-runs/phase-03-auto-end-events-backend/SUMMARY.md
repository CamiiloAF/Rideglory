# SUMMARY — Phase 03: Auto-End Events Backend

**Timestamp:** 2026-07-01T03:35:03Z
**Agente:** Tech Lead
**Veredicto:** needs_changes

---

## Objetivo

Cerrar automáticamente rodadas `IN_PROGRESS` con más de 24 horas sin terminar, mediante:
- Un cron horario en `NotificationSchedulerService` (api-gateway)
- Dos nuevos MessagePatterns TCP internos en events-ms (`findActiveEventsOlderThan`, `forceEndTracking`)
- Extracción de la lógica FCM a un servicio inyectable (`TrackingNotificationsService`)

---

## Qué cambió por área

### events-ms

- `events.service.ts`: Agrega `findActiveEventsOlderThan(cutoffDate)` y `forceEndTracking(eventId)` idempotente. Formateo en métodos existentes (sin cambio de lógica).
- `events.controller.ts`: Dos nuevos `@MessagePattern` con comentario `// INTERNAL ONLY — no HTTP endpoint`.
- `events.service.spec.ts`: Corrige 3 tests con drift en `findUpcoming`; agrega 7 tests nuevos (AC1, AC2, AC3). 13 tests totales, todos pasan.

**Archivos fuera de alcance en working tree (commit separado obligatorio):**
- `prisma/migrations/20260701014208_add_medical_consent_risk_fields/migration.sql`
- `prisma/schema.prisma`
- `src/registrations/registrations.service.ts`

### api-gateway

- `tracking-notifications.service.ts` (nuevo): Extrae `sendEventEndedNotifications` del controller. Lógica FCM idéntica, ahora inyectable.
- `tracking-http.controller.ts`: Inyecta `TrackingNotificationsService`; delega FCM. **BUG-01** (blocker): auth de `endTracking` cambió de `uid` a `email+findUserByEmail` — fuera de alcance, viola PRD §6 guardrail, inconsistente con `startTracking`.
- `tracking.module.ts`: Añade `TrackingNotificationsService` a providers + exports `[TrackingNotificationsService, TrackingBroadcaster]`.
- `notification-scheduler.module.ts`: Importa `TrackingModule`.
- `notification-scheduler.service.ts`: Inyecta `TrackingNotificationsService` y `TrackingBroadcaster`; `_autoEndRunning` flag; cron `autoEndStalledEvents()` correcto con guard, ventana 24h, aislamiento por evento, finally-reset.

---

## Archivos

### events-ms — en scope
- `src/events/events.service.ts`
- `src/events/events.controller.ts`
- `src/events/events.service.spec.ts`

### events-ms — fuera de scope (commit separado)
- `prisma/migrations/20260701014208_add_medical_consent_risk_fields/`
- `prisma/schema.prisma`
- `src/registrations/registrations.service.ts`

### api-gateway — en scope
- `src/tracking/tracking-notifications.service.ts` (nuevo)
- `src/tracking/tracking-notifications.service.spec.ts` (nuevo)
- `src/tracking/tracking-http.controller.ts`
- `src/tracking/tracking-http.controller.spec.ts` (nuevo)
- `src/tracking/tracking.module.ts`
- `src/scheduler/notification-scheduler.module.ts`
- `src/scheduler/notification-scheduler.service.ts`
- `src/scheduler/notification-scheduler-auto-end.service.spec.ts` (nuevo)

---

## Pruebas

| Suite | Tests | Estado |
|-------|-------|--------|
| `events-ms` — `events.service.spec` | 13 pass | VERDE |
| `api-gateway` — `notification-scheduler` (pre-existing + Phase03) | 42 pass | VERDE |
| `api-gateway` — `tracking-notifications.service.spec` | 5 pass | VERDE |
| `api-gateway` — `tracking-http.controller.spec` | 6 pass | VERDE |

Verificado localmente con `npx jest`.

---

## Riesgos / Watchlist

| ID | Riesgo | Severidad | Estado |
|----|--------|-----------|--------|
| BUG-01 | `endTracking` auth cambió de `uid` a `email+findUserByEmail` — out-of-scope, viola PRD §6, inconsistente con `startTracking` | BLOCKER | Fix requerido |
| OUT-SCOPE-EVENTS-MS | 3 archivos de otro feature mezclados en events-ms working tree | MEDIO | Commit separado antes de Phase 03 |
| DEPLOY-ORDER | Phase 03 sin Phase 01 activo en producción deja GPS/WS abiertos en clientes | ALTO | Constraint de despliegue |

---

## Mensaje de commit sugerido

### events-ms (solo archivos en scope)
```
feat(events): add findActiveEventsOlderThan and forceEndTracking for auto-end cron

Adds two INTERNAL ONLY MessagePatterns (TCP, never HTTP):
- findActiveEventsOlderThan: finds IN_PROGRESS events with startDate <= cutoff
- forceEndTracking: idempotent transition to FINISHED (no owner check)
Fix 3 drifted tests in findUpcoming + 7 new unit tests covering AC1-AC3.
```

### api-gateway
```
feat(scheduler): auto-end stalled IN_PROGRESS events after 24h

- Extract TrackingNotificationsService from TrackingHttpController
- Export TrackingNotificationsService + TrackingBroadcaster from TrackingModule
- Import TrackingModule in NotificationSchedulerModule
- Add autoEndStalledEvents @Cron('0 * * * *', America/Bogota) with boolean guard,
  24h cutoff, per-event error isolation, and finally-reset
- 20 new unit tests (AC1-AC10 full coverage)

Note: revert BUG-01 auth change in endTracking before this commit.
```
