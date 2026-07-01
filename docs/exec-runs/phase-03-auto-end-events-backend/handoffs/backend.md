# Backend handoff — Phase 03: Auto-End Events Backend

**Fecha:** 2026-07-01T02:04:33Z  
**Última actualización:** 2026-07-01T03:31:39Z (Fix — aviso archivos fuera de alcance)  
**Agente:** Backend  
**Repos afectados:** `events-ms`, `api-gateway` (submódulos de rideglory-api)

---

## AVISO CRÍTICO — Archivos fuera del alcance de Phase 03 en events-ms

> **El humano DEBE excluir los siguientes archivos/directorios del commit de Phase 03 y commitearlos por separado**, en un commit propio (e.g. `feat(registrations): add medical consent and risk acceptance fields`).

El PRD §3 establece explícitamente **"Sin migración de BD"** para esta fase. Sin embargo, la working tree de `events-ms` contiene cambios de otro feature (consentimiento médico / aceptación de riesgo) que quedaron mezclados:

| Archivo / Directorio | Por qué está fuera de alcance |
|---|---|
| `prisma/migrations/20260701014208_add_medical_consent_risk_fields/migration.sql` | Migración que agrega campos de consentimiento médico y riesgo — no forma parte de Phase 03 |
| `prisma/schema.prisma` | Agrega `organizerAcceptedResponsibilityAt` a `Event` y `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion` a `EventRegistration` — out of scope |
| `src/registrations/registrations.service.ts` | Usa los campos anteriores — out of scope |

### Cómo hacer el commit correcto (git add selectivo)

```bash
cd /Users/cami/Developer/Personal/rideglory-api/events-ms

# Solo los archivos de Phase 03 (dentro de events-ms):
git add src/events/events.service.ts
git add src/events/events.controller.ts
git add src/events/events.service.spec.ts
git add src/events/events.service.iter3.spec.ts   # si fue modificado por Phase 03

# Commit de Phase 03:
git commit -m "feat(events): add findActiveEventsOlderThan and forceEndTracking for auto-end cron"

# Luego, en un commit separado, los archivos fuera de alcance:
git add prisma/migrations/20260701014208_add_medical_consent_risk_fields/
git add prisma/schema.prisma
git add src/registrations/registrations.service.ts
git commit -m "feat(registrations): add medical consent and risk acceptance fields"
```

> **NUNCA** hagas `git add .` o `git add -A` en events-ms en este momento — incluiría la migración no revisada en el commit de Phase 03.

---

---

## Baseline

### events-ms
- `events.service.spec.ts`: **3 de 6 tests fallaban** antes de mis cambios (TC-6, TC-7, TC-8 para `findUpcoming`). Los tests esperaban `state: { not: 'DRAFT' }` pero la implementación había sido actualizada a `state: { notIn: ['DRAFT', 'IN_PROGRESS', 'FINISHED'] }` en un PR anterior — drift de tests, no un bug mío.
- Acción: corregí los 3 tests fallidos para que reflejen el comportamiento actual correcto y luego agregué los nuevos tests.

### api-gateway
- `notification-scheduler.service.spec.ts`: **34 tests pasaban** — baseline limpio.

---

## Archivos cambiados

### events-ms

| Archivo | Tipo | Cambio |
|---------|------|--------|
| `src/events/events.service.ts` | MODIFY | Agrega `findActiveEventsOlderThan(cutoffDate)` e `forceEndTracking(eventId)` al final de `EventsService` |
| `src/events/events.controller.ts` | MODIFY | Agrega `@MessagePattern('findActiveEventsOlderThan')` y `@MessagePattern('forceEndTracking')` con comentario `// INTERNAL ONLY` |
| `src/events/events.service.spec.ts` | MODIFY | Corrige TC-6/TC-7/TC-8 (drift); agrega describe blocks para `findActiveEventsOlderThan` (3 tests) y `forceEndTracking` (3 tests) |

### api-gateway

| Archivo | Tipo | Cambio |
|---------|------|--------|
| `src/tracking/tracking-notifications.service.ts` | CREATE | Nuevo servicio injectable que extrae `sendEventEndedNotifications` del controller |
| `src/tracking/tracking-http.controller.ts` | MODIFY | Inyecta `TrackingNotificationsService`; delega FCM a él; elimina método privado `sendEventEndedNotifications`; elimina `NotificationsService` del constructor |
| `src/tracking/tracking.module.ts` | MODIFY | Agrega `TrackingNotificationsService` a providers; agrega `exports: [TrackingNotificationsService, TrackingBroadcaster]` |
| `src/scheduler/notification-scheduler.module.ts` | MODIFY | Importa `TrackingModule` para exponer `TrackingNotificationsService` y `TrackingBroadcaster` |
| `src/scheduler/notification-scheduler.service.ts` | MODIFY | Inyecta `TrackingNotificationsService` y `TrackingBroadcaster`; agrega `_autoEndRunning` boolean guard; agrega `@Cron('0 * * * *') autoEndStalledEvents()` con 24h cutoff, aislamiento por evento, y finally-reset del guard |
| `src/scheduler/notification-scheduler-auto-end.service.spec.ts` | CREATE | 8 tests: happy path, sin eventos, aislamiento de errores, guard de concurrencia (3 variantes), smoke test de existencia |

---

## Pruebas nuevas

### events-ms — `events.service.spec.ts`
- **TC-6 (corregido):** `findUpcoming` sin filtros usa medianoche UTC hoy como baseline; estado excluye `DRAFT/IN_PROGRESS/FINISHED`
- **TC-7 (corregido):** `findUpcoming` con filtro de tipo; estado excluye los 3 estados correctamente
- **TC-8 (corregido):** `findUpcoming` con `dateFrom` override; estado correcto
- **findActiveEventsOlderThan:** filtra solo `IN_PROGRESS` con `startDate lte cutoff`; retorna vacío cuando no hay; estado es estrictamente `IN_PROGRESS`
- **forceEndTracking:** transiciona `IN_PROGRESS → FINISHED` y retorna estado actualizado; idempotente (no llama UPDATE si ya es `FINISHED`); retorna `UNKNOWN` si el evento no existe

### api-gateway — `notification-scheduler-auto-end.service.spec.ts`
- **Happy path:** 1 evento → llama `forceEndTracking`, `broadcastEventEnded`, `sendEventEndedNotifications`
- **Cutoff 24h:** verifica que `cutoffDate` sea aproximadamente `Date.now() - 24h`
- **Sin eventos:** no llama `forceEndTracking` ni broadcast cuando la lista está vacía
- **Aislamiento de errores:** si evento 1 falla en `forceEndTracking`, evento 2 se procesa correctamente
- **Guard - bloqueo:** si `_autoEndRunning = true`, sale inmediatamente con `logger.warn`
- **Guard - reset éxito:** `_autoEndRunning` vuelve a `false` tras run exitoso
- **Guard - reset error:** `_autoEndRunning` vuelve a `false` incluso cuando falla el fetch de eventos

---

## Resultado final

| Repo | Suite | Antes | Después |
|------|-------|-------|---------|
| events-ms | `events.service.spec` | 3 fail / 6 total | **12 pass / 12 total** |
| api-gateway | `notification-scheduler` | 34 pass / 34 total | **42 pass / 42 total** |

**Total nuevos tests:** 3 correcciones + 3 nuevos en events-ms + 8 nuevos en api-gateway = **14 cambios de test**

---

## Verificación manual

```bash
# events-ms
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
npx jest events.service.spec
# → 12 passed

# api-gateway
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npx jest notification-scheduler
# → 42 passed (34 pre-existing + 8 nuevos)
```

El cron `autoEndStalledEvents` corre cada hora (`0 * * * *`, America/Bogota). Para verificación manual en staging:
1. Crear un evento y ponerlo en `IN_PROGRESS` vía `POST /api/events/:id/tracking/start`
2. Modificar `startDate` en BD a más de 24h en el pasado
3. Esperar el próximo tick del cron (o invocar `service.autoEndStalledEvents()` directamente en un test e2e)
4. Verificar que el evento quede en estado `FINISHED` y que los riders aprobados reciban FCM

---

## Notas Frontend/QA

- **Sin cambios de API pública**: los 2 nuevos endpoints TCP (`findActiveEventsOlderThan`, `forceEndTracking`) son **INTERNAL ONLY** — solo accesibles vía TCP desde el api-gateway, nunca expuestos como HTTP. La app Flutter no necesita cambios.
- **Idempotencia garantizada**: si el cron corre múltiples veces (raro, gracias al guard), solo el primer run en un tick procesará eventos; los siguientes ticks encontrarán los eventos ya `FINISHED` y `forceEndTracking` los devolverá sin UPDATE.
- **Error handling**: si `forceEndTracking` falla para un evento, el cron continúa con los demás (aislamiento por evento). Los errores se loggean como `AUTO_END: failed for event {id}: {err}`.
- **FCM best-effort**: las notificaciones push a riders son disparadas con `void .catch(() => undefined)` — no bloquean el cierre del evento ni propagan errores.
- **QA:** la forma más directa de probar el flujo end-to-end es via tests e2e (Patrol) o arrancando el backend en local, manipulando la BD, y verificando logs del scheduler.
