> Slim handoff — read this before handoffs/architect.md

# Backend handoff — Phase 03: Auto-End Events Backend

**Repos afectados:** `events-ms` y `api-gateway` (submódulos de rideglory-api)
**Sin migraciones de BD. Sin nuevas env-vars.**

---

## events-ms — 3 archivos

### 1. `src/events/events.service.ts` — MODIFY

Agrega dos métodos al final de `EventsService` (después de `findEventsNeedingReminder`):

```typescript
async findActiveEventsOlderThan(cutoffDate: Date): Promise<Array<{ id: string }>> {
  return this.event.findMany({
    where: {
      state: EventState.IN_PROGRESS,
      startDate: { lte: cutoffDate },
    },
    select: { id: true },
  });
}

async forceEndTracking(eventId: string): Promise<{ id: string; state: string }> {
  const event = await this.event.findUnique({ where: { id: eventId } });
  if (!event || event.state !== EventState.IN_PROGRESS) {
    return { id: eventId, state: event?.state ?? 'UNKNOWN' };
  }
  const updated = await this.event.update({
    where: { id: eventId },
    data: { state: EventState.FINISHED },
  });
  return { id: updated.id, state: updated.state };
}
```

- `forceEndTracking` NO tiene owner check (INTERNAL ONLY).
- NULL en `startDate` es excluido automáticamente por Prisma `lte`.

### 2. `src/events/events.controller.ts` — MODIFY

Agrega al final de `EventsController`, con comentario obligatorio:

```typescript
// INTERNAL ONLY — no HTTP endpoint
@MessagePattern('findActiveEventsOlderThan')
findActiveEventsOlderThan(@Payload() payload: { cutoffDate: string }) {
  return this.eventsService.findActiveEventsOlderThan(new Date(payload.cutoffDate));
}

// INTERNAL ONLY — no HTTP endpoint
@MessagePattern('forceEndTracking')
forceEndTracking(@Payload() payload: { eventId: string }) {
  return this.eventsService.forceEndTracking(payload.eventId);
}
```

### 3. `src/events/events.service.spec.ts` — MODIFY

Agrega describe blocks para `findActiveEventsOlderThan` (filtro correcto, no retorna FINISHED) y `forceEndTracking` (IN_PROGRESS→FINISHED, FINISHED→no-op, no UPDATE extra). Ver `events.service.spec.ts` existente para el patrón de mocking de Prisma.

---

## api-gateway — 6 archivos

### 4. `src/tracking/tracking-notifications.service.ts` — CREATE (nuevo archivo)

```typescript
import { Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { firstValueFrom } from 'rxjs';
import { timeout } from 'rxjs/operators';
import { EVENTS_SERVICE, USERS_SERVICE } from '../config/services';
import { NotificationsService } from '../notifications/notifications.service';

type UserResult = { id: string; fcmToken?: string | null };
const RPC_TIMEOUT_MS = 5_000;

@Injectable()
export class TrackingNotificationsService {
  constructor(
    @Inject(EVENTS_SERVICE) private readonly eventsService: ClientProxy,
    @Inject(USERS_SERVICE) private readonly usersService: ClientProxy,
    private readonly notificationsService: NotificationsService,
  ) {}

  async sendEventEndedNotifications(eventId: string): Promise<void> {
    const userIds = await firstValueFrom<string[]>(
      this.eventsService
        .send('getApprovedRegistrantUserIds', { eventId })
        .pipe(timeout(RPC_TIMEOUT_MS)),
    );
    for (const userId of userIds) {
      try {
        const user = await firstValueFrom<UserResult>(
          this.usersService.send('findOneUser', { id: userId }).pipe(timeout(RPC_TIMEOUT_MS)),
        );
        if (user.fcmToken) {
          await this.notificationsService.sendFcm(
            user.fcmToken,
            'La rodada ha terminado',
            'El organizador ha finalizado la rodada',
            { type: 'TRACKING_ENDED', eventId, route: `rideglory://events/detail-by-id?id=${eventId}` },
          );
        }
      } catch {
        // Non-fatal — continue with other users
      }
    }
  }
}
```

### 5. `src/tracking/tracking-http.controller.ts` — MODIFY

- Importar `TrackingNotificationsService`.
- Agregar al constructor: `private readonly trackingNotificationsService: TrackingNotificationsService`.
- En `endTracking()`: reemplazar `void this.sendEventEndedNotifications(eventId).catch(...)` por `void this.trackingNotificationsService.sendEventEndedNotifications(eventId).catch(() => undefined)`.
- Eliminar el método privado `sendEventEndedNotifications` (ya no necesario).

### 6. `src/tracking/tracking.module.ts` — MODIFY

```typescript
// Agregar a providers:
TrackingNotificationsService,

// Agregar exports array (no existe actualmente):
exports: [TrackingNotificationsService, TrackingBroadcaster],
```

Importar `TrackingNotificationsService` en el archivo.

### 7. `src/scheduler/notification-scheduler.module.ts` — MODIFY

```typescript
// Agregar a imports:
import { TrackingModule } from '../tracking/tracking.module';

// En @Module imports array, agregar:
TrackingModule,
```

### 8. `src/scheduler/notification-scheduler.service.ts` — MODIFY

```typescript
// Nuevas importaciones:
import { TrackingNotificationsService } from '../tracking/tracking-notifications.service';
import { TrackingBroadcaster } from '../tracking/tracking-broadcaster.service';

// Constructor — agregar:
private readonly trackingNotificationsService: TrackingNotificationsService,
private readonly trackingBroadcaster: TrackingBroadcaster,

// Propiedad de clase:
private _autoEndRunning = false;

// Nuevo método cron:
/** Every hour on the hour — auto-end events stalled in IN_PROGRESS for 24+ hours */
@Cron('0 * * * *', { timeZone: 'America/Bogota' })
async autoEndStalledEvents(): Promise<void> {
  if (this._autoEndRunning) {
    this.logger.warn('AUTO_END: previous run still in progress — skipping');
    return;
  }
  this._autoEndRunning = true;
  try {
    const cutoffDate = new Date(Date.now() - 24 * 60 * 60_000);
    let events: Array<{ id: string }>;
    try {
      events = await firstValueFrom<Array<{ id: string }>>(
        this.eventsService
          .send('findActiveEventsOlderThan', { cutoffDate: cutoffDate.toISOString() })
          .pipe(timeout(10_000)),
      );
    } catch (err: unknown) {
      this.logger.error(`AUTO_END: failed to fetch stalled events: ${String(err)}`);
      return;
    }

    if (events.length === 0) {
      return;
    }
    this.logger.log(`AUTO_END: found ${events.length} stalled event(s)`);

    for (const event of events) {
      try {
        await firstValueFrom(
          this.eventsService
            .send('forceEndTracking', { eventId: event.id })
            .pipe(timeout(10_000)),
        );
        this.trackingBroadcaster.broadcastEventEnded(event.id);
        void this.trackingNotificationsService
          .sendEventEndedNotifications(event.id)
          .catch(() => undefined);
        this.logger.log(`AUTO_END: closed event ${event.id}`);
      } catch (err: unknown) {
        this.logger.error(`AUTO_END: failed for event ${event.id}: ${String(err)}`);
      }
    }
  } finally {
    this._autoEndRunning = false;
  }
}
```

### 9. `src/scheduler/notification-scheduler-auto-end.service.spec.ts` — CREATE

Tests requeridos (ver patrón de `notification-scheduler.service.spec.ts` existente):
- Happy path: 1 evento encontrado → `forceEndTracking` llamado, `broadcastEventEnded` llamado, `sendEventEndedNotifications` llamado
- Sin eventos: retorno inmediato, sin RPC adicionales
- Idempotencia: 1 evento ya en FINISHED → `forceEndTracking` retorna sin UPDATE (spy en Prisma)
- Error aislado: si evento 1 falla en `forceEndTracking`, evento 2 se procesa igualmente
- Guard: si `_autoEndRunning = true` cuando llega el tick, retorna inmediatamente

---

## Verificación final

```bash
# events-ms
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
npm run test -- --testPathPattern=events.service.spec
npm run lint

# api-gateway
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npm run test -- --testPathPattern=notification-scheduler-auto-end
npm run lint
```

> Full detail: handoffs/architect.md
