# Architect handoff — Phase 03: Auto-End Events Backend

**Date:** 2026-07-01T01:53:31Z
**Status:** done

---

## Decisiones

| Flag | Valor | Razon |
|------|-------|-------|
| `uiChanges` | false | Phase puramente backend; Flutter ya se hizo en Phase 1 |
| `backendChanges` | true | events-ms + api-gateway modificados |
| `frontendChanges` | false | Sin cambios Flutter en este phase |
| `dbChanges` | false | `state` y `startDate` ya existen en el schema Prisma de events-ms (verificado) |
| `needsDesign` | false | Sin pantallas nuevas |

---

## Change map

| Repo / Submodulo | Archivo | Action | Razon | Riesgo |
|---|---|---|---|---|
| `events-ms` | `src/events/events.service.ts` | modify | Agrega `findActiveEventsOlderThan(cutoffDate)` + `forceEndTracking(eventId)` idempotente | med |
| `events-ms` | `src/events/events.controller.ts` | modify | Agrega `@MessagePattern('findActiveEventsOlderThan')` y `@MessagePattern('forceEndTracking')` con comentario `// INTERNAL ONLY` | med |
| `events-ms` | `src/events/events.service.spec.ts` | modify | Tests de los dos nuevos metodos (filtro correcto, idempotencia, error aislado) | low |
| `api-gateway` | `src/tracking/tracking-notifications.service.ts` | create | Extrae `sendEventEndedNotifications` de `TrackingHttpController` a servicio inyectable | low |
| `api-gateway` | `src/tracking/tracking-http.controller.ts` | modify | Inyecta `TrackingNotificationsService`; delega en lugar de llamar metodo privado | low |
| `api-gateway` | `src/tracking/tracking.module.ts` | modify | Agrega `TrackingNotificationsService` a `providers` y `exports`; agrega `TrackingBroadcaster` a `exports` | low |
| `api-gateway` | `src/scheduler/notification-scheduler.module.ts` | modify | Importa `TrackingModule` | low |
| `api-gateway` | `src/scheduler/notification-scheduler.service.ts` | modify | Inyecta `TrackingNotificationsService` + `TrackingBroadcaster`; agrega flag `_autoEndRunning` y metodo `@Cron('0 * * * *')` `autoEndStalledEvents()` | med |
| `api-gateway` | `src/scheduler/notification-scheduler-auto-end.service.spec.ts` | create | Tests del cron (happy path, sin eventos, idempotencia, error aislado, guard) | low |

---

## Contratos

### events-ms — nuevos MessagePatterns (TCP interno, NUNCA HTTP)

**`findActiveEventsOlderThan`**
- Payload: `{ cutoffDate: string }` (ISO 8601)
- Response: `Array<{ id: string }>`
- Logica: `event.findMany({ where: { state: 'IN_PROGRESS', startDate: { lte: new Date(cutoffDate) } }, select: { id: true } })`
- NULL-safety: Prisma no evalua `null lte date`; registros con `startDate = null` son excluidos automaticamente

**`forceEndTracking`**
- Payload: `{ eventId: string }`
- Response: `{ id: string; state: string }`
- Logica: si `state !== IN_PROGRESS`, retorna inmediatamente (idempotente); si `IN_PROGRESS`, hace `update({ state: FINISHED })` y retorna
- Sin owner check (INTERNAL ONLY)
- Comentario obligatorio en `EventsController`: `// INTERNAL ONLY — no HTTP endpoint`

### api-gateway — TrackingNotificationsService

- Clase: `@Injectable() export class TrackingNotificationsService`
- Archivo: `src/tracking/tracking-notifications.service.ts`
- Dependencias: `@Inject(EVENTS_SERVICE)`, `@Inject(USERS_SERVICE)`, `NotificationsService`
- Metodo publico: `sendEventEndedNotifications(eventId: string): Promise<void>`
- Logica: identica a `TrackingHttpController.sendEventEndedNotifications` actual; FCM multicast a todos los registrantes APPROVED con `type: 'TRACKING_ENDED'`, deeplink `rideglory://events/detail-by-id?id=<eventId>`
- Timeout RPC: `5_000` ms (alineado con la implementacion actual)

### api-gateway — NotificationSchedulerService: autoEndStalledEvents

```
@Cron('0 * * * *', { timeZone: 'America/Bogota' })
async autoEndStalledEvents(): Promise<void>
```

- Guard: `if (this._autoEndRunning) { this.logger.warn(...); return; }`
- Ventana: `cutoffDate = new Date(Date.now() - 24 * 60 * 60_000)` (fija, v1)
- RPC timeout: `10_000` ms para `findActiveEventsOlderThan` y `forceEndTracking`
- Por cada evento: (1) RPC `forceEndTracking`, (2) `trackingBroadcaster.broadcastEventEnded(eventId)`, (3) `void trackingNotificationsService.sendEventEndedNotifications(eventId).catch(() => undefined)`
- Error por evento: caught con `logger.error`, cron continua con los demas
- Guard reset: `finally { this._autoEndRunning = false }`

---

## Datos / Migraciones

Sin migraciones. El schema de `events-ms` ya tiene:
- `state EventState` (enum con `IN_PROGRESS`, `FINISHED`)
- `startDate DateTime`

Verificado en `events-ms/prisma/schema.prisma` lineas 36, 38, 65, 75.

---

## Env

Sin nuevas variables de entorno. Todos los TCP hosts/ports ya configurados en `api-gateway/config/envs` y `events-ms/src/config`.

---

## Riesgos

| Riesgo | Mitigacion |
|--------|-----------|
| `forceEndTracking` podria ser invocado via HTTP si alguien agrega un endpoint HTTP inadvertidamente | Comentario `// INTERNAL ONLY — no HTTP endpoint` obligatorio en `EventsController`; revision explicita en code review; criterio de aceptacion §5.8 |
| Importar `TrackingModule` en `NotificationSchedulerModule` carga el `TrackingGateway` (WS) en el mismo modulo | Es esperado y correcto; `TrackingGateway` no tiene efectos secundarios al ser importado como dependencia transitiva |
| `TrackingBroadcaster` ya tiene su propio `EVENTS_SERVICE` client registrado via `TrackingModule`; al importar `TrackingModule` en `NotificationSchedulerModule` no hay duplicacion de registros TCP porque NestJS reutiliza el mismo token | Comportamiento verificado de NestJS DI con `ClientsModule.registerAsync` |
| Events con `startDate = null` (caso raro) podrian satisfacer el filtro incorrectamente | Prisma `lte` con NULL es NULL (falso): registros con `startDate = null` son excluidos automaticamente |
| Fase 3 en produccion sin Fase 1 (Flutter) ya activa: el WS broadcast llega a riders con GPS/WS abiertos que no tienen el handler de cleanup | Constraint de despliegue: Fase 1 debe estar en produccion primero (§6 del PRD) |

---

## Orden de Implementacion

1. `events-ms/src/events/events.service.ts` — metodos `findActiveEventsOlderThan` + `forceEndTracking`
2. `events-ms/src/events/events.controller.ts` — 2 `@MessagePattern` con comentario INTERNAL ONLY
3. `events-ms/src/events/events.service.spec.ts` — tests de los nuevos metodos
4. `api-gateway/src/tracking/tracking-notifications.service.ts` — nuevo archivo con logica extraida
5. `api-gateway/src/tracking/tracking-http.controller.ts` — inyectar + delegar
6. `api-gateway/src/tracking/tracking.module.ts` — providers + exports actualizados
7. `api-gateway/src/scheduler/notification-scheduler.module.ts` — importar `TrackingModule`
8. `api-gateway/src/scheduler/notification-scheduler.service.ts` — nuevas inyecciones, flag, cron
9. `api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` — tests del cron

---

## Superficie de Regresion

- `POST /api/events/:eventId/tracking/end` (endpoint manual): comportamiento externo invariante; solo la implementacion interna delega a `TrackingNotificationsService`. Cubierto por criterio de aceptacion §5.9.
- Metodos cron existentes en `NotificationSchedulerService` (SOAT, RTM, maintenance, event reminders): sin cambios en su logica; la inyeccion de `TrackingNotificationsService` y `TrackingBroadcaster` son nuevos parametros en el constructor que no afectan los metodos existentes.
- `TrackingBroadcaster.broadcastEventEnded` ya existe y no cambia su firma.
- `TrackingRoomsService` no cambia.
- `TrackingGateway` no cambia.
- Tests existentes: `events.service.spec.ts` y `notification-scheduler.service.spec.ts` deben seguir pasando sin modificaciones a sus casos existentes.

---

## Fuera de Alcance

- Endpoint HTTP para `forceEndTracking`
- Lock distribuido (Redis) para el cron — suficiente con flag booleano v1
- Configuracion de ventana 24h via env-var — valor fijo en v1
- Cambios en `rideglory-contracts` — MessagePatterns son internos al canal TCP
- Cambios Flutter (Phase 1)
- `removeRoom` en `TrackingRoomsService`
