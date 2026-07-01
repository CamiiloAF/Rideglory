# REVIEW CHECKLIST — Phase 03: Auto-End Events Backend

**Timestamp:** 2026-07-01T03:35:03Z

Pasos manuales antes de commitear. Completar en orden.

---

## 1. Fix obligatorio — BUG-01 (antes de cualquier commit)

**Archivo:** `rideglory-api/api-gateway/src/tracking/tracking-http.controller.ts`

El método `endTracking` cambió su autenticación fuera de scope. Revertir al patrón de `startTracking`:

```typescript
// ANTES del cambio (patrón correcto — consistente con startTracking):
async endTracking(...) {
  const authUserId = request.user?.uid;
  if (!authUserId) {
    throw new UnauthorizedException();
  }
  // ... usa authUserId directamente
}
```

Después de revertir, re-ejecutar:
```bash
cd rideglory-api/api-gateway
npx jest tracking-http.controller
```
Los tests de AC9 deberán actualizarse para reflejar el auth revertido (eliminar los tests de `findUserByEmail` y `email` path, ajustar el happy path a `uid`).

---

## 2. Commit selectivo en events-ms

Los siguientes archivos NO son de Phase 03 y deben commitearse **por separado** ANTES del commit de Phase 03:

```bash
cd /Users/cami/Developer/Personal/rideglory-api/events-ms

# Commit del feature separado:
git add prisma/migrations/20260701014208_add_medical_consent_risk_fields/
git add prisma/schema.prisma
git add src/registrations/registrations.service.ts
git commit -m "feat(registrations): add medical consent and risk acceptance fields"

# Luego el commit de Phase 03:
git add src/events/events.service.ts
git add src/events/events.controller.ts
git add src/events/events.service.spec.ts
git commit -m "feat(events): add findActiveEventsOlderThan and forceEndTracking for auto-end cron"
```

---

## 3. Verificar tests en verde

```bash
# events-ms
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
npx jest events.service.spec
# → 13 passed

# api-gateway
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npx jest notification-scheduler tracking-notifications tracking-http.controller
# → 53+ passed
```

---

## 4. Verificar que forceEndTracking NO tiene endpoint HTTP

En `events-ms/src/events/events.controller.ts`:
- [ ] `@MessagePattern('forceEndTracking')` está presente con `// INTERNAL ONLY — no HTTP endpoint`
- [ ] No existe ningún `@Get`, `@Post`, `@Put`, `@Delete` para `forceEndTracking`

En `api-gateway/src/tracking/tracking-http.controller.ts`:
- [ ] No existe ningún endpoint HTTP que llame `forceEndTracking`
- [ ] El único acceso es via `eventsService.send('forceEndTracking', ...)` en `notification-scheduler.service.ts`

---

## 5. Verificar cron y módulo

En `api-gateway/src/scheduler/notification-scheduler.service.ts`:
- [ ] `@Cron('0 * * * *', { timeZone: 'America/Bogota' })` sobre `autoEndStalledEvents`
- [ ] Guard `_autoEndRunning` está en el `if` al inicio y en el `finally`
- [ ] Cada evento en un `try/catch` separado (aislamiento)
- [ ] `void trackingNotificationsService.sendEventEndedNotifications(...).catch(() => undefined)` (best-effort FCM)

En `api-gateway/src/scheduler/notification-scheduler.module.ts`:
- [ ] `TrackingModule` está en `imports`

En `api-gateway/src/tracking/tracking.module.ts`:
- [ ] `exports: [TrackingNotificationsService, TrackingBroadcaster]`

---

## 6. Verificar orden de despliegue

- [ ] Confirmar que Phase 01 (Flutter WS cleanup — `fix(tracking): cleanup completo de GPS y WS al recibir tracking.event.ended`) está commiteado y en producción ANTES de desplegar Phase 03 backend.

---

## 7. Prueba manual en staging (post-deploy)

1. Crear un evento y ponerlo en `IN_PROGRESS` via `POST /api/events/:id/tracking/start`
2. Modificar `startDate` en BD a `NOW() - INTERVAL '25 hours'`
3. Esperar siguiente tick del cron (o invocar `service.autoEndStalledEvents()` directamente en un test e2e)
4. Verificar:
   - [ ] Evento en estado `FINISHED` en BD
   - [ ] Log `AUTO_END: closed event <id>`
   - [ ] Riders WS conectados reciben `{ type: 'tracking.event.ended', data: { eventId } }`
   - [ ] Registrantes APPROVED reciben notificación FCM con `type: TRACKING_ENDED` y deeplink `rideglory://events/detail-by-id?id=<eventId>`
5. Repetir paso 3 (idempotencia): el evento ya en `FINISHED` no recibe UPDATE adicional

---

## 8. Commit api-gateway (después de fix BUG-01)

```bash
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
git add src/tracking/tracking-notifications.service.ts
git add src/tracking/tracking-notifications.service.spec.ts
git add src/tracking/tracking-http.controller.ts
git add src/tracking/tracking-http.controller.spec.ts
git add src/tracking/tracking.module.ts
git add src/scheduler/notification-scheduler.module.ts
git add src/scheduler/notification-scheduler.service.ts
git add src/scheduler/notification-scheduler-auto-end.service.spec.ts
git commit -m "feat(scheduler): auto-end stalled IN_PROGRESS events after 24h"
```
