> Slim handoff — read this before handoffs/architect.md

# QA handoff — Phase 03: Auto-End Events Backend

**Scope:** Backend-only. Sin cambios Flutter. Sin migraciones.

---

## Comandos de verificacion

```bash
# events-ms
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
npm run test
npm run lint

# api-gateway
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npm run test
npm run lint
```

Ambos deben pasar en verde sin nuevas violaciones.

---

## Criterios de aceptacion — trazabilidad

| CA | Descripcion | Cubierto por |
|----|-------------|-------------|
| 1 | Evento IN_PROGRESS con startDate = ahora-25h es encontrado y cerrado en el siguiente tick del cron | Test spec auto-end: happy path |
| 2 | Evento IN_PROGRESS con startDate = ahora-23h NO es cerrado | Test spec: `findActiveEventsOlderThan` filtro correcto |
| 3 | `forceEndTracking` sobre evento ya FINISHED no hace UPDATE adicional (idempotencia) | Test spec: idempotencia spy |
| 4 | Registrantes APPROVED reciben FCM con `type = 'TRACKING_ENDED'` y deeplink correcto | Test spec: happy path verifica `sendEventEndedNotifications` llamado; logica extraida a `TrackingNotificationsService` (ya testeada por el controlador existente) |
| 5 | Riders WS conectados reciben `tracking.event.ended` via `broadcastEventEnded` | Test spec: happy path verifica `broadcastEventEnded` llamado |
| 6 | Si un evento falla en `forceEndTracking`, el cron continua con los demas | Test spec: error aislado |
| 7 | Segunda ejecucion del cron retorna inmediatamente si la primera sigue corriendo (`_autoEndRunning` guard) | Test spec: guard test |
| 8 | No existe endpoint HTTP que exponga `forceEndTracking` | Code review: ningun `@Get`/`@Post`/`@Put`/`@Delete` en `EventsController` para `forceEndTracking`; MessagePattern solo en canal TCP |
| 9 | `POST /api/events/:eventId/tracking/end` sigue funcionando correctamente | Regresion: el endpoint existente ahora delega a `TrackingNotificationsService`; comportamiento externo igual |
| 10 | `npm run test` y `npm run lint` pasan en verde en ambos submódulos | CI / ejecucion manual |

---

## Archivos de test criticos

- `events-ms/src/events/events.service.spec.ts` — tests existentes deben seguir pasando; nuevos tests agregados para `findActiveEventsOlderThan` y `forceEndTracking`
- `api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` — archivo nuevo, 5 escenarios

---

## Riesgos de regresion a verificar manualmente

1. El metodo `endTracking` en `TrackingHttpController` debe seguir invocando FCM a registrantes (ahora via `TrackingNotificationsService`).
2. Los crons existentes de SOAT, RTM, maintenance y event-reminder deben seguir funcionando (sus metodos no cambian, solo el constructor del servicio tiene nuevas inyecciones).

> Full detail: handoffs/architect.md
