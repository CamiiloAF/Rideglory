# 03-architect-review.md

**Slug:** event-tracking-fixes
**Timestamp:** 2026-06-20T00:09:26Z
**Verdict:** ok_con_ajustes

---

## Validacion por fase

### Fase 1 — WS Cleanup on Event End (Flutter)

**Complejidad: BAJA**

El bug está perfectamente delimitado. `_subscribeToEventEnded()` en
`lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart` (línea 546)
solo llama `_logSessionEnded()` y emite `state.copyWith(isFinished: true)`. Le faltan
tres pasos que ya existen como dependencias inyectadas en el cubit:

1. `await _positionSubscription?.cancel(); _positionSubscription = null;`
2. `await _stopTrackingUseCase(eventId: _eventId, userId: _userId!);`
3. `_trackingWsClient.leaveSession(...)` — **AJUSTE REQUERIDO:** `TrackingWsClient`
   NO está inyectado en `LiveTrackingCubit` actualmente. La solución es:
   - Opción A (recomendada): inyectar `TrackingWsClient` en `LiveTrackingCubit`
     mediante su factory (`LiveTrackingCubitFactory`). El cliente ya es
     `@lazySingleton` por lo que GetIt lo resolverá sin coste extra.
   - Opción B: exponer `leaveSession` a través de `TrackingRepository` (interfaz
     de dominio), manteniendo la capa de presentación limpia de dependencias
     concretas de infraestructura.
   Se recomienda la **Opción B** para respetar Clean Architecture: agregar
   `leaveSession({required String eventId, required String userId})` a
   `TrackingRepository` e implementarlo en `TrackingRepositoryImpl` delegando
   a `TrackingWsClient`.

El orden de operaciones debe ser:
```
1. _logSessionEnded(endReasonEventEnded)   // ya presente
2. _positionSubscription?.cancel()
3. _stopTrackingUseCase(eventId, userId)   // fire-and-forget: fold ignoring error
4. _trackingRepository.leaveSession(eventId, userId)
5. emit(state.copyWith(isTracking: false, isFinished: true))
```
El paso 3 puede fallar (el evento ya está FINISHED en el backend); debe capturarse
en `fold` sin relanzar para no bloquear el paso 4. El paso 5 se emite al final
para que la UI de `RideFinishedOverlay` aparezca tras completar el cleanup.

La cobertura de tests es un gap confirmado. Se necesita un nuevo test en un archivo
dedicado (e.g. `live_tracking_cubit_event_ended_test.dart`) que use `MockTrackingRepository`
con un `StreamController<void>` para `eventEnded`, verifique que el cubit:
- llama `stopTrackingUseCase` exactamente una vez
- llama `trackingRepository.leaveSession` exactamente una vez
- emite estado con `isTracking: false, isFinished: true`
- respeta `_sessionEndLogged` (no doble log si ya fue llamado)

**No hay cambios de contrato API en esta fase.**

---

### Fase 2 — Event List Date Filter (Flutter)

**Complejidad: BAJA**

El backend ya soporta `dateFrom` en `GET /api/events` — confirmado en `EventService`
Retrofit, `GetEventsUseCase`, y `EventsService` en events-ms. El gap está enteramente
en `EventsCubit.fetchEvents()` (línea 100):

```dart
final result = await _fetchFn(
  type: ...,
  dateFrom: filters.startDate?.toIso8601String().substring(0, 10),  // null si no hay filtro
  dateTo: ...,
);
```

**Fix:** cuando `filters.startDate == null` (sin filtro de usuario), pasar como piso:
```dart
final floor = DateTime.now();
final floorDate = DateTime(floor.year, floor.month, floor.day);
final dateFrom = (filters.startDate ?? floorDate).toIso8601String().substring(0, 10);
```

**AJUSTE REQUERIDO — Timezone:** El PO marcó el riesgo de UTC vs. local. La fecha
debe computarse en la hora local del dispositivo (no UTC) para que un usuario en
UTC-5 no vea eventos de ayer. `DateTime.now()` en Dart siempre retorna la hora
local del dispositivo, por lo que `DateTime(floor.year, floor.month, floor.day)`
trunca correctamente a medianoche local. NO usar `DateTime.now().toUtc()`.

**AJUSTE MENOR — myEvents no recibe el fix:** El constructor `EventsCubit.myEvents`
usa `GetMyEventsUseCase` que no acepta `dateFrom`, y no tiene este bug (muestra
TODOS los eventos del owner, incluyendo pasados, lo cual es UX correcta para el
organizador). El fix solo aplica al `EventsCubit` default. Verificar que la rama
`_isMyEvents` no quede afectada.

**AJUSTE DE UX — Eventos IN_PROGRESS:** El backend excluye `IN_PROGRESS` de la
lista general a menos que el `authUserId` sea owner o registrante aprobado. Con el
nuevo `dateFrom = hoy`, un evento que arrancó ayer (startDate ayer, estado IN_PROGRESS)
quedaría excluido por `dateFrom` aunque el rider debería verlo. La solución es aplicar
`dateFrom` como piso de `startDate` en el backend, lo que ya ocurre (`dateFrom` filtra
`startDate >= dateFrom`). Dado que la rodada podría comenzar justo antes de medianoche,
hay un edge case donde el rider no vería un evento en progreso desde ayer. Se recomienda
que la UI de lista filtre solo `state == FINISHED || state == CANCELLED` del lado
cliente como post-proceso adicional en `_applyFiltersAndEmit()`, o que el `dateFrom`
aplique solo `startDate >= ayer` (T-1 día) como buffer. Decisión de producto: para
v1, aplicar piso = hoy es aceptable; el edge case de rodadas nocturnas es improbable.

**No hay cambios de contrato API en esta fase.**

---

### Fase 3 — Auto-End Events After 24 Hours (Backend)

**Complejidad: MEDIA**

La infraestructura está en muy buen estado: `@nestjs/schedule` instalado, cron de
recordatorios funcionando como patrón, `broadcastEventEnded` y `sendEventEndedNotifications`
ya existentes. Sin embargo hay tres gaps de implementación y un riesgo de seguridad:

**Gap 1 — Método `forceEndTracking` en events-ms:**
`EventsService.endTracking()` (línea 320 del service) valida `event.ownerId !== authUserId`
y lanza excepción si no coinciden. Para el cron no hay `authUserId`. Se necesita un
método interno sin esa validación:

```typescript
// events-ms/src/events/events.service.ts
async forceEndTracking(eventId: string): Promise<{ id: string; state: string }> {
  const event = await this.prisma.event.findUniqueOrThrow({ where: { id: eventId } });
  if (event.state !== EventState.IN_PROGRESS) return { id: event.id, state: event.state };
  return this.prisma.event.update({
    where: { id: eventId },
    data: { state: EventState.FINISHED },
    select: { id: true, state: true },
  });
}
```

Y el MessagePattern correspondiente en `EventsController`:
```typescript
@MessagePattern('forceEndTracking')
forceEndTracking(@Payload() payload: { eventId: string }) {
  return this.eventsService.forceEndTracking(payload.eventId);
}
```

**RIESGO CRÍTICO:** Este MessagePattern NO debe tener un endpoint HTTP en api-gateway.
El cron lo invoca internamente por RPC. El controller HTTP
`TrackingHttpController` no debe exponer `POST /tracking/force-end`. Documentar
explícitamente esta restricción en el código con un comentario.

**Gap 2 — Método `findActiveEventsOlderThan` en events-ms:**
```typescript
async findActiveEventsOlderThan(cutoffDate: Date): Promise<{ id: string; name: string }[]> {
  return this.prisma.event.findMany({
    where: {
      state: EventState.IN_PROGRESS,
      startDate: { lte: cutoffDate },
    },
    select: { id: true, name: true },
  });
}
```
Y su MessagePattern `'findActiveEventsOlderThan'` en `EventsController`.

**AJUSTE — Usar `startDate` o `updatedAt`:** El campo `startDate` es el que define
cuándo arrancó la rodada según el organizador. Un evento que arranca puntual a las
10am del día anterior a las 10:10am tiene `startDate = ayer_10am`, cutoff = `ahora - 24h`.
Este es el campo correcto para el cron. NO usar `createdAt` ni `updatedAt`.

**Gap 3 — Extracción de `sendEventEndedNotifications`:**
El método privado `sendEventEndedNotifications` en `TrackingHttpController` (línea 198)
debe extraerse a `NotificationsService` o a un nuevo `EventNotificationsService`
(injectable) para que el scheduler lo reutilice sin duplicación. La firma propuesta:
```typescript
async sendEventEndedNotifications(eventId: string): Promise<void>
```
Alternativa más simple: mantener el método en `TrackingHttpController` pero moverlo
a un `TrackingNotificationsService` inyectado en ambos. De las dos, la segunda es
preferible para no inflar `NotificationsService` con lógica de negocio de eventos.

**Gap 4 — Limpieza de `TrackingRoomsService`:**
`TrackingRoomsService` en api-gateway mantiene `clientsByEvent: Map<string, Set<WebSocket>>`.
Cuando el cron llama `broadcastEventEnded(eventId)`, todos los clientes WS conectados
reciben el mensaje y (gracias a la Fase 1) se desconectan limpiamente via
`handleDisconnect → rooms.removeClient()`. El room se auto-limpia en O(n_riders)
desconexiones individuales. **No se necesita un `removeRoom` explícito** — el
`removeClient` ya borra el `Set` cuando está vacío (línea 24: `if (set.size === 0)
{ this.clientsByEvent.delete(eventId); }`). Este riesgo del PO está mitigado por
el comportamiento existente, siempre que la Fase 1 esté desplegada antes de Fase 3.

**Cron propuesto:**
```typescript
// Cada hora en punto, zona America/Bogota
@Cron('0 * * * *', { timeZone: 'America/Bogota' })
async autoEndStalledEvents() {
  const cutoff = new Date(Date.now() - 24 * 60 * 60_000);
  // 1. Fetch stalled events
  // 2. For each: forceEndTracking → broadcastEventEnded → sendEventEndedNotifications
  // 3. Log resultado
}
```

**AJUSTE — Concurrencia del cron:** No existe protección contra solapamiento de
ejecuciones del cron (si un run tarda >1h). Para v1, dado que son eventos de rodada
(pocos simultáneos), es aceptable sin guard. Si se quiere protección, un flag en
memoria (`_autoEndRunning: boolean`) es suficiente para el proceso single-instance.
No se necesita lock distribuido en esta escala.

---

## Contratos

### Contratos nuevos en events-ms (MessagePatterns — RPC interno, NO HTTP)

| MessagePattern | Payload | Response | Notas |
|---|---|---|---|
| `'findActiveEventsOlderThan'` | `{ cutoffDate: string }` (ISO) | `{ id: string; name: string }[]` | Solo estado `IN_PROGRESS` con `startDate <= cutoffDate` |
| `'forceEndTracking'` | `{ eventId: string }` | `{ id: string; state: string }` | Idempotente: si ya es FINISHED retorna sin modificar; sin owner check |

### Contratos modificados en TrackingRepository (Flutter — Fase 1 con Opción B)

| Método | Firma | Implementación |
|---|---|---|
| `leaveSession` | `Future<void> leaveSession({required String eventId, required String userId})` | Delegar a `TrackingWsClient.leaveSession(eventId: eventId, userId: userId)` |

### Sin cambios en contratos HTTP ni en DTOs Retrofit

Las fases 1 y 2 son puramente Flutter internals. La Fase 3 agrega solo MessagePatterns
internos de RPC entre api-gateway y events-ms — ningún endpoint HTTP nuevo.

---

## Riesgos

### R1 — `forceEndTracking` expuesto accidentalmente por HTTP [CRÍTICO]
**Descripción:** Si alguien agrega por error un endpoint HTTP para invocar
`forceEndTracking`, cualquier usuario autenticado podría finalizar la rodada de otro.
**Mitigación:** (a) El MessagePattern solo vive en `EventsController` (microservicio
TCP, no HTTP). (b) Agregar comentario `// INTERNAL ONLY — no HTTP endpoint` en el
controller. (c) Code review checklist debe verificar que no existe ruta en
`TrackingHttpController` para este pattern.

### R2 — Fase 3 depende de Fase 1 para limpieza completa [MEDIO]
**Descripción:** Si la Fase 3 se despliega sin la Fase 1, el cron finaliza el evento
y hace broadcast `tracking.event.ended`, pero el rider no cancela GPS ni WS (bug
original). El rider sigue enviando ubicaciones a un evento FINISHED.
**Mitigación:** Desplegar Fases 1 + 2 antes de Fase 3. El executor debe documentar
esto como prerrequisito en el handoff de QA.

### R3 — Timezone en dateFrom (Fase 2) [BAJO]
**Descripción:** Si se usa UTC en lugar de local, un rider en Colombia (UTC-5) vería
eventos que empezaron hace hasta 5 horas como "pasados" y no los vería.
**Mitigación:** Usar `DateTime.now()` en Dart (siempre local), truncar a medianoche
local con `DateTime(now.year, now.month, now.day)`.

### R4 — `_stopTrackingUseCase` puede fallar en Fase 1 si el evento ya es FINISHED [BAJO]
**Descripción:** El backend rechaza `trackingStopSession` para eventos FINISHED.
**Mitigación:** El resultado de `_stopTrackingUseCase` debe manejarse con `fold` sin
relanzar; el cleanup de WS y la emisión de UI deben ocurrir independientemente del
resultado HTTP.

### R5 — Analytics doble-conteo en Fase 1 [BAJO]
**Descripción:** Si el usuario ya inició el cierre manual (`close()`) simultáneamente
con `eventEnded`, `_sessionEndLogged` podría ya estar en true.
**Mitigación:** El flag `_sessionEndLogged` ya existe y está verificado en
`_logSessionEnded()` — el fix debe respetar este flag antes de loguear, lo que ya
es el comportamiento de `_logSessionEnded`.

---

## Ajustes

1. **Fase 1 — Inyectar `leaveSession` vía `TrackingRepository`** (Opción B): agregar
   `leaveSession` como método abstracto en la interfaz de dominio `TrackingRepository` e
   implementarlo en `TrackingRepositoryImpl`. Esto evita inyectar `TrackingWsClient`
   (infraestructura) directamente en el cubit (presentación).

2. **Fase 1 — Orden correcto de cleanup**: la emisión de `isFinished: true` va al
   final, después de cancelar GPS y llamar stop + leaveSession, para no bloquear la
   UI mientras se esperan los awaits.

3. **Fase 2 — `DateTime.now()` local, no UTC**: documentar este requisito explícitamente
   en el handoff de frontend para que el implementador no use `.toUtc()`.

4. **Fase 3 — Extraer `sendEventEndedNotifications` a `TrackingNotificationsService`**:
   nuevo servicio inyectable en api-gateway, compartido por `TrackingHttpController` y
   `NotificationSchedulerService`. Evita duplicación y deriva futura.

5. **Fase 3 — `forceEndTracking` es idempotente**: debe verificar `state !== IN_PROGRESS`
   antes de hacer el UPDATE y retornar sin error si ya es FINISHED. Esto previene
   re-procesamiento si el cron se solapa.

6. **Orden de despliegue obligatorio: Fase 1 → Fase 2 → Fase 3**. Fase 3 tiene
   prerrequisito funcional sobre Fase 1 (rooms cleanup vía WS disconnect).
