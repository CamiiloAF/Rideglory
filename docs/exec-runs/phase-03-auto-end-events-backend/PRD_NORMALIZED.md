# PRD Normalizado — Phase 03: Auto-End Events After 24 Hours (Backend)

**Slug:** phase-03-auto-end-events-backend
**Plan fuente:** docs/plans/event-tracking-fixes/phases/phase-03-auto-end-events-after-24-hours-backend.md
**Timestamp:** 2026-07-01T01:51:38Z
**Nivel rg-exec:** full

---

## 1 Objetivo

Cerrar automáticamente rodadas en estado `IN_PROGRESS` cuya `startDate` sea mayor o igual a 24 horas en el pasado, mediante un cron horario en `NotificationSchedulerService` (api-gateway). Al cerrarse: (a) el estado en base de datos queda `FINISHED`, (b) los riders WS conectados reciben `tracking.event.ended` (triggereando el cleanup de Fase 1), y (c) todos los registrantes aprobados reciben notificación FCM. El método de cierre (`forceEndTracking`) es idempotente y nunca se expone por HTTP.

---

## 2 Por que

- Rodadas reales pueden quedar en `IN_PROGRESS` indefinidamente si el organizador no finaliza manualmente (crash de app, abandono, olvido). Esto contamina los listados de eventos activos y mantiene conexiones WS y GPS abiertas en clientes de forma innecesaria.
- Sin este mecanismo, el cleanup del lado cliente (Fase 1) nunca se dispara para esos casos extremos, dejando recursos abiertos en todos los dispositivos conectados.
- La ventana de 24 horas cubre cualquier rodada razonablemente larga, eliminando falsos positivos.

---

## 3 Alcance

### Entra

- **events-ms:** `findActiveEventsOlderThan(cutoffDate: Date)` en `EventsService` + `@MessagePattern('findActiveEventsOlderThan')` en `EventsController`.
- **events-ms:** `forceEndTracking(eventId: string)` idempotente en `EventsService` + `@MessagePattern('forceEndTracking')` en `EventsController` (comentario `// INTERNAL ONLY — no HTTP endpoint`). Sin owner check.
- **api-gateway:** nuevo `TrackingNotificationsService` (`@Injectable`) que extrae `sendEventEndedNotifications` de `TrackingHttpController`.
- **api-gateway:** `TrackingHttpController` refactorizado para inyectar y delegar en `TrackingNotificationsService`.
- **api-gateway:** `NotificationSchedulerService` con inyección de `TrackingNotificationsService` y `TrackingBroadcaster`; nuevo método `autoEndStalledEvents()` con `@Cron('0 * * * *', { timeZone: 'America/Bogota' })` y guard `_autoEndRunning: boolean`.
- **Módulos NestJS:** `tracking.module.ts` exporta `TrackingNotificationsService` y `TrackingBroadcaster`; `notification-scheduler.module.ts` importa `TrackingModule`.
- **Tests unitarios:** cron (happy path, sin eventos, idempotencia, error aislado, guard), `forceEndTracking` (IN_PROGRESS, FINISHED, CANCELLED), `findActiveEventsOlderThan` (filtro correcto).

### No entra

- Endpoint HTTP para `forceEndTracking`.
- Método `removeRoom` en `TrackingRoomsService` (ya manejado por `removeClient`).
- Lock distribuido para el cron (proceso single-instance; flag booleano suficiente en v1).
- Configuración de la ventana de 24h via env-var (valor fijo en v1).
- Cambios en la app Flutter (cubiertos en Fase 1).
- Migración de base de datos (campos `state` y `startDate` ya existen).
- Cambios en `rideglory-contracts` (los MessagePatterns son internos al canal TCP).

---

## 4 Areas afectadas

| Repo / Submódulo | Archivo | Tipo de cambio |
|---|---|---|
| `events-ms` | `src/events/events.service.ts` | Agrega `findActiveEventsOlderThan` y `forceEndTracking` |
| `events-ms` | `src/events/events.controller.ts` | Agrega dos `@MessagePattern` internos |
| `events-ms` | `src/events/events.service.spec.ts` | Agrega tests de los nuevos métodos |
| `api-gateway` | `src/tracking/tracking-notifications.service.ts` | Archivo nuevo: `TrackingNotificationsService` |
| `api-gateway` | `src/tracking/tracking-http.controller.ts` | Inyecta y delega en `TrackingNotificationsService` |
| `api-gateway` | `src/tracking/tracking.module.ts` | Agrega a `providers` y `exports` |
| `api-gateway` | `src/scheduler/notification-scheduler.module.ts` | Importa `TrackingModule` |
| `api-gateway` | `src/scheduler/notification-scheduler.service.ts` | Nuevas inyecciones, flag, y método cron |
| `api-gateway` | `src/scheduler/notification-scheduler-auto-end.service.spec.ts` | Archivo nuevo: tests del cron |

Sin cambios en Flutter ni en `rideglory-contracts`.

---

## 5 Criterios de aceptacion

1. Un evento con `state = IN_PROGRESS` y `startDate = ahora - 25h` es encontrado por `findActiveEventsOlderThan` y su estado cambia a `FINISHED` en base de datos en la siguiente ejecución del cron.
2. Un evento con `state = IN_PROGRESS` y `startDate = ahora - 23h` NO es cerrado por el cron (fuera de la ventana de 24h).
3. Un evento ya en `state = FINISHED` no recibe un UPDATE adicional si `forceEndTracking` es invocado nuevamente sobre él (idempotencia verificable via spy en tests o logs de Prisma).
4. Todos los registrantes con `status = APPROVED` del evento cerrado reciben una notificación FCM con `type = 'TRACKING_ENDED'` y el deeplink `rideglory://events/detail-by-id?id=<eventId>`.
5. Los riders WS conectados al evento reciben el mensaje `{ type: 'tracking.event.ended', data: { eventId } }` via `TrackingBroadcaster.broadcastEventEnded`.
6. Si un evento individual falla en `forceEndTracking` (ej: timeout RPC), el cron continúa procesando los demás eventos sin crashear; el error queda logueado.
7. Si el cron está en ejecución cuando se dispara el siguiente tick horario, la segunda ejecución retorna inmediatamente sin procesamiento (guard `_autoEndRunning`).
8. No existe ningún endpoint HTTP en `TrackingHttpController` que permita invocar `forceEndTracking` desde el exterior. El pattern solo existe en el canal TCP.
9. `TrackingHttpController.endTracking()` (endpoint `POST /api/events/:eventId/tracking/end`) sigue funcionando correctamente delegando las notificaciones FCM a `TrackingNotificationsService`.
10. `npm run test` y `npm run lint` pasan en verde en ambos submódulos (`events-ms` y `api-gateway`) sin nuevas violaciones.

---

## 6 Guardrails de regresion

- El endpoint `POST /api/events/:eventId/tracking/end` (manual) no debe verse alterado en comportamiento ni en firma. Solo su implementación interna delega a `TrackingNotificationsService`.
- `TrackingBroadcaster` ya existente no recibe cambios en su interfaz pública.
- `NotificationSchedulerService` ya existente mantiene sus demás métodos cron intactos (ej: notificaciones de SOAT/RTM).
- No se introducen nuevas dependencias circulares en NestJS; verificar con arranque del módulo.
- La query Prisma en `findActiveEventsOlderThan` filtra explícitamente `state = IN_PROGRESS`; valores `null` en `startDate` no satisfacen la condición `lte` (NULL-safe en Prisma).
- `forceEndTracking` verifica el estado antes de hacer UPDATE (doble protección junto con la query del cron).
- Fase 3 no debe desplegarse en producción sin que Fase 1 (Flutter WS cleanup) ya esté en producción.

---

## 7 Constraints heredados

- **Seguridad crítica:** `forceEndTracking` bypasea el owner check. El pattern `'forceEndTracking'` nunca puede quedar expuesto por HTTP. Comentario `// INTERNAL ONLY` obligatorio en `EventsController`. Revisión explícita en code review.
- **Orden de despliegue:** Fase 1 (Flutter) → Fase 3 (Backend). Sin Fase 1, el broadcast WS llega a riders que no cancelan GPS/WS.
- **Proceso single-instance:** el guard `_autoEndRunning` es suficiente para v1. No se introduce lock distribuido (Redis, etc.).
- **Ventana fija de 24h:** `Date.now() - 24 * 60 * 60_000`. No configurable via env-var en esta fase.
- **Sin migración de BD:** los campos `state` y `startDate` ya existen. No se agregan columnas ni índices.
- **Sin cambios en `rideglory-contracts`:** los nuevos MessagePatterns son internos al canal TCP entre `api-gateway` y `events-ms`; no requieren actualizar el paquete compartido.
- **Campo de corte:** `startDate` (cuándo arrancó la rodada según el organizador), nunca `createdAt` ni `updatedAt`.
- **Timeout RPC:** `timeout(10_000)` en llamadas al cron; `timeout(5_000)` en `TrackingNotificationsService`. Errores capturados por try/catch; el cron continúa con los demás eventos.
