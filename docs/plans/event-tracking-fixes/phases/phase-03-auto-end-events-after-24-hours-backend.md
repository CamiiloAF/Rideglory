# Fase 3 — Auto-End Events After 24 Hours (Backend)

**Slug:** event-tracking-fixes
**Timestamp:** 2026-06-20T00:21:55Z
**Nivel rg-exec:** full
**Depende de:** Fase 1 (WS Cleanup on Event End)

---

## Objetivo

Rodadas en estado `IN_PROGRESS` cuya `startDate` sea menor o igual a `ahora - 24 horas` son cerradas automáticamente por un cron horario en `NotificationSchedulerService` (api-gateway). Al cerrarse, los riders conectados al WS reciben `tracking.event.ended` (triggereando el cleanup de Fase 1), todos los registrantes aprobados reciben notificación FCM, y el estado en base de datos queda `FINISHED`. El método que ejecuta el cierre (`forceEndTracking`) es idempotente y no expone endpoint HTTP.

---

## Alcance (entra / no entra)

### Entra

- **events-ms:** nuevo método `findActiveEventsOlderThan(cutoffDate: Date)` en `EventsService` + `MessagePattern` `'findActiveEventsOlderThan'` en `EventsController`.
- **events-ms:** nuevo método `forceEndTracking(eventId: string)` idempotente en `EventsService` + `MessagePattern` `'forceEndTracking'` en `EventsController`, con comentario `// INTERNAL ONLY — no HTTP endpoint`. Sin owner check.
- **api-gateway:** nuevo `TrackingNotificationsService` (`@Injectable`) que extrae `sendEventEndedNotifications` de `TrackingHttpController`. Firma: `async sendEventEndedNotifications(eventId: string): Promise<void>`.
- **api-gateway:** `TrackingHttpController` se refactoriza para inyectar `TrackingNotificationsService` y delegar en él (elimina el método privado inline).
- **api-gateway:** `NotificationSchedulerService` recibe inyección de `TrackingNotificationsService`, `TrackingBroadcaster`, y `EVENTS_SERVICE` (ClientProxy ya inyectado). Nuevo método `autoEndStalledEvents()` decorado con `@Cron('0 * * * *', { timeZone: 'America/Bogota' })`.
- **api-gateway:** guard de concurrencia mediante flag `_autoEndRunning: boolean` en la instancia de `NotificationSchedulerService`.
- **Módulos:** `notification-scheduler.module.ts` importa `TrackingModule` (o exporta `TrackingNotificationsService` vía módulo propio); `tracking.module.ts` exporta `TrackingBroadcaster` y `TrackingNotificationsService`.
- **Tests unitarios:** cron con todos los colaboradores mockeados; idempotencia de `forceEndTracking`; guard de concurrencia.

### No entra

- Endpoint HTTP para `forceEndTracking` — prohibido explícitamente.
- Método `removeRoom` en `TrackingRoomsService` — `removeClient` ya auto-limpia rooms vacíos al tamaño cero (línea 23-24 de `tracking-rooms.service.ts`); no se necesita.
- Lock distribuido para el cron — proceso single-instance; `_autoEndRunning` es suficiente para v1.
- Configuración de la ventana de 24 horas vía env-var — valor fijo para v1.
- Cambios en la app Flutter — cubiertos en Fase 1.
- Migración de base de datos — no hay nuevas columnas ni índices.
- Cambios en `rideglory-contracts` — los nuevos MessagePatterns son internos al TCP entre api-gateway y events-ms; no requieren actualizar el paquete de contratos compartidos.

---

## Que se debe hacer (pasos concretos y ordenados)

### 1. events-ms — `EventsService`: agregar `findActiveEventsOlderThan`

En `events-ms/src/events/events.service.ts`, agregar al final de la clase:

```typescript
async findActiveEventsOlderThan(
  cutoffDate: Date,
): Promise<{ id: string; name: string }[]> {
  return this.event.findMany({
    where: {
      state: EventState.IN_PROGRESS,
      startDate: { lte: cutoffDate },
    },
    select: { id: true, name: true },
  });
}
```

**Nota:** usar `startDate` (cuándo arrancó la rodada según el organizador), nunca `createdAt` ni `updatedAt`.

### 2. events-ms — `EventsService`: agregar `forceEndTracking`

En `events-ms/src/events/events.service.ts`, agregar inmediatamente después del paso anterior:

```typescript
// INTERNAL ONLY — invocado por el cron de api-gateway via RPC.
// No existe endpoint HTTP para este método. No realizar owner check.
async forceEndTracking(
  eventId: string,
): Promise<{ id: string; state: string }> {
  const event = await this.findOne(eventId);
  if (event.state !== EventState.IN_PROGRESS) {
    // Idempotente: si ya está FINISHED (o cualquier otro estado), retornar sin error.
    return { id: event.id, state: event.state };
  }
  const updated = await this.event.update({
    where: { id: eventId },
    data: { state: EventState.FINISHED },
    select: { id: true, state: true },
  });
  return updated;
}
```

### 3. events-ms — `EventsController`: agregar los dos nuevos `MessagePattern`

En `events-ms/src/events/events.controller.ts`, agregar al final del controlador:

```typescript
@MessagePattern('findActiveEventsOlderThan')
findActiveEventsOlderThan(
  @Payload() payload: { cutoffDate: string },
) {
  return this.eventsService.findActiveEventsOlderThan(
    new Date(payload.cutoffDate),
  );
}

// INTERNAL ONLY — no HTTP endpoint exists for this pattern.
@MessagePattern('forceEndTracking')
forceEndTracking(@Payload() payload: { eventId: string }) {
  return this.eventsService.forceEndTracking(payload.eventId);
}
```

### 4. api-gateway — crear `TrackingNotificationsService`

Crear nuevo archivo `api-gateway/src/tracking/tracking-notifications.service.ts`:

```typescript
import { Injectable, Inject } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { firstValueFrom, timeout } from 'rxjs';
import { NotificationsService } from '../notifications/notifications.service';
import { EVENTS_SERVICE, USERS_SERVICE } from '../config/services';

const RPC_TIMEOUT_MS = 5_000;

interface UserResult {
  id: string;
  fcmToken?: string;
}

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
            {
              type: 'TRACKING_ENDED',
              eventId,
              route: `rideglory://events/detail-by-id?id=${eventId}`,
            },
          );
        }
      } catch {
        // Non-fatal — continue with other users
      }
    }
  }
}
```

### 5. api-gateway — refactorizar `TrackingHttpController`

En `api-gateway/src/tracking/tracking-http.controller.ts`:
- Agregar inyección de `TrackingNotificationsService` al constructor.
- Reemplazar el cuerpo del método privado `sendEventEndedNotifications` por una delegación: `return this.trackingNotificationsService.sendEventEndedNotifications(eventId);`
- El método privado puede quedar como wrapper o eliminarse si la llamada inline ya es clara.

### 6. api-gateway — actualizar `tracking.module.ts`

En `api-gateway/src/tracking/tracking.module.ts`:
- Agregar `TrackingNotificationsService` a `providers`.
- Agregar `TrackingNotificationsService` y `TrackingBroadcaster` a `exports` para que `NotificationSchedulerModule` los pueda importar.

### 7. api-gateway — actualizar `notification-scheduler.module.ts`

En `api-gateway/src/scheduler/notification-scheduler.module.ts`:
- Importar `TrackingModule` (que exporta `TrackingNotificationsService` y `TrackingBroadcaster`).
- Esto provee al scheduler acceso a ambos servicios sin duplicar la configuración de `ClientsModule`.

### 8. api-gateway — agregar `autoEndStalledEvents` en `NotificationSchedulerService`

En `api-gateway/src/scheduler/notification-scheduler.service.ts`:

- Inyectar `TrackingNotificationsService` y `TrackingBroadcaster` en el constructor.
- Agregar el flag de concurrencia como propiedad privada: `private _autoEndRunning = false;`
- Agregar el nuevo método:

```typescript
@Cron('0 * * * *', { timeZone: 'America/Bogota' })
async autoEndStalledEvents(): Promise<void> {
  if (this._autoEndRunning) {
    this.logger.warn('autoEndStalledEvents: run still in progress, skipping.');
    return;
  }
  this._autoEndRunning = true;
  try {
    const cutoff = new Date(Date.now() - 24 * 60 * 60_000);
    const stalledEvents = await firstValueFrom<{ id: string; name: string }[]>(
      this.eventsClient
        .send('findActiveEventsOlderThan', { cutoffDate: cutoff.toISOString() })
        .pipe(timeout(10_000)),
    );

    this.logger.log(
      `autoEndStalledEvents: found ${stalledEvents.length} stalled event(s).`,
    );

    for (const event of stalledEvents) {
      try {
        await firstValueFrom(
          this.eventsClient
            .send('forceEndTracking', { eventId: event.id })
            .pipe(timeout(10_000)),
        );
        this.trackingBroadcaster.broadcastEventEnded(event.id);
        void this.trackingNotificationsService
          .sendEventEndedNotifications(event.id)
          .catch((err: unknown) =>
            this.logger.error(
              `autoEndStalledEvents: FCM failed for event ${event.id}: ${String(err)}`,
            ),
          );
        this.logger.log(
          `autoEndStalledEvents: closed event "${event.name}" (${event.id}).`,
        );
      } catch (err) {
        this.logger.error(
          `autoEndStalledEvents: failed to close event ${event.id}: ${String(err)}`,
        );
      }
    }
  } finally {
    this._autoEndRunning = false;
  }
}
```

**Nota:** `this.eventsClient` es el `ClientProxy` de `EVENTS_SERVICE` ya inyectado en el servicio. Verificar el nombre exacto de la propiedad en el constructor actual y usar el mismo.

### 9. Tests unitarios

Crear `api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` (o agregar describe-block en el spec existente si es corto). Cubrir:
- Happy path: 2 eventos encontrados, `forceEndTracking` llamado 2 veces, `broadcastEventEnded` 2 veces, FCM 2 veces.
- Idempotencia: `forceEndTracking` con evento ya `FINISHED` devuelve `{ state: 'FINISHED' }` sin error; el cron continúa sin crash.
- Guard de concurrencia: si `_autoEndRunning` es `true` al inicio, el método retorna inmediatamente y ningún colaborador es llamado.
- Error aislado: si `forceEndTracking` falla para un evento, el cron continúa con el siguiente evento (no lanza; el error se loguea).

Crear o actualizar `events-ms/src/events/events.service.spec.ts` agregando:
- `forceEndTracking` con evento `IN_PROGRESS` → devuelve `{ id, state: 'FINISHED' }` y ejecuta UPDATE en Prisma.
- `forceEndTracking` con evento ya `FINISHED` → devuelve `{ id, state: 'FINISHED' }` sin ejecutar UPDATE.
- `findActiveEventsOlderThan` → filtra correctamente por `state === IN_PROGRESS` y `startDate <= cutoffDate`.

### 10. Verificación final

```bash
# En events-ms
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
npm run test

# En api-gateway
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npm run test

# Lint
npm run lint
```

---

## Archivos a crear/modificar (rutas reales)

| Accion | Ruta | Que cambia |
|--------|------|------------|
| Modificar | `events-ms/src/events/events.service.ts` | Agrega `findActiveEventsOlderThan(cutoffDate)` y `forceEndTracking(eventId)` idempotente sin owner check |
| Modificar | `events-ms/src/events/events.controller.ts` | Agrega `@MessagePattern('findActiveEventsOlderThan')` y `@MessagePattern('forceEndTracking')` con comentario INTERNAL ONLY |
| Crear | `api-gateway/src/tracking/tracking-notifications.service.ts` | Nuevo `@Injectable` que encapsula la lógica de FCM post-evento-terminado; extraída de `TrackingHttpController` |
| Modificar | `api-gateway/src/tracking/tracking-http.controller.ts` | Inyecta `TrackingNotificationsService`; reemplaza método privado `sendEventEndedNotifications` por delegación |
| Modificar | `api-gateway/src/tracking/tracking.module.ts` | Agrega `TrackingNotificationsService` a `providers` y a `exports`; exporta también `TrackingBroadcaster` |
| Modificar | `api-gateway/src/scheduler/notification-scheduler.module.ts` | Importa `TrackingModule` para acceder a `TrackingNotificationsService` y `TrackingBroadcaster` |
| Modificar | `api-gateway/src/scheduler/notification-scheduler.service.ts` | Inyecta `TrackingNotificationsService` y `TrackingBroadcaster`; agrega flag `_autoEndRunning` y método `autoEndStalledEvents()` con `@Cron('0 * * * *')` |
| Crear | `api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` | Tests unitarios del cron: happy path, idempotencia, guard, error aislado por evento |
| Modificar | `events-ms/src/events/events.service.spec.ts` | Agrega tests de `forceEndTracking` (normal + idempotente) y `findActiveEventsOlderThan` |

---

## Contratos / API rideglory-api

### Nuevos MessagePatterns TCP internos (events-ms ← api-gateway)

Estos patrones solo existen en el canal TCP entre microservicios. No tienen ruta HTTP asociada.

| MessagePattern | Payload | Response | Notas |
|---|---|---|---|
| `'findActiveEventsOlderThan'` | `{ cutoffDate: string }` (ISO 8601) | `{ id: string; name: string }[]` | Solo devuelve eventos `IN_PROGRESS` con `startDate <= cutoffDate`; usa campo `startDate`, no `createdAt` |
| `'forceEndTracking'` | `{ eventId: string }` | `{ id: string; state: string }` | Idempotente: si el evento ya no es `IN_PROGRESS`, retorna el estado actual sin modificar; sin owner check; comentario `// INTERNAL ONLY` en el controller |

### Sin cambios en contratos HTTP

Ningún endpoint HTTP nuevo en `TrackingHttpController` ni en `EventsController` HTTP. `rideglory-contracts` no se modifica.

---

## Cambios de datos / migraciones

**Ninguno.** No se agregan columnas, índices ni seeds. Los campos `state` y `startDate` ya existen en la tabla `events`. Prisma no requiere migración.

---

## Criterios de aceptacion

1. Un evento con `state = IN_PROGRESS` y `startDate = ahora - 25h` es encontrado por `findActiveEventsOlderThan` y su estado cambia a `FINISHED` en base de datos en la siguiente ejecución del cron.
2. Un evento con `state = IN_PROGRESS` y `startDate = ahora - 23h` NO es cerrado por el cron (fuera de ventana de 24h).
3. Un evento ya en `state = FINISHED` no recibe un UPDATE adicional si `forceEndTracking` es invocado nuevamente sobre él (idempotencia verificable via logs de Prisma o spy en tests).
4. Todos los registrantes con `status = APPROVED` del evento cerrado reciben una notificación FCM con `type = 'TRACKING_ENDED'` y el deeplink correcto.
5. Los riders WS conectados al evento reciben el mensaje `{ type: 'tracking.event.ended', data: { eventId } }` via broadcast.
6. Si un evento individual falla en `forceEndTracking` (ej: timeout RPC), el cron continúa procesando los demás eventos sin crashear.
7. Si el cron está en ejecución cuando se dispara el siguiente tick horario, la segunda ejecución retorna inmediatamente sin procesamiento (guard `_autoEndRunning`).
8. No existe ningún endpoint HTTP en `TrackingHttpController` que permita invocar `forceEndTracking` desde el exterior.
9. `TrackingHttpController.endTracking()` (endpoint `POST /api/events/:eventId/tracking/end`) sigue funcionando correctamente delegando las notificaciones FCM a `TrackingNotificationsService`.
10. `npm run test` y `npm run lint` pasan en verde en ambos submódulos (`events-ms` y `api-gateway`) sin nuevas violaciones.

---

## Pruebas

### Unitarias (api-gateway — `NotificationSchedulerService`)

Archivo: `api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts`

| Caso | Descripcion | Assertion clave |
|------|-------------|-----------------|
| Happy path 2 eventos | `findActiveEventsOlderThan` devuelve 2 eventos; ambos son cerrados y notificados | `forceEndTracking` llamado 2 veces; `broadcastEventEnded` llamado 2 veces; FCM llamado 2 veces |
| Sin eventos | `findActiveEventsOlderThan` devuelve `[]` | Ningún colaborador downstream es invocado; no hay error |
| Idempotencia | `forceEndTracking` devuelve `{ state: 'FINISHED' }` (evento ya cerrado) | No crash; broadcast y FCM igual se intentan (el evento puede tener riders aún conectados) |
| Error en un evento | `forceEndTracking` lanza para el primer evento | El segundo evento se procesa igualmente; el error del primero queda logueado |
| Guard concurrencia | Llamar `autoEndStalledEvents()` mientras `_autoEndRunning = true` | El método retorna sin invocar `findActiveEventsOlderThan` ni ningún colaborador |

### Unitarias (events-ms — `EventsService`)

Archivo: `events-ms/src/events/events.service.spec.ts`

| Caso | Descripcion | Assertion clave |
|------|-------------|-----------------|
| `forceEndTracking` — IN_PROGRESS | Evento en `IN_PROGRESS` | Prisma `update` llamado; respuesta `{ id, state: 'FINISHED' }` |
| `forceEndTracking` — ya FINISHED | Evento en `FINISHED` | Prisma `update` NO llamado; respuesta `{ id, state: 'FINISHED' }` |
| `forceEndTracking` — CANCELLED | Evento en `CANCELLED` | Prisma `update` NO llamado; respuesta `{ id, state: 'CANCELLED' }` |
| `findActiveEventsOlderThan` | 3 eventos: 1 `IN_PROGRESS` + `startDate` antes del cutoff, 1 `IN_PROGRESS` después del cutoff, 1 `FINISHED` | Solo devuelve el primero |

### Integracion / smoke

No existe entorno de integración automatizado. El implementador debe:
1. Arrancar el stack local (`docker-compose up`).
2. Crear un evento `IN_PROGRESS` con `startDate` de hace 25 horas via Prisma Studio o seed.
3. Invocar `autoEndStalledEvents()` manualmente (exportar el método o usar un endpoint temporal de debug).
4. Verificar en la base de datos que el evento quedó `FINISHED`.
5. Verificar que el WS broadcast fue emitido (log del gateway).
6. Verificar que FCM fue disparado (log del scheduler).

---

## Riesgos y mitigaciones

| ID | Severidad | Descripcion | Mitigacion |
|----|-----------|-------------|------------|
| R1 | **Critica** | `forceEndTracking` expuesto accidentalmente por HTTP: cualquier usuario autenticado podría cerrar la rodada de otro | Comentario `// INTERNAL ONLY` en `EventsController`; sin ruta en `TrackingHttpController`; verificar en code review que no existe ningún `@Post` o `@Put` que llame a este pattern; criterio de aceptación 8 es verificable |
| R2 | **Alta** | Fase 3 desplegada sin Fase 1: el cron cierra el evento y hace broadcast WS, pero los riders no cancelan GPS ni WS por el bug original — siguen enviando ubicaciones a un evento FINISHED | Orden de despliegue obligatorio: Fase 1 → Fase 3. Documentado en el handoff de QA. El cron en Fase 3 no tiene sentido completo sin Fase 1 |
| R3 | **Media** | Cron concurrente: una ejecución que tarde >1h solaparía con el siguiente tick horario, procesando el mismo evento dos veces | Flag `_autoEndRunning: boolean` en la instancia; log de advertencia al detectar solapamiento; suficiente para v1 single-instance |
| R4 | **Media** | Módulos NestJS mal conectados: `NotificationSchedulerModule` no importa `TrackingModule`, causando error de inyección en arranque | Verificar en `notification-scheduler.module.ts` que `TrackingModule` está en `imports`; test de smoke de arranque del módulo |
| R5 | **Baja** | `forceEndTracking` puede fallar por timeout RPC si events-ms está lento | `timeout(10_000)` en la llamada RPC; error capturado por try/catch del loop; el cron continúa con los demás eventos |
| R6 | **Baja** | Blast radius FCM masivo si el cron procesa erróneamente eventos `SCHEDULED` o `DRAFT` | La query Prisma filtra explícitamente `state = IN_PROGRESS`; el método `forceEndTracking` verifica el estado antes de hacer UPDATE; doble protección |
| R7 | **Baja** | El campo `startDate` en Prisma puede ser `null` para eventos draft en estado legacy | La query usa `startDate: { lte: cutoffDate }` — valores `null` NO satisfacen la condición `lte` en Prisma (NULL-safe); no hay riesgo de incluir eventos sin `startDate` |

---

## Dependencias (fases prerequisito y por que)

### Fase 1 — WS Cleanup on Event End (Flutter) — OBLIGATORIA

**Por que:** El cron de Fase 3 emite `broadcastEventEnded(eventId)` via WS a todos los riders conectados. Sin Fase 1, los riders reciben el mensaje pero `LiveTrackingCubit._subscribeToEventEnded()` no cancela el GPS ni cierra el WS — el rider sigue enviando ubicaciones al backend de un evento ya `FINISHED` indefinidamente. El broadcast es el mecanismo que desencadena el cleanup del lado cliente; si ese cleanup está roto, el cierre automático es solo parcial. El room en memoria (`TrackingRoomsService`) tampoco se limpia porque los clientes WS nunca se desconectan (el cleanup WS de Fase 1 es lo que dispara `removeClient`).

**Orden de despliegue:** Flutter (Fase 1) debe estar en producción antes de desplegar Fase 3 en api-gateway. Fases 1 y 3 no comparten código Flutter/Backend, pero tienen acoplamiento funcional en runtime.

---

## Ejecucion recomendada (nivel rg-exec: full)

**Nivel:** `full`

**Por que este nivel:**

- **Cross-repo:** los cambios abarcan dos submódulos Git independientes (`events-ms` y `api-gateway`), cada uno con su propio ciclo de build, tests y despliegue. El implementador debe coordinar PRs en ambos repositorios y verificar que los contratos RPC coincidan antes de desplegar.
- **Nuevos MessagePatterns RPC internos:** `'findActiveEventsOlderThan'` y `'forceEndTracking'` son contratos TCP nuevos entre microservicios. Un typo en el nombre del pattern, un mismatch de payload, o un timeout mal configurado causa errores silenciosos en producción (el cron loguea el fallo pero no hay alerta automática).
- **Nuevo servicio inyectable:** `TrackingNotificationsService` debe integrarse correctamente en el árbol de módulos NestJS de dos módulos distintos (`TrackingModule` y `NotificationSchedulerModule`). Una dependencia circular o un módulo no importado resulta en un error de arranque del proceso.
- **Cron con efectos secundarios reales:** el `@Cron` horario ejecuta tres operaciones con efectos sobre estado persistente (Prisma UPDATE) y sistemas externos (WS broadcast a clientes reales, FCM a dispositivos reales). Un bug en la lógica del cron — como un cutoff calculado incorrectamente — puede cerrar eventos activos que no deberían cerrarse, o enviar FCM masivo erróneo.
- **Riesgo de seguridad critico:** `forceEndTracking` bypasea el owner check que existe en `endTracking`. Si este pattern queda expuesto accidentalmente por HTTP (ej: alguien agrega una ruta en `TrackingHttpController` por error), cualquier usuario autenticado puede cerrar la rodada de cualquier otro. El nivel `full` garantiza que el auditor Opus revisa explícitamente la ausencia de esa ruta y que el comentario `// INTERNAL ONLY` está presente.
- **Idempotencia y guard de concurrencia obligatorios:** sin idempotencia en `forceEndTracking`, dos ejecuciones del cron solapadas producirían un conflicto en la actualización de estado. Sin `_autoEndRunning`, una ejecución lenta duplicaría las notificaciones FCM. Estos mecanismos requieren revisión cuidadosa.
- **Coordinación de despliegue con Fase 1:** el implementador debe documentar en el handoff de QA que Fase 3 no debe desplegarse sin Fase 1, y verificar este prerequisito antes del merge.
