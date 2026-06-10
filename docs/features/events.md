# Documentación del Feature: Events

> Última actualización: 2026-06-01  
> Alcance: `lib/features/events/`

> Esta documentación cubre únicamente el feature `events/`. El feature de inscripciones, antes incluido aquí, se separó a [event_registration.md](./event_registration.md).

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Ciclo de vida de un evento](#3-ciclo-de-vida-de-un-evento)
4. [Arquitectura por capas](#4-arquitectura-por-capas)
   - 4.1 [Domain](#41-domain)
   - 4.2 [Data](#42-data)
   - 4.3 [Presentation](#43-presentation)
5. [Cubits y estados](#5-cubits-y-estados)
6. [Flujo de tracking en vivo](#6-flujo-de-tracking-en-vivo)
7. [Sub-features](#7-sub-features)
8. [Rutas de navegación](#8-rutas-de-navegación)
9. [API endpoints](#9-api-endpoints)
10. [Conexiones con otros features](#10-conexiones-con-otros-features)
11. [Patrones y trampas conocidas](#11-patrones-y-trampas-conocidas)
12. [Archivos clave de referencia rápida](#12-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

El feature **Events** es el núcleo de Rideglory. Permite a los organizadores **crear, publicar y gestionar rodadas de motociclismo** y a los riders **explorar, ver detalle y seguir en tiempo real** los eventos.

Responsabilidades:
- CRUD completo de eventos (lista, detalle, crear, editar, publicar, eliminar).
- Constructor de rutas (simple y custom con hasta 9 waypoints) con Mapbox.
- Tracking en vivo via WebSocket (`/tracking/ws`) durante un evento `inProgress`.
- Gestión de asistentes (aprobación/rechazo desde el organizador).
- SOS broadcast durante el tracking.

> El feature de inscripciones (`event_registration/`) consume `EventModel` y se documenta aparte. Las pantallas de eventos pueden navegar al form de inscripción, pero la lógica del registro vive en su propio feature.

---

## 2. Modelo de dominio

### `EventModel`
> `lib/features/events/domain/model/event_model.dart`

```
EventModel
  id: String?                              — null si no persiste aún
  ownerId: String                          — userId del organizador (requerido)
  name: String                             (requerido)
  description: String                      — rich-text (JSON Quill Delta serializado como string)
  city: String                             (requerido)
  startDate: DateTime                      (requerido)
  endDate: DateTime?                       — null = evento de un día
  difficulty: EventDifficulty              (requerido, 1–5)
  meetingPoint: String                     — nombre textual
  destination: String                      — nombre textual
  meetingTime: DateTime                    — la fecha es ignorada, solo hora
  eventType: EventType                     (requerido)
  allowedBrands: List<String>              (default [])
  price: int?                              — null o 0 = gratis
  maxParticipants: int?                    — null = sin límite
  imageUrl: String?                        — URL Firebase Storage
  createdDate: DateTime?
  updatedDate: DateTime?
  state: EventState                        (default scheduled)
  waypoints: List<String>                  (default []) — nombres textuales
  routeGeoJson: Map<String, dynamic>?      — {routeType, points: [{lat, lng, label}]}
```

**Getters calculados:**
- `isFree` → `price == null || price == 0`.
- `isMultiBrand` → `allowedBrands.isEmpty`.
- `isMultiDay` → `endDate != null`.
- `routePoints` → parsea `routeGeoJson['points']` a `List<AddressLocation>` para Mapbox.

**Igualdad**: solo por `id` (`==` y `hashCode`). **Trampa**: dos eventos con `id == null` se consideran iguales (hash 0).

### Enums

**`EventType`**
| Enum | Label |
|---|---|
| `tourism` | Turismo |
| `urban` | Urbana |
| `offRoad` | Off-road |
| `competition` | Competición |
| `solidarity` | Solidaria |
| `shortDistance` | Corta distancia |

**`EventDifficulty`** — 5 niveles con `value: int` (1–5), `label` con chiles y `shortLabel`. `fromValue(int)` hace lookup inverso (default `one` si no coincide).

**`EventState`** — `draft`, `scheduled`, `inProgress`, `cancelled`, `finished`.

**`RouteType`** (en `constants/event_form_fields.dart`) — `simple`, `custom`.

### `RiderTrackingModel`
> `domain/model/rider_tracking_model.dart`

```
userId / fullName / role: RiderTrackingRole (lead | rider)
latitude / longitude / speedKmh / distanceMeters
batteryPercent / isActive / deviceLabel / lastUpdated
```

`RiderTrackingRole.fromStorage(String?)` parsea `'lead'` → `lead`, todo lo demás → `rider`.

### `RiderProfileModel`
> `domain/model/rider_profile_model.dart`

Datos persistidos del rider para pre-llenar futuras inscripciones:
```
id, userId, fullName, identificationNumber, birthDate,
phone, email, residenceCity,
eps, medicalInsurance, bloodType,
emergencyContactName, emergencyContactPhone,
updatedDate
```

### `SosAlertModel`
```
userId, riderName, latitude?, longitude?, phone?
```

### `UpdateLocationRequest`
```
eventId, userId, latitude, longitude, speedKmh, distanceMeters, batteryPercent
```

### `UploadEventImageRequest`
```
localImagePath, eventId?, ownerId?
```

---

## 3. Ciclo de vida de un evento

```
[NUEVA CREACIÓN]
     │
     ▼
  draft ────── publishEvent() ──────▶ scheduled
     │                                    │
     │                                    │ startEvent() (organizador)
     │                                    ▼
     │                               inProgress
     │                                    │
     │                                    │ stopEvent() (organizador)
     │                                    ▼
     │                                finished
     │
     └── deleteEvent() válido en draft y scheduled
```

| Acción | Cubit method | Endpoint | Restricción |
|---|---|---|---|
| Guardar borrador | `EventFormCubit.saveDraft()` | `POST/PATCH /events` | `state=draft`, solo requiere `name` |
| Publicar | `EventDetailCubit.publishEvent()` | `PATCH /events/:id/publish` | Solo owner |
| Iniciar | `EventDetailCubit.startEvent()` | `POST /events/:id/tracking/start` | Solo owner, estado scheduled |
| Finalizar | `EventDetailCubit.stopEvent()` | `POST /events/:id/tracking/end` | Solo owner, estado inProgress |
| Eliminar | `EventDeleteCubit.deleteEvent()` | `DELETE /events/:id` | Solo owner |

---

## 4. Arquitectura por capas

### 4.1 Domain
```
lib/features/events/domain/
├── model/
│   ├── event_model.dart
│   ├── rider_tracking_model.dart
│   ├── rider_profile_model.dart
│   ├── sos_alert_model.dart
│   ├── update_location_request.dart
│   └── upload_event_image_request.dart
├── repository/
│   ├── event_repository.dart
│   ├── tracking_repository.dart
│   ├── event_cover_repository.dart
│   └── rider_profile_repository.dart
└── use_cases/
    ├── create_event_use_case.dart
    ├── update_event_use_case.dart
    ├── delete_event_use_case.dart
    ├── get_events_use_case.dart
    ├── get_my_events_use_case.dart
    ├── get_event_by_id_use_case.dart
    ├── publish_event_use_case.dart
    ├── upload_event_image_use_case.dart
    ├── get_generate_cover_use_case.dart
    ├── start_tracking_use_case.dart
    ├── stop_tracking_use_case.dart
    ├── update_location_use_case.dart
    ├── watch_active_riders_use_case.dart
    ├── get_rider_profile_use_case.dart
    └── save_rider_profile_use_case.dart
```

**`EventRepository`** (signatures):
```dart
getEvents({type?, dateFrom?, dateTo?, city?}) → Either<DomainException, List<EventModel>>
getMyEvents() → Either<…, List<EventModel>>
getEventById(String id) → Either<…, EventModel>
createEvent(EventModel) → Either<…, EventModel>
updateEvent(EventModel) → Either<…, EventModel>     // requiere id != null
deleteEvent(String id) → Either<…, Nothing>
uploadEventImage(UploadEventImageRequest) → Either<…, String>  // URL pública
publishEvent(String id) → Either<…, EventModel>
```

**`TrackingRepository`**:
```dart
watchActiveRiders(String eventId) → Stream<List<RiderTrackingModel>>
startTracking({eventId, initialData}) → Future<Either<…, Nothing>>
updateLocation(UpdateLocationRequest) → Future<Either<…, Nothing>>
stopTracking({eventId, userId}) → Future<Either<…, Nothing>>
endRide(String eventId) → Future<Either<…, Nothing>>
publishSos({eventId, userId, latitude?, longitude?}) → void          // sin retorno
sosAlerts → Stream<SosAlertModel>
eventEnded → Stream<void>
```

**`EventCoverRepository`**:
```dart
generateCover({title, eventType, city}) → Future<Either<…, String>>
```

**`RiderProfileRepository`**:
```dart
getMyRiderProfile() → Future<Either<…, RiderProfileModel?>>
saveRiderProfile(RiderProfileModel) → Future<Either<…, RiderProfileModel>>
```

---

### 4.2 Data
```
lib/features/events/data/
├── dto/
│   ├── event_dto.dart                (extends EventModel)
│   ├── event_dto_converters.dart     (EventDifficultyConverter, EventTypeConverter, EventStateConverter)
│   ├── rider_tracking_dto.dart       (extends RiderTrackingModel)
│   ├── rider_profile_dto.dart        (extends RiderProfileModel)
│   ├── cover_generation_dto.dart
│   └── *.g.dart
├── repository/
│   ├── event_repository_impl.dart
│   ├── tracking_repository_impl.dart
│   ├── event_cover_repository_impl.dart
│   └── rider_profile_repository_impl.dart
└── service/
    ├── event_service.dart            (@singleton @RestApi)
    ├── event_cover_service.dart      (@singleton @RestApi)
    ├── tracking_service.dart         (Dio manual, sin Retrofit)
    └── tracking_ws_client.dart       (@lazySingleton WebSocket)
```

**`EventDto extends EventModel`** — patrón inusual donde el DTO hereda del modelo. `EventModel.toJson()` se expone como extension (`EventModelExtension.toJson()` en `event_dto.dart`).

**Converters Freezed-style** para enums:
- `EventDifficultyConverter`: acepta `int` o `String` (`EASY`, `MODERATE`, `MEDIUM`, `HARD`, `VERY_HARD`).
- `EventTypeConverter`: serializa como UPPER_SNAKE_CASE (`TOURISM`, `OFF_ROAD`, etc.).
- `EventStateConverter`: maneja camelCase y UPPER_SNAKE_CASE; default `scheduled` si null.

**`EventService` (Retrofit)**:
| Método | HTTP | Path |
|---|---|---|
| `getEvents({type?, dateFrom?, dateTo?, city?})` | `GET` | `/events` |
| `getMyEvents()` | `GET` | `/events/my` |
| `getEventById(id)` | `GET` | `/events/{id}` |
| `createEvent(body)` | `POST` | `/events` |
| `updateEvent(id, body)` | `PATCH` | `/events/{id}` |
| `deleteEvent(id)` | `DELETE` | `/events/{id}` |
| `startRide(id)` | `POST` | `/events/{id}/tracking/start` |
| `endRide(id)` | `POST` | `/events/{id}/tracking/end` |
| `publishEvent(id)` | `PATCH` | `/events/{id}/publish` |

**`TrackingService` (Dio manual)**:
| Método | HTTP | Path | Body |
|---|---|---|---|
| `startSession({eventId, rider})` | `POST` | `/events/{id}/tracking/session/start` | `{rider: RiderTrackingDto.toJson()}` |
| `stopSession({eventId, userId})` | `POST` | `/events/{id}/tracking/session/stop` | `{userId}` |
| `snapshot(eventId)` | `GET` | `/events/{id}/tracking/snapshot` | — |

**`EventRepositoryImpl.uploadEventImage()`** sube a Firebase Storage en path:
- Si tiene `eventId`: `events/{eventId}/cover.jpg`.
- Si no (creación): `events/{ownerId}-{microseconds}/cover.jpg`.

Retorna la URL de descarga pública.

---

### 4.3 Presentation
```
lib/features/events/presentation/
├── list/
│   ├── events_cubit.dart
│   ├── events_page.dart
│   └── widgets/
├── detail/
│   ├── cubit/event_detail_cubit.dart, event_detail_state.dart
│   ├── event_detail_page.dart        (recibe EventModel)
│   ├── event_detail_by_id_page.dart  (recibe String id, fetch al init)
│   ├── event_detail_view.dart
│   ├── event_route_map_screen.dart   (mapa full-screen de la ruta)
│   ├── params.dart                   (EventDetailPageParams, EventRegistrationParams)
│   └── widgets/
├── form/
│   ├── cubit/event_form_cubit.dart, event_form_state.dart
│   ├── event_form_page.dart
│   ├── screens/event_route_config_screen.dart    (constructor de ruta custom)
│   └── widgets/
│       └── sections/                              (una sección por archivo)
├── tracking/
│   ├── cubit/
│   │   ├── live_tracking_cubit.dart
│   │   ├── live_tracking_state.dart
│   │   └── live_tracking_cubit_factory.dart
│   ├── live_map_page.dart
│   ├── live_tracking_session_holder.dart        (@lazySingleton)
│   ├── tracking_location_settings.dart           (distance filter 12m, interval 4s)
│   ├── participants/participants_placeholder_page.dart
│   └── widgets/
├── attendees/
│   ├── attendees_cubit.dart
│   ├── attendees_page.dart
│   └── widgets/
├── delete/
│   └── cubit/event_delete_cubit.dart
├── drafts/
│   └── my_drafts_page.dart
└── shared/
    ├── dialogs/cancel_registration_dialog.dart
    └── widgets/
        ├── initials_avatar.dart
        └── registration_status_chip.dart
```

---

## 5. Cubits y estados

| Cubit | Archivo | DI | Estado | Notas |
|---|---|---|---|---|
| `EventsCubit` | `list/events_cubit.dart` | manual | `ResultState<List<EventModel>>` | Dos factories: `EventsCubit(GetEventsUseCase)` y `.myEvents(GetMyEventsUseCase)` |
| `EventFormCubit` | `form/cubit/event_form_cubit.dart` | `@injectable` | `EventFormState` (freezed) | save + cover IA + waypoints + tipo de ruta |
| `EventDetailCubit` | `detail/cubit/event_detail_cubit.dart` | manual | `EventDetailState` (freezed) | event + registration + lastUpdated |
| `EventDeleteCubit` | `delete/cubit/event_delete_cubit.dart` | `@injectable` | `ResultState<String>` | Emite `eventId` al borrar |
| `AttendeesCubit` | `attendees/attendees_cubit.dart` | manual | `ResultState<List<EventRegistrationModel>>` | Optimistic approve/reject con rollback |
| `LiveTrackingCubit` | `tracking/cubit/live_tracking_cubit.dart` | factory custom | `LiveTrackingState` (freezed) | Ver §6 |

### `EventsCubit`

**Estado interno:**
```
_allEvents: List<EventModel>
_filters: EventFilters
_searchQuery: String
```

**`EventFilters`** (value class):
```
types: Set<EventType>
difficulties: Set<EventDifficulty>
city: String?
startDate / endDate: DateTime?
freeOnly: bool
multiBrandOnly: bool
```

**Filtros**:
- **Server-side** (en `getEvents` query): `type`, `dateFrom`, `dateTo`, `city`.
- **Client-side** (en `_applyFiltersAndEmit`): `difficulties`, `freeOnly`, `multiBrandOnly`, `searchQuery`.

**Mutaciones locales (sin re-fetch):**
- `addEvent(EventModel)` — prepend a cache.
- `updateEvent(EventModel)` — reemplaza in-place por id.
- `removeEvent(String eventId)` — filtra del cache.
- `startEvent(EventModel)` — actualiza via API, si éxito → `updateEvent` local.

> `_applyFiltersAndEmit()` primero emite `ResultState.initial()` y luego el dato filtrado. Esto fuerza rebuild incluso si el dato resultante es idéntico (workaround para `Equatable`).

### `EventFormState` (freezed)
```dart
ResultState<EventModel> saveResult;
ResultState<String> coverGenerationResult;
List<String> waypoints;
List<AddressLocation?> waypointLocations;
RouteType routeType;
String? meetingPointName, destinationName;
AddressLocation? meetingPointLocation, destinationLocation;
```

Métodos clave:
- `initialize({event?})` — modo create/edit + detecta routeType.
- `setRoute({meetingPointName, destinationName, locations})`.
- `addWaypoint(String)` (max 9), `setWaypointLocation(i, AddressLocation?)`, `removeWaypoint(i)`, `setRouteType(type)`, `clearWaypoints()`.
- `_buildRouteGeoJson(RouteType)` → `{routeType, points: [{lat, lng, label}]}`.
- `saveEvent(event, {localCoverImagePath?, remoteCoverImageUrl?})`.
- `generateCover({title, eventType, city})`, `resetCoverGeneration()`.
- `buildEventToSave() → EventModel?` — valida y construye.
- `buildDraftToSave() → EventModel?` — solo requiere `name`.
- `saveDraft({localCoverImagePath?, remoteCoverImageUrl?})`.

### `EventDetailState` (freezed)
```dart
ResultState<EventRegistrationModel?> registrationResult;
ResultState<EventModel> eventResult;
ResultState<List<EventRegistrationModel>> attendeesResult;   // gestión de inscritos desde el detalle
ResultState<EventModel>? lastUpdatedEventResult;             // one-shot: consumir y limpiar
```

Métodos:
- `loadEvent(id)`, `loadMyRegistration(eventId)`.
- `cancelRegistration(registrationId)`, `updateRegistration(EventRegistrationModel)`.
- `startEvent(event)`, `publishEvent(event)`, `stopEvent(event)`.
- **Gestión de inscritos (desde el detalle):** `approveAttendee(id)`, `rejectAttendee(id)` y `setAttendeeReadyForEdit(id)` — todos **optimistas** vía `_updateAttendeeStatusLocally` (cambian el estado local primero con `unawaited(useCase)`). Soporta **solicitar edición** además de aprobar/rechazar.
- `clearLastUpdatedEvent()` — para liberar el canal one-shot.

> `_updateAttendeeStatusLocally` actualiza la lista sin refetch, pero como `EventRegistrationModel.==` compara **solo por id**, emite un estado intermedio (`ResultState.initial()`) antes del nuevo `data` para forzar el rebuild de Bloc (la deep equality no detectaría el cambio de `status`).

### `LiveTrackingState` (freezed)
```dart
ResultState<List<RiderTrackingModel>> ridersResult;
bool isTracking;                         // GPS activo
double totalDistanceMeters;              // del dispositivo actual
double? currentUserLatitude, currentUserLongitude;
ResultState<SosAlertModel?> sosAlertResult;
bool hasSentSos;                         // ya envió SOS este usuario
bool isFinished;                         // organizador terminó → auto-pop
```

### `AttendeesCubit`

Métodos:
- `fetchAttendees(eventId)`.
- `approveRegistration(id)` — **optimistic con rollback**: cambia el state local primero (`_updateRegistrationStatusLocally` devuelve el estado previo), espera la API y, si falla, revierte al estado anterior.
- `rejectRegistration(id)` — idem.
- `setReadyForEdit(id)` — espera resultado y refetcha.

---

## 6. Flujo de tracking en vivo

### Capas

```
LiveTrackingCubit
    │
    ├─ GPS (geolocator)           → posición cada N segundos (filter 12m, interval 4s)
    │                               throttle ≥ 4s entre pushes al backend
    │
    ├─ StartTrackingUseCase       → POST /events/:id/tracking/session/start (HTTP)
    │                               registra al rider en el snapshot
    │
    ├─ UpdateLocationUseCase      → TrackingWsClient.publishLocation()
    │                               WS message type: tracking.location.update
    │
    ├─ WatchActiveRidersUseCase   → TrackingRepositoryImpl.watchActiveRiders()
    │   │                          (Stream.multi: snapshot HTTP inicial + WS updates)
    │   └─ TrackingWsClient        → WebSocket wss://…/tracking/ws?eventId=…&token=…
    │
    └─ StopTrackingUseCase        → WS tracking.leave + POST session/stop
```

### Mensajes WebSocket

| Dirección | Tipo | Descripción |
|---|---|---|
| client → server | `tracking.join` | unirse a sesión del evento |
| client → server | `tracking.location.update` | lat/lng/speed/distance/battery |
| client → server | `tracking.sos` | alerta SOS |
| client → server | `tracking.sos.cancel` | el rider desactiva su propio SOS |
| client → server | `tracking.leave` | salida limpia |
| server → client | `tracking.snapshot` | estado completo de todos los riders |
| server → client | `tracking.rider.updated` | actualización de un rider |
| server → client | `tracking.rider.left` | rider salió |
| server → client | `tracking.sos.alert` | SOS broadcast (también dirigido solo al cliente que se une si hay un SOS activo) |
| server → client | `tracking.sos.cleared` | un SOS fue cancelado (`{ userId }`) |
| server → client | `tracking.event.ended` | organizador terminó |

> **SOS y late-joiners:** el gateway mantiene una caché en memoria del SOS activo por evento (`activeSosByEvent`). Al unirse a un evento con SOS activo, el servidor reenvía `tracking.sos.alert` **dirigido solo a ese cliente** (después del snapshot), y lo borra al recibir `tracking.sos.cancel`. La caché se pierde si el proceso del gateway se reinicia (la BD solo guarda `sosTriggeredAt`, sin el rider id).

### `TrackingWsClient` (`@lazySingleton`)

- **Cache** `_ridersByUserId: Map<String, RiderTrackingModel>` actualizado por cada mensaje, emitido como lista al stream.
- **Streams broadcast**: `_ridersController`, `_sosController`, `_sosClearedController`, `_eventEndedController` — soportan múltiples listeners.
- **Reconexión automática 2s** si la conexión se cae sin desconexión manual.
- **Snapshot inicial HTTP** via `TrackingService.snapshot()` antes del primer mensaje WS.
- **URI WS**: `parsedBase.scheme == 'https' ? 'wss' : 'ws'`, path `${baseUrl}/tracking/ws`, query `eventId=…&token=…`.

### `LiveTrackingSessionHolder` — keep-alive
```dart
@lazySingleton
class LiveTrackingSessionHolder {
  LiveTrackingCubit? _cubit;
  String? _eventId;

  LiveTrackingCubit obtainForEvent({eventId, eventOwnerId}) { ... }
  void stopSessionForEvent(String eventId) { ... }
}
```

**Por qué existe:** cuando el usuario navega fuera de `LiveMapPage`, el cubit NO se cierra. El GPS y la sesión WS continúan activos hasta que el organizador termine la rodada o el usuario cierre sesión.

### Throttling backend push

```dart
if (now.difference(_lastBackendPush!) < const Duration(seconds: 4)) {
  // solo actualiza estado local, no envía al WS
  emit(state.copyWith(totalDistanceMeters: ..., currentUserLatitude: ...));
  return;
}
```

GPS updates a la UI = inmediato. WS push = max cada 4s.

### Roles

- `RiderTrackingRole.lead` → `user.id == eventOwnerId`.
- `RiderTrackingRole.rider` → cualquier otro.

El lead se distingue por el estilo de su marcador (ver Marcadores). El control "Terminar rodada" **no** vive en el mapa: el organizador termina la rodada desde el detalle del evento (`EventDetailOwnerLiveBar`).

### Marcadores de riders en el mapa (`InitialsMarkerIcon` + `LiveMapWidget`)

Tres variantes (`RiderMarkerVariant`), renderizadas a PNG y registradas como *style image* de Mapbox por nombre estable (`rider_marker_<userId>`), con `scale = devicePixelRatio` para tamaño correcto/nítido:

- **lead** (48 px): relleno acento sólido, iniciales oscuras, glow naranja (gradiente radial contenido, no `MaskFilter`) + badge de corona.
- **rider** (44 px): relleno `accent-subtle`, borde acento, iniciales acento, glow tenue.
- **sos** (48 px): relleno/borde/glow rojo (el rider cuyo `userId == sosAlert.userId`).

Mover un marcador solo muta su geometría (no re-registra imagen → sin churn ni duplicados). `_updateAnnotations` está serializado (guard de re-entrada) para evitar marcadores duplicados al moverse rápido.

**Cámara:** viewport estable (no re-snap en cada update). El botón centrar activa *follow* (persigue al usuario, zoom por defecto 16); panear con el dedo (`onScrollListener`) lo desactiva. Tap en un marcador o en una tarjeta de telemetría → centra ese rider y se sincroniza la selección (resalte + scroll en la lista).

### Flujo SOS

```
Rider tap SOS → SosConfirmDialog
  → LiveTrackingCubit.triggerSos() → TrackingRepository.publishSos() → WS 'tracking.sos'
  → hasSentSos = true (botón en estado activo)

Otros riders reciben 'tracking.sos.alert' → sosAlertResult = Data(SosAlertModel)
  → SosBanner compacto (nombre real resuelto en backend + teléfono),
    marcador rojo en el mapa y tarjeta roja en Rider Telemetry.
  → "Localizar" abre un AppModal: Centrar en el mapa | Abrir en Google Maps.

Cancelar: el botón SOS sigue tappable estando activo → ConfirmationDialog (danger/rojo)
  → LiveTrackingCubit.cancelSos() → WS 'tracking.sos.cancel'
  → backend difunde 'tracking.sos.cleared' → todos limpian el banner/marcador.
```

> El nombre del rider en el SOS (banner + push FCM) lo resuelve el backend (`events-ms`): registro del evento → `users-ms` → parte del email → `"Un rider"`. Nunca el UUID.

### Flujo de finalización por organizador

```
Lead tap "Terminar rodada" → EndRideConfirmDialog
  → LiveTrackingCubit.endRide(eventId)
     → TrackingRepository.endRide() → POST /events/:id/tracking/end
     → WS broadcast 'tracking.event.ended'
  → Todos: isFinished = true → auto-pop de LiveMapPage
  → EventDetailCubit.stopEvent() actualiza state local a finished
  → LiveTrackingSessionHolder.stopSessionForEvent() → cierra cubit
```

---

## 7. Sub-features

### Lista (`/events`, `/events/mine`)
`EventsCubit` con dos factories. Filtros server + client. Optimistic add/update/remove. Pull-to-refresh dispara `fetchEvents()`.

### Formulario (`/events/create`, `/events/edit`)
`EventFormPage` → provee `EventFormCubit` + `FormImageCubit`. `EventFormView` orquesta secciones:

1. Cover (local o IA via `generateCover`).
2. Basic info: name + description (Quill) + city.
3. Date/time: rango + toggle multi-day + meetingTime.
4. Locations: tipo de ruta + meeting + destination (o constructor custom).
5. Difficulty: 1–5 chiles.
6. Event type: chips.
7. Multi-brand: toggle + selector.
8. Max participants.
9. Price.

Constantes en `EventFormFields` (clase abstracta con string constants).

### Constructor de ruta personalizada (`form/screens/event_route_config_screen.dart`)
- Hasta 9 waypoints.
- Búsqueda textual (`PlaceService` Mapbox Geocoding) o "Seleccionar en mapa" (pin centrado + geocoding inverso).
- Renderiza pin numerado (verde primer, naranja resto) + polyline naranja (`#F98C1F`).
- `cameraForCoordinatesPadding` ajusta la cámara para mostrar todos los puntos.

### Detalle (`/events/detail`, `/events/detail-by-id`)
- `EventDetailPage` recibe `EventModel` completo.
- `EventDetailByIdPage` recibe `String id`, llama `loadEvent()` (usado en deep links).
- `EventDetailView` mantiene `currentEvent` mutable local; listener de `lastUpdatedEventResult` lo sincroniza.
- Owner ve `EventDetailOwnerLifecycleBar` (start/stop/publish/mapa); rider ve `EventDetailCTABar` (inscribirse/seguir/cancelar según estado).
- `PopScope` custom: si viene desde lista, pop retorna `EventModel` actualizado para refrescar el cache de la lista sin re-fetch.

### Asistentes (`/events/attendees`) — "Gestionar Inscritos" (Pencil `IUxas`)
`AttendeesCubit` con optimistic approve/reject (con rollback). UI alineada al diseño:
- AppBar con título + badge naranja del conteo de pendientes (`AttendeesView._pendingCount`).
- `AttendeesDataView`: buscador (`AppSearchBar`) + `AttendeesFilterChips` **inline** (Todos / Pendientes / Aprobados / Rechazados) — reemplaza el antiguo botón de filtros + `AttendeesFilterBottomSheet` (eliminado).
- `AttendeesList`: dos secciones con `AttendeesSectionHeader` + badge de conteo (NUEVAS SOLICITUDES amarillo, YA PROCESADOS neutral).
  - Pendientes: `AttendeePendingRequestCard` (avatar + nombre + vehículo + `RegistrationStatusPill` + barra Aprobar/Rechazar inline).
  - Procesados: `AttendeeProcessedItem` con badge de estado sutil (fondo translúcido + texto coloreado).

### Live tracking (`/events/live-map`)
Ver §6.

### Borradores (`/events/drafts`)
`MyDraftsPage` usa `EventsCubit.myEvents` con filtro local `EventState.draft`. Continúa edición via `editEvent`.

---

## 8. Rutas de navegación

```dart
AppRoutes.events              → '/events'
AppRoutes.myEvents            → '/events/mine'
AppRoutes.myDrafts            → '/events/drafts'
AppRoutes.createEvent         → '/events/create'
AppRoutes.editEvent           → '/events/edit'           extra: EventModel?
AppRoutes.eventDetail         → '/events/detail'         extra: EventModel
AppRoutes.eventDetailById     → '/events/detail-by-id'   extra: String | query 'id'
AppRoutes.eventAttendees      → '/events/attendees'      extra: EventModel
AppRoutes.liveMap             → '/events/live-map'       extra: EventModel
AppRoutes.participants        → '/events/participants'   extra: EventModel
AppRoutes.eventRegistration   → '/events/registration'   extra: EventRegistrationParams   (feature event_registration)
AppRoutes.myRegistrations     → '/events/my-registrations'                                (feature event_registration)
AppRoutes.registrationDetail  → '/events/registration-detail'  extra: RegistrationDetailExtra (feature event_registration)
AppRoutes.riderProfile        → '/events/attendees/rider-profile'  extra: String userId   (feature users)
```

**Consideraciones:**
- `EventDetailByIdPage` admite `eventId` por query string (`?id=xxx`) o por `extra`.
- Guard de `AppRouter.redirect`: si la ruta es `eventRegistration` y el usuario es el owner del evento, se redirige a `eventDetailById?id=...`.

---

## 9. API endpoints

### Eventos
| Método | Endpoint |
|---|---|
| `GET` | `/events` (query: `type`, `dateFrom`, `dateTo`, `city`) |
| `GET` | `/events/my` |
| `GET` | `/events/:id` |
| `POST` | `/events` |
| `PATCH` | `/events/:id` |
| `DELETE` | `/events/:id` |
| `PATCH` | `/events/:id/publish` |

### Tracking
| Método | Endpoint |
|---|---|
| `POST` | `/events/:id/tracking/start` (state → inProgress) |
| `POST` | `/events/:id/tracking/end` (state → finished) |
| `POST` | `/events/:id/tracking/session/start` |
| `POST` | `/events/:id/tracking/session/stop` |
| `GET` | `/events/:id/tracking/snapshot` |
| WS | `/tracking/ws?eventId=…&token=…` |

Definidos en `lib/core/http/api_routes.dart` (`ApiRoutes.events`, `eventTrackingStart(id)`, etc.).

---

## 10. Conexiones con otros features

| Feature | Conexión |
|---|---|
| `event_registration` | Importa `EventModel`; `EventDetailCubit` lee la inscripción del usuario actual. CTA "Inscribirse" navega a `eventRegistration` |
| `vehicles` | Vehículo se asocia a la inscripción del evento (en feature `event_registration`) |
| `users` | `RiderProfilePage` se navega desde `AttendeesPage` para ver un asistente |
| `home` | `HomeData.upcomingEvents` reutiliza `EventDto` y `EventModel` |
| `notifications` | Tipos `newRegistration`, `registrationApproved`, `registrationRejected`, eventos del SOS y tracking |

---

## 11. Patrones y trampas conocidas

### `EventDto extends EventModel`
Patrón inusual: el DTO hereda del modelo. Permite `EventDto.fromJson` + `EventModelExtension.toJson` sin castear manualmente.

### Igualdad por `id` solamente
`EventModel ==` compara solo `id`. Dos eventos con `id == null` (no persistidos) se consideran iguales. **No usar `Set<EventModel>` o `List.contains()` con objetos no persistidos.**

### `routeGeoJson` y `waypoints` duplican información
- `waypoints: List<String>` — nombres textuales.
- `routeGeoJson['points']` — coordenadas.

Para detectar ruta custom: `waypoints.isNotEmpty || routeGeoJson?['routeType'] == 'custom'`.

### `_applyFiltersAndEmit` emite `initial` antes del dato
```dart
emit(const ResultState.initial());
emit(ResultState.data(data: filtered));
```
Workaround para forzar rebuild cuando el dato resultante es idéntico al anterior.

### `AttendeesCubit` approve/reject es optimista con rollback
`_updateStatusOptimistically` cambia el state local y luego espera la API; en `Left` revierte al estado previo. Ya no usa `unawaited`. La confirmación visual al usuario sigue siendo inmediata (optimista).

### `LiveTrackingCubit` no se registra en DI directamente
Se crea via `LiveTrackingCubitFactory` que inyecta todas las dependencias. El acceso pasa por `LiveTrackingSessionHolder`.

### `MyRegistrationsCubit` — N+1 evento (en event_registration)
Documentado en [event_registration.md §15](./event_registration.md#15-conexión-con-events-n1). Cada inscripción dispara un `getEventById` para enriquecer.

### `EventDetailView.currentEvent` mutable
Estado local de `State<EventDetailView>` sincronizado con `lastUpdatedEventResult` del cubit. Si refactorizas, mantener la sincronización.

### `TrackingWsClient.publishSos` usa null-aware map literal
```dart
{
  'latitude': ?latitude,
  'longitude': ?longitude,
}
```
Sintaxis de Dart 3.x: si `latitude` es null, la key se omite. **Válida**, no es bug. Sin embargo no funciona en versiones anteriores a Dart 3.

### Conversor de dificultad acepta `int` o `String`
`EventDifficultyConverter` admite valores `1..5` o strings `EASY/MODERATE/MEDIUM/HARD/VERY_HARD`. Si la API cambia el formato, ambos casos están cubiertos.

### Firebase Storage path para nueva creación
Antes de tener `eventId`, sube a `events/{ownerId}-{microseconds}/cover.jpg`. Permite múltiples versiones antes de persistir el evento. Limpiar archivos huérfanos sería un tema aparte (cron en backend).

### `getMyEvents` no acepta filtros
A diferencia de `getEvents`, `getMyEvents` no recibe query params. Todos los filtros para mis eventos se aplican client-side en `_applyFiltersAndEmit`.

### Live tracking sin manejo de error de WS
Si la conexión WS no se puede establecer (token expirado, sin red), `_ridersController.addError(StateError(...))`. La UI puede mostrar error pero no hay UI explícita de reintentar — depende del `2s reconnect`.

### Geolocator distance filter 12m + interval Android 4s
Ver `tracking_location_settings.dart`. Si se cambian estos valores, ajustar el throttle del cubit para evitar desbalance entre datos locales y servidor.

### Apple sign-in es stub
Mencionado en `authentication.md`. No es directamente del feature events, pero `AuthCubit` lo usa al autenticar para poder tracking.

### `EventState` default es `scheduled`
Si se omite el campo en el modelo (creación nueva sin pasar state), defaultea a `scheduled`. Para crear un borrador, hay que setearlo explícitamente a `EventState.draft`.

---

## 12. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Modelo del evento + enums | `lib/features/events/domain/model/event_model.dart` |
| Modelo tracking | `lib/features/events/domain/model/rider_tracking_model.dart` |
| Modelo SOS | `lib/features/events/domain/model/sos_alert_model.dart` |
| Repo events interface | `lib/features/events/domain/repository/event_repository.dart` |
| Repo tracking interface | `lib/features/events/domain/repository/tracking_repository.dart` |
| Use cases | `lib/features/events/domain/use_cases/` |
| Service events Retrofit | `lib/features/events/data/service/event_service.dart` |
| Service tracking (Dio manual) | `lib/features/events/data/service/tracking_service.dart` |
| WS client | `lib/features/events/data/service/tracking_ws_client.dart` |
| Service cover IA | `lib/features/events/data/service/event_cover_service.dart` |
| DTO eventos | `lib/features/events/data/dto/event_dto.dart` |
| Converters de enums | `lib/features/events/data/dto/event_dto_converters.dart` |
| Cubit lista | `lib/features/events/presentation/list/events_cubit.dart` |
| Cubit formulario | `lib/features/events/presentation/form/cubit/event_form_cubit.dart` |
| Estado del form | `lib/features/events/presentation/form/cubit/event_form_state.dart` |
| Constructor de ruta | `lib/features/events/presentation/form/screens/event_route_config_screen.dart` |
| Cubit detalle | `lib/features/events/presentation/detail/cubit/event_detail_cubit.dart` |
| View detalle (PopScope) | `lib/features/events/presentation/detail/event_detail_view.dart` |
| Page detalle por id | `lib/features/events/presentation/detail/event_detail_by_id_page.dart` |
| Cubit live tracking | `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart` |
| Estado live tracking | `lib/features/events/presentation/tracking/cubit/live_tracking_state.dart` |
| Factory del cubit tracking | `lib/features/events/presentation/tracking/cubit/live_tracking_cubit_factory.dart` |
| Session holder keep-alive | `lib/features/events/presentation/tracking/live_tracking_session_holder.dart` |
| Settings de location | `lib/features/events/presentation/tracking/tracking_location_settings.dart` |
| Page live map | `lib/features/events/presentation/tracking/live_map_page.dart` |
| Cubit asistentes | `lib/features/events/presentation/attendees/attendees_cubit.dart` |
| Cubit borrar | `lib/features/events/presentation/delete/cubit/event_delete_cubit.dart` |
| Page borradores | `lib/features/events/presentation/drafts/my_drafts_page.dart` |
| Constantes del form | `lib/features/events/constants/event_form_fields.dart` |
| Endpoints API | `lib/core/http/api_routes.dart` |
| Rutas app | `lib/shared/router/app_routes.dart` |
