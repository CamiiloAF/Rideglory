# 01-scan.md

**Slug:** event-tracking-fixes
**Timestamp:** 2026-06-20T00:05:22Z

---

## Inventario Flutter

### Feature: events

**Domain** (`lib/features/events/domain/`)
- `EventModel` — modelo puro con `EventState` enum (draft/scheduled/inProgress/inProgress/finished/cancelled)
- `TrackingRepository` — interfaz abstracta con streams: `eventEnded`, `sosAlerts`, `sosCleared`; métodos `stopTracking`, `startTracking`, `endRide`
- Use cases clave: `StopTrackingUseCase`, `StartTrackingUseCase`, `UpdateLocationUseCase`, `WatchActiveRidersUseCase`, `GetEventsUseCase` (acepta `type`, `dateFrom`, `dateTo`)

**Data** (`lib/features/events/data/`)
- `EventService` — Retrofit client con `getEvents({type, dateFrom, dateTo})`, `getMyEvents()`, `startRide(id)`, `endRide(id)`, `getEventById(id)`
- `TrackingWsClient` — `@lazySingleton`; gestiona WS con auto-reconexión (Timer 2s en `_onDisconnected`); expone `eventEnded` stream; tiene `leaveSession({eventId, userId})` que setea `_manualDisconnect = true` y cierra canal

**Presentation** (`lib/features/events/presentation/`)
- `LiveTrackingCubit` — cubit central del tracking en vivo; `_subscribeToEventEnded()` escucha `trackingRepository.eventEnded` pero **solo emite `isFinished: true`**, sin cancelar `_positionSubscription`, sin llamar `_stopTrackingUseCase`, y sin llamar `_wsClient.leaveSession()` — BUG CONFIRMADO
- `EventsCubit` — cubit de listado con `EventFilters` (types, difficulties, startDate, endDate, freeOnly, multiBrandOnly); la carga inicial no pasa `dateFrom`, por lo que carga todos los eventos incluyendo pasados — GAP CONFIRMADO
- `EventFilters` — modelo de filtros local; `startDate`/`endDate` se aplican localmente en `_applyFiltersAndEmit()`, pero el fetch no aplica filtro de fecha automático al arrancar

**Tests existentes:**
- `test/features/events/presentation/tracking/live_tracking_cubit_analytics_test.dart` — cubre SOS y analytics del cubit; usa `MockTrackingRepository` con streams controlados; no cubre el path de `eventEnded` + cleanup

### Feature: home

**Domain** (`lib/features/home/domain/`)
- `HomeData` — contiene `mainVehicle` y `upcomingEvents: List<EventModel>`
- `GetHomeDataUseCase` — llama `HomeRepository.getHomeData()`

**Data** (`lib/features/home/data/`)
- `HomeService` — Retrofit client `GET /home` sin parámetros de fecha
- `HomeRepositoryImpl` — delega a `HomeService.getHome()`; no hay punto de extensión para filtros de fecha

**Presentation** (`lib/features/home/presentation/`)
- `HomeCubit` / `HomeState` — carga datos de home en bloque; los eventos upcoming vienen del endpoint `/home`

---

## Dependencias pubspec.yaml relevantes

- `flutter_bloc` / `bloc` — state management
- `web_socket_channel` — WS tracking
- `geolocator` — GPS position stream (base de `_positionSubscription`)
- `retrofit` / `dio` — REST client incluyendo `EventService`
- `injectable` / `get_it` — DI; `TrackingWsClient` es `@lazySingleton`
- `freezed_annotation` — `LiveTrackingState` es freezed
- `mocktail` — mocking en tests

---

## Superficie rideglory-api

### api-gateway (`/api-gateway/src/`)

**Tracking HTTP** (`tracking/tracking-http.controller.ts`)
- `POST /api/events/:eventId/tracking/start` — cambia estado a IN_PROGRESS + broadcast `tracking.event.started`
- `POST /api/events/:eventId/tracking/end` — cambia estado a FINISHED + broadcast `tracking.event.ended` + FCM multicast a registrantes aprobados vía `sendEventEndedNotifications()`
- `POST /api/events/:eventId/tracking/session/start` — registra rider en room de memoria + broadcast snapshot
- `POST /api/events/:eventId/tracking/session/stop` — elimina rider de room + broadcast `tracking.rider.left`
- `GET /api/events/:eventId/tracking/snapshot` — devuelve riders activos

**Events HTTP** (`events/events.controller.ts`)
- `GET /api/events?type=&dateFrom=&dateTo=` — pasa filtros al events-ms; incluye `authUserId` del token
- `GET /api/events/upcoming?type=&dateFrom=&dateTo=` — eventos futuros (sin auth user requerido)
- `GET /api/events/my` — eventos del owner autenticado

**TrackingBroadcaster** (`tracking/tracking-broadcaster.service.ts`)
- `broadcastEventEnded(eventId)` — ya existe y funciona; emite JSON `{ type: 'tracking.event.ended', data: { eventId } }` a todos los clientes WS del room

**NotificationSchedulerService** (`scheduler/notification-scheduler.service.ts`)
- `@nestjs/schedule` INSTALADO en api-gateway (`^6.1.3`)
- Cron existente: `sendEventReminders()` cada 15 min — busca eventos 24h antes de empezar
- Infraestructura completa: `@Cron`, `EVENTS_SERVICE` ClientProxy, `NotificationsService` con FCM, `getApprovedRegistrantUserIds`, manejo de errores por evento
- **NO existe cron de auto-finalización** de eventos IN_PROGRESS que lleven > 24h

### events-ms (`/events-ms/src/`)

**EventsService** (Prisma + lógica de negocio)
- `findAll(filters)` — filtra por `dateFrom`/`dateTo` (parámetros YA SOPORTADOS), `type`, y visibilidad IN_PROGRESS por `authUserId`
- `endTracking(eventId, authUserId)` — cambia estado de IN_PROGRESS a FINISHED; requiere que `authUserId === ownerId` — **NO reutilizable directamente para cron** (requiere owner check)
- `getApprovedRegistrantUserIds(eventId)` — ya existe
- `markReminderSent(eventId)` / `findEventsNeedingReminder(from, to)` — patrón de idempotencia ya establecido
- **NO existe método** para buscar eventos IN_PROGRESS con startDate > 24h (necesario para cron de auto-finalización)
- **NO existe MessagePattern** `'autoEndEvent'` o similar

**EventState enum** (en contracts): `DRAFT | SCHEDULED | IN_PROGRESS | CANCELLED | FINISHED`

**TrackingService** — mantiene rooms en memoria (`ridersByEvent: Map<string, Map<string, RiderTrackingDto>>`); no tiene método para limpiar rooms de eventos auto-finalizados

**`@nestjs/schedule` NO está instalado en events-ms** — solo en api-gateway

---

## Gap Analysis

### Fix 1 — WS cleanup al recibir `tracking.event.ended` (Flutter)

**Estado: partial**

- `TrackingWsClient.leaveSession()` EXISTE y es correcto (setea `_manualDisconnect`, cierra canal)
- `StopTrackingUseCase` EXISTE con contrato correcto
- `_positionSubscription` EXISTE pero no se cancela en `_subscribeToEventEnded()`
- `_subscribeToEventEnded()` solo llama `emit(state.copyWith(isFinished: true))` — le faltan 3 pasos: cancelar GPS, llamar stop use case, llamar leaveSession
- Los tests existentes de `LiveTrackingCubit` no cubren el path `eventEnded → cleanup`

**Lo que falta:**
- Modificar `_subscribeToEventEnded()` en `live_tracking_cubit.dart`
- Agregar test unitario para el path eventEnded en `live_tracking_cubit_analytics_test.dart` o archivo nuevo

### Fix 2 — Auto-finalización de eventos tras 24h (Backend)

**Estado: not started**

- `@nestjs/schedule` YA instalado en api-gateway — no hay que agregarlo
- Infraestructura de crons YA existe en `NotificationSchedulerService`
- `broadcastEventEnded()` YA existe en `TrackingBroadcaster`
- `sendEventEndedNotifications()` YA existe en `TrackingHttpController` (método privado, necesita extracción o replicación)
- `getApprovedRegistrantUserIds` MessagePattern YA existe

**Lo que falta:**
1. **events-ms**: nuevo método `findActiveEventsOlderThan(cutoffDate)` en `EventsService` + nuevo MessagePattern `'findActiveEventsOlderThan'` en `EventsController`; nuevo método `forceEndTracking(eventId)` sin owner check para uso interno del cron
2. **api-gateway**: nuevo método `@Cron` en `NotificationSchedulerService` (o nuevo servicio) que: (a) busca eventos IN_PROGRESS con `startDate <= now - 24h`, (b) llama `forceEndTracking` via RPC, (c) llama `broadcastEventEnded`, (d) envía FCM a registrantes
3. Inyectar `TrackingBroadcaster` en el scheduler o extraer la lógica FCM del `TrackingHttpController` a un servicio compartido

### Fix 3 — Filtro de eventos por fecha en home/listado (Flutter)

**Estado: partial**

- El backend YA soporta `dateFrom` / `dateTo` en `GET /api/events` — el parámetro está en `EventFilterDto`, `FindAllEventsPayloadDto`, y `EventsService` Retrofit
- `GetEventsUseCase` acepta `dateFrom` como String
- `EventsCubit.fetchEvents()` pasa `filters.startDate` al backend cuando el usuario aplica filtros manualmente
- **Gap:** el fetch inicial (sin filtros del usuario) no envía `dateFrom=startOfToday`, por lo que trae eventos pasados
- Para home: `GET /home` llama `findUpcoming` que YA filtra `startDate >= new Date()` en el backend — home NO tiene el bug; el bug es en la página de listado general

**Lo que falta:**
- En `EventsCubit.fetchEvents()`: cuando `filters.startDate == null` (sin filtro de usuario), pasar `dateFrom = startOfToday.toIso8601String()` como piso mínimo
- Alternativa más limpia: en `_fetchFn` del cubit default (no myEvents), siempre pasar `dateFrom` al menos como inicio del día actual si el usuario no especificó fechas

---

## Patrones

1. **Cron idempotente con flag**: ya establecido en `markReminderSent`/`reminderSentAt`; el cron de auto-finalización puede replicar este patrón o simplemente chequear el estado actual del evento antes de proceder (eventos FINISHED ya no son IN_PROGRESS).
2. **Broadcast + FCM separados**: el patrón existente en `TrackingHttpController.endTracking()` es `broadcast(eventId) → sendNotifications(eventId)` (async fire-and-forget para FCM); el cron debe replicarlo.
3. **RPC desde api-gateway a events-ms**: patrón establecido con `ClientProxy.send(pattern, payload).pipe(timeout(N))`. El nuevo método del cron seguirá este mismo patrón.
4. **Singleton WS client**: `TrackingWsClient` es `@lazySingleton` en Flutter; la llamada a `leaveSession` desde el cubit debe usar el cliente ya inyectado (no crear instancia nueva).
5. **Bus de analytics anti-doble-conteo**: `_sessionEndLogged` flag en el cubit; el fix de `eventEnded` debe respetar esta lógica (ya existe `_logSessionEnded()`).

---

## Implicaciones para el plan

1. **Fase 1 (Flutter WS cleanup)** es la más simple — cambio quirúrgico en `_subscribeToEventEnded()` + test unitario. Riesgo bajo; `leaveSession` y `stopUseCase` ya existen.

2. **Fase 2 (Backend cron)** requiere cambios en dos submódulos (`rideglory-contracts` opcional, `events-ms`, `api-gateway`). El mayor riesgo es el owner-check en `endTracking`: necesita un método interno sin esa validación o un parámetro `force: true`. El cron vive en api-gateway donde `@nestjs/schedule` ya está. El broadcaster ya existe y es inyectable.

3. **Fase 3 (Filtro fecha Flutter)** es un cambio de una línea en `EventsCubit.fetchEvents()`: pasar `dateFrom = startOfToday` cuando no hay filtro de usuario activo. No requiere cambios en backend (ya soportado). El home ya funciona correctamente vía `findUpcoming`.

4. **Orden sugerido de fases**: 1 → 3 → 2 (de menor a mayor complejidad y riesgo; las fases Flutter son independientes entre sí y del backend).

5. **Extracción de `sendEventEndedNotifications`** del `TrackingHttpController` a un servicio compartido puede ser conveniente para Fase 2, pero también puede replicarse inline en el scheduler para menor acoplamiento — decisión para el arquitecto de plan.
