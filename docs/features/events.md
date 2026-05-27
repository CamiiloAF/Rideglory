# Documentación del Feature: Eventos & Registro

> Última actualización: 2026-05-26  
> Alcance: `lib/features/events/` y `lib/features/event_registration/`

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Ciclo de vida de un evento](#3-ciclo-de-vida-de-un-evento)
4. [Arquitectura por capas](#4-arquitectura-por-capas)
   - 4.1 [Domain — Events](#41-domain--events)
   - 4.2 [Data — Events](#42-data--events)
   - 4.3 [Presentation — Events](#43-presentation--events)
   - 4.4 [Domain — Event Registration](#44-domain--event-registration)
   - 4.5 [Data — Event Registration](#45-data--event-registration)
   - 4.6 [Presentation — Event Registration](#46-presentation--event-registration)
5. [Cubits y estados — mapa completo](#5-cubits-y-estados--mapa-completo)
6. [Flujo de tracking en vivo](#6-flujo-de-tracking-en-vivo)
7. [Rutas de navegación](#7-rutas-de-navegación)
8. [API endpoints](#8-api-endpoints)
9. [Sub-features en detalle](#9-sub-features-en-detalle)
   - 9.1 [Lista de eventos (`/events`)](#91-lista-de-eventos-events)
   - 9.2 [Formulario de evento](#92-formulario-de-evento)
   - 9.3 [Constructor de ruta personalizada](#93-constructor-de-ruta-personalizada)
   - 9.4 [Detalle de evento](#94-detalle-de-evento)
   - 9.5 [Formulario de inscripción](#95-formulario-de-inscripción)
   - 9.6 [Gestión de asistentes (organizador)](#96-gestión-de-asistentes-organizador)
   - 9.7 [Live Tracking (mapa en vivo)](#97-live-tracking-mapa-en-vivo)
   - 9.8 [Mis inscripciones](#98-mis-inscripciones)
   - 9.9 [Mis borradores](#99-mis-borradores)
10. [Patrones y trampas conocidas](#10-patrones-y-trampas-conocidas)
11. [Archivos clave de referencia rápida](#11-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

El feature de **Eventos** es el núcleo de Rideglory. Permite a los organizadores crear, publicar y gestionar rodadas de motociclismo; y a los riders explorar, inscribirse y seguir el evento en tiempo real.

Se divide en **dos features Flutter** con sus propias carpetas:

| Feature Flutter | Responsabilidad |
|---|---|
| `events/` | CRUD de eventos, listado/filtrado, detalle, tracking en vivo |
| `event_registration/` | Inscripción de riders, aprobación/rechazo por organizador, historial |

Ambos features comparten modelos: `EventModel` (definido en `events/domain/`) es importado por `event_registration/`.

---

## 2. Modelo de dominio

### `EventModel`
> `lib/features/events/domain/model/event_model.dart`

```
EventModel
  id: String?              — null si aún no persiste (nuevo o borrador sin guardar)
  ownerId: String          — userId Firebase del organizador
  name: String
  description: String      — rich-text (almacenado como JSON de Quill Delta)
  city: String
  startDate: DateTime
  endDate: DateTime?       — null = evento de un solo día
  difficulty: EventDifficulty  (1–5 chiles)
  meetingPoint: String     — nombre textual del punto de encuentro
  destination: String      — nombre textual del destino
  meetingTime: DateTime    — hora de concentración (ignora la fecha, solo hora)
  eventType: EventType
  allowedBrands: List<String>  — vacío = multi-marca
  price: int?              — null o 0 = gratis
  maxParticipants: int?    — null = sin límite
  imageUrl: String?        — URL en Firebase Storage
  state: EventState        — ciclo de vida (ver §3)
  waypoints: List<String>  — nombres de waypoints (ruta custom)
  routeGeoJson: Map?       — {routeType, points: [{lat, lng, label}]}
```

**Getters calculados:**
- `isFree` → `price == null || price == 0`
- `isMultiBrand` → `allowedBrands.isEmpty`
- `isMultiDay` → `endDate != null`
- `routePoints` → parsea `routeGeoJson.points` → `List<AddressLocation>`

**Igualdad:** basada únicamente en `id` (dos instancias con mismo `id` son iguales).

---

### `EventType` (enum)
```
tourism, urban, offRoad, competition, solidarity, shortDistance
```
Cada valor tiene un `label` en español para mostrar en la UI.

---

### `EventDifficulty` (enum)
```
one(1, 'Fácil 🌶', 'FÁCIL')  …  five(5, 'Muy difícil 🌶🌶🌶🌶🌶', 'MUY DIFÍCIL')
```
Serializado como entero (`value`). `fromValue(int)` hace la conversión inversa.

---

### `EventState` (enum)
```
draft → scheduled → inProgress → finished
                  ↘ cancelled
```
Ver §3 para las transiciones permitidas.

---

### `EventRegistrationModel`
> `lib/features/event_registration/domain/model/event_registration_model.dart`

```
EventRegistrationModel
  id: String?
  eventId: String
  eventName: String
  userId: String
  status: RegistrationStatus      (pending, approved, rejected, cancelled, readyForEdit)
  fullName / identificationNumber / birthDate / phone / email / residenceCity
  eps / medicalInsurance? / bloodType: BloodType
  emergencyContactName / emergencyContactPhone
  vehicleId: String?              — ID del vehículo seleccionado
  vehicleSummary: VehicleSummaryModel?   — placa + marca (snapshot)
  createdAt / updatedAt
```

---

### `RiderTrackingModel`
> `lib/features/events/domain/model/rider_tracking_model.dart`

Snapshot en tiempo real de un rider dentro de la sesión de tracking:

```
userId / fullName / role: RiderTrackingRole (lead | rider)
latitude / longitude / speedKmh / distanceMeters
batteryPercent / isActive / deviceLabel / lastUpdated
```

---

### `RiderProfileModel`
> `lib/features/events/domain/model/rider_profile_model.dart`

Datos del rider guardados para pre-llenar futuras inscripciones:
```
userId, fullName, identificationNumber, birthDate, phone, email,
residenceCity, eps, medicalInsurance, bloodType,
emergencyContactName, emergencyContactPhone
```
Se persiste en backend via `SaveRiderProfileUseCase`. Al crear/editar inscripción se carga con `GetRiderProfileUseCase` y se usa para pre-rellenar el form.

---

### `SosAlertModel`
```
userId / riderName / latitude? / longitude? / phone?
```
Broadcast por WebSocket tipo `tracking.sos.alert`.

---

## 3. Ciclo de vida de un evento

```
[NUEVA CREACIÓN]
     │
     ▼
  draft  ──────────── publishEvent() ──────────────▶  scheduled
     │                                                    │
     │ (también se puede guardar directamente             │ startEvent() (organizador)
     │  como scheduled si se publica al guardar)          ▼
     │                                               inProgress
     │                                                    │
     │                                                    │ stopEvent() (organizador)
     │                                                    ▼
     │                                               finished
     │
     └──── (se puede eliminar mientras sea draft o scheduled)
```

**Transiciones de estado:**
| Acción | Método Cubit | Endpoint API | Restricción |
|---|---|---|---|
| Guardar borrador | `EventFormCubit.saveDraft()` | `POST/PATCH /events` | `state=draft`, solo requiere `name` |
| Publicar desde detalle | `EventDetailCubit.publishEvent()` | `PATCH /events/:id/publish` | Solo owner |
| Iniciar rodada | `EventDetailCubit.startEvent()` | `PATCH /events/:id` (state=inProgress) | Solo owner, estado actual = scheduled |
| Finalizar rodada | `EventDetailCubit.stopEvent()` | `PATCH /events/:id` (state=finished) | Solo owner, estado actual = inProgress |
| Eliminar | `EventDeleteCubit.deleteEvent()` | `DELETE /events/:id` | Solo owner |

---

## 4. Arquitectura por capas

### 4.1 Domain — Events
```
lib/features/events/domain/
├── model/
│   ├── event_model.dart              ← modelo principal
│   ├── rider_tracking_model.dart
│   ├── rider_profile_model.dart
│   ├── sos_alert_model.dart
│   ├── update_location_request.dart  ← payload WS de ubicación
│   └── upload_event_image_request.dart
├── repository/
│   ├── event_repository.dart         ← interfaz CRUD + upload
│   ├── tracking_repository.dart      ← interfaz tracking
│   ├── event_cover_repository.dart   ← interfaz cover AI
│   └── rider_profile_repository.dart
└── use_cases/
    ├── create_event_use_case.dart
    ├── update_event_use_case.dart
    ├── delete_event_use_case.dart
    ├── get_events_use_case.dart       ← con filtros opcionales
    ├── get_my_events_use_case.dart
    ├── get_event_by_id_use_case.dart
    ├── publish_event_use_case.dart
    ├── upload_event_image_use_case.dart
    ├── get_generate_cover_use_case.dart  ← genera cover con IA
    ├── start_tracking_use_case.dart
    ├── stop_tracking_use_case.dart
    ├── update_location_use_case.dart
    ├── watch_active_riders_use_case.dart ← retorna Stream
    ├── get_rider_profile_use_case.dart
    └── save_rider_profile_use_case.dart
```

**Contratos de repositories:**

`EventRepository`:
```dart
getEvents({type?, dateFrom?, dateTo?, city?}) → Either<DomainException, List<EventModel>>
getMyEvents()                                  → Either<…, List<EventModel>>
getEventById(String id)                        → Either<…, EventModel>
createEvent(EventModel)                        → Either<…, EventModel>
updateEvent(EventModel)                        → Either<…, EventModel>   // requiere id != null
deleteEvent(String id)                         → Either<…, Nothing>
uploadEventImage(UploadEventImageRequest)      → Either<…, String>       // retorna URL
publishEvent(String id)                        → Either<…, EventModel>
```

`TrackingRepository`:
```dart
watchActiveRiders(String eventId)              → Stream<List<RiderTrackingModel>>
startTracking({eventId, initialData})          → Future<Either<…, Nothing>>
updateLocation(UpdateLocationRequest)          → Future<Either<…, Nothing>>
stopTracking({eventId, userId})                → Future<Either<…, Nothing>>
endRide(String eventId)                        → Future<Either<…, Nothing>>
publishSos({eventId, userId, lat?, lng?})      → void
sosAlerts                                      → Stream<SosAlertModel>
eventEnded                                     → Stream<void>
```

---

### 4.2 Data — Events
```
lib/features/events/data/
├── dto/
│   ├── event_dto.dart                ← extends EventModel (patrón DTO-hereda-modelo)
│   ├── event_dto.g.dart              ← generado
│   ├── event_dto_converters.dart     ← converters Freezed para enums
│   ├── cover_generation_dto.dart
│   ├── rider_tracking_dto.dart
│   └── rider_profile_dto.dart
├── repository/
│   ├── event_repository_impl.dart    ← @Injectable(as: EventRepository)
│   ├── tracking_repository_impl.dart ← @Injectable(as: TrackingRepository)
│   ├── event_cover_repository_impl.dart
│   └── rider_profile_repository_impl.dart
└── service/
    ├── event_service.dart            ← @singleton @RestApi() Retrofit
    ├── event_service.g.dart
    ├── event_cover_service.dart      ← @singleton @RestApi()
    ├── tracking_service.dart         ← @singleton Dio manual (no Retrofit)
    └── tracking_ws_client.dart       ← @lazySingleton WebSocket
```

**Patrón DTO especial — `EventDto extends EventModel`:**

`EventDto` hereda de `EventModel` en lugar de ser una clase separada. Esto permite:
- `EventDto.fromJson()` para deserializar la respuesta del API.
- `EventModelExtension.toJson()` (extension) para serializar cualquier `EventModel` sin castear.
- Los `@JsonKey` ajustan nombres (`createdAt` → `createdDate`, etc.).
- `toJson()` sobreescribe las fechas con `apiEncodeRequiredDateTime` para el formato correcto.

**Imagen de portada — Firebase Storage:**
`EventRepositoryImpl.uploadEventImage()` sube directamente a Firebase Storage:
```
events/{eventId}/cover.jpg         (edición)
events/{ownerId}-{timestamp}/cover.jpg   (creación antes de tener ID)
```
Retorna la URL de descarga pública.

**Cover generada con IA:**
`EventCoverService` → `POST /events/generate-cover` con `{title, eventType, city}`.  
Retorna `CoverGenerationDto` con la URL de la imagen generada.

---

### 4.3 Presentation — Events

#### Sub-secciones de presentación:

```
lib/features/events/presentation/
├── list/                     ← Listado + filtros
│   ├── events_cubit.dart
│   ├── events_page.dart
│   └── widgets/
├── detail/                   ← Detalle de evento
│   ├── cubit/
│   │   ├── event_detail_cubit.dart
│   │   └── event_detail_state.dart
│   ├── event_detail_page.dart       ← recibe EventModel por extra
│   ├── event_detail_by_id_page.dart ← recibe String id por pathParam
│   ├── event_detail_view.dart       ← lógica + UI principal
│   ├── event_route_map_screen.dart  ← pantalla full-screen de ruta
│   └── widgets/
├── form/                     ← Crear/editar evento
│   ├── cubit/event_form_cubit.dart
│   ├── event_form_page.dart
│   ├── screens/event_route_config_screen.dart   ← constructor de ruta custom
│   └── widgets/
│       └── sections/         ← una sección de form por archivo
├── tracking/                 ← Live tracking
│   ├── cubit/
│   │   ├── live_tracking_cubit.dart
│   │   ├── live_tracking_state.dart
│   │   └── live_tracking_cubit_factory.dart
│   ├── live_map_page.dart
│   ├── live_tracking_session_holder.dart  ← @lazySingleton
│   └── widgets/
├── attendees/                ← Gestión de asistentes (owner)
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

### 4.4 Domain — Event Registration
```
lib/features/event_registration/domain/
├── model/
│   ├── event_registration_model.dart   ← modelo principal con RegistrationStatus, BloodType
│   ├── vehicle_summary_model.dart      ← snapshot placa+marca del vehículo
│   └── registration_with_event.dart   ← agregado para "Mis Inscripciones"
├── repository/
│   └── event_registration_repository.dart
└── use_cases/
    ├── add_event_registration_use_case.dart
    ├── update_event_registration_use_case.dart
    ├── cancel_event_registration_use_case.dart
    ├── get_event_registrations_use_case.dart   ← para el organizador
    ├── get_my_registration_for_event_use_case.dart
    ├── get_my_registrations_use_case.dart
    ├── approve_registration_use_case.dart
    ├── reject_registration_use_case.dart
    └── set_registration_ready_for_edit_use_case.dart
```

---

### 4.5 Data — Event Registration
```
lib/features/event_registration/data/
├── dto/
│   ├── event_registration_dto.dart    ← @JsonSerializable
│   └── vehicle_summary_dto.dart
├── repository/
│   └── event_registration_repository_impl.dart
└── service/
    └── registration_service.dart     ← Dio manual (no Retrofit)
```

`RegistrationService` es notable: acepta `saveToProfile: bool` en el body de create/update. Cuando es `true`, el backend persiste los datos del rider en su perfil.

---

### 4.6 Presentation — Event Registration
```
lib/features/event_registration/presentation/
├── cubit/
│   └── registration_form_cubit.dart   ← @injectable
├── event_registration_page.dart
├── my_registrations_cubit.dart        ← @injectable, global en MultiBlocProvider
├── my_registrations_page.dart
├── my_registrations_view.dart
├── my_registrations_data_view.dart
├── registration_form_content.dart
├── registration_form_view.dart
├── registration_detail_page.dart
├── registration_detail_extra.dart     ← params de navegación
└── widgets/
    ├── inscription_card.dart
    ├── vehicle_selector_field.dart    ← selector de vehículo del garage
    ├── vehicle_selector_empty.dart
    ├── vehicle_selector_loading.dart
    ├── save_to_profile_checkbox.dart
    ├── expandable_container.dart
    └── registration_detail_*.dart     ← secciones del detalle
```

---

## 5. Cubits y estados — mapa completo

| Cubit | Archivo | DI | Estado | Notas |
|---|---|---|---|---|
| `EventsCubit` | `list/events_cubit.dart` | manual (factory) | `ResultState<List<EventModel>>` | Soporta dos modos: `EventsCubit(...)` (todos) y `EventsCubit.myEvents(...)`. Tiene cache local `_allEvents` y filtrado en memoria |
| `EventFormCubit` | `form/cubit/event_form_cubit.dart` | `@injectable` | `EventFormState` (freezed) | `saveResult + coverGenerationResult + waypoints + routeType + locations` |
| `EventDetailCubit` | `detail/cubit/event_detail_cubit.dart` | manual | `EventDetailState` (freezed) | `eventResult + registrationResult + lastUpdatedEventResult` |
| `EventDeleteCubit` | `delete/cubit/event_delete_cubit.dart` | `@injectable` | `ResultState<String>` | Emite el `eventId` al terminar con éxito |
| `AttendeesCubit` | `attendees/attendees_cubit.dart` | manual | `ResultState<List<EventRegistrationModel>>` | Optimistic update en approve/reject |
| `LiveTrackingCubit` | `tracking/cubit/live_tracking_cubit.dart` | vía factory | `LiveTrackingState` (freezed) | No se registra en DI directamente; se crea via `LiveTrackingCubitFactory` |
| `RegistrationFormCubit` | `event_registration/presentation/cubit/` | `@injectable` | `ResultState<EventRegistrationModel>` | Pre-llena desde auth user → rider profile |
| `MyRegistrationsCubit` | `event_registration/presentation/` | `@injectable` + global | `ResultState<List<RegistrationWithEvent>>` | Declarado en `main.dart` `MultiBlocProvider`. Combina registrations + eventos |

### `EventFormState` — estructura detallada
```dart
@freezed
class EventFormState {
  ResultState<EventModel> saveResult;        // resultado del guardado
  ResultState<String> coverGenerationResult; // URL de cover generada
  List<String> waypoints;                    // nombres de waypoints (ruta custom)
  List<AddressLocation?> waypointLocations;  // coordenadas paralelas
  RouteType routeType;                       // simple | custom
  String? meetingPointName;
  String? destinationName;
  AddressLocation? meetingPointLocation;
  AddressLocation? destinationLocation;
}
```

### `EventDetailState` — estructura detallada
```dart
@freezed
class EventDetailState {
  ResultState<EventRegistrationModel?> registrationResult; // inscripción del usuario actual
  ResultState<EventModel> eventResult;                     // datos del evento
  ResultState<EventModel>? lastUpdatedEventResult;         // solo cuando hay start/stop/publish
}
```
`lastUpdatedEventResult` se usa como canal de one-shot: el listener en la UI lo consume y llama `clearLastUpdatedEvent()` inmediatamente.

### `LiveTrackingState` — estructura detallada
```dart
@freezed
class LiveTrackingState {
  ResultState<List<RiderTrackingModel>> ridersResult;
  bool isTracking;                    // GPS activo y sesión iniciada
  double totalDistanceMeters;         // distancia acumulada del device actual
  double? currentUserLatitude;
  double? currentUserLongitude;
  ResultState<SosAlertModel?> sosAlertResult;  // alerta SOS entrante
  bool hasSentSos;                    // si este usuario ya mandó SOS
  bool isFinished;                    // organizador finalizó la rodada → auto-pop
}
```

---

## 6. Flujo de tracking en vivo

### Arquitectura de capas del tracking

```
LiveTrackingCubit
    │
    ├─ GPS (geolocator)          → posición del device cada N segundos
    │                              máx 1 push al backend cada 4s
    │
    ├─ StartTrackingUseCase      → HTTP POST /events/:id/tracking/session/start
    │                              registra al rider en el snapshot
    │
    ├─ UpdateLocationUseCase     → TrackingWsClient.publishLocation()
    │                              mensaje WS tipo: tracking.location.update
    │
    ├─ WatchActiveRidersUseCase  → TrackingRepositoryImpl.watchActiveRiders()
    │   │                          (Stream multi: WS + snapshot HTTP inicial)
    │   └─ TrackingWsClient      → WebSocket wss://…/tracking/ws?eventId=…&token=…
    │
    └─ StopTrackingUseCase       → WS tracking.leave + HTTP POST session/stop
```

### Mensajes WebSocket (tipo `string` JSON)

| Dirección | Tipo | Descripción |
|---|---|---|
| cliente → servidor | `tracking.join` | unirse a la sesión del evento |
| cliente → servidor | `tracking.location.update` | lat/lng/speed/distance/battery |
| cliente → servidor | `tracking.sos` | alerta SOS del rider |
| cliente → servidor | `tracking.leave` | salida limpia de la sesión |
| servidor → cliente | `tracking.snapshot` | estado completo de todos los riders activos |
| servidor → cliente | `tracking.rider.updated` | actualización de un rider |
| servidor → cliente | `tracking.rider.left` | rider salió |
| servidor → cliente | `tracking.sos.alert` | SOS broadcast |
| servidor → cliente | `tracking.event.ended` | organizador terminó la rodada |

### `TrackingWsClient` — comportamiento interno

- **Singleton `@lazySingleton`:** una sola instancia por sesión de app.
- **Reconexión automática:** si el WS se desconecta inesperadamente, reintenta en 2 segundos. Se cancela si fue desconexión manual (`leaveSession`).
- **Cache en memoria `_ridersByUserId`:** Map<userId, RiderTrackingModel>. Se actualiza con cada mensaje y se emite como lista al stream.
- **Streams broadcast:** `_ridersController`, `_sosController`, `_eventEndedController` — todos broadcast para soportar múltiples listeners.
- **Snapshot inicial HTTP:** `TrackingRepositoryImpl` pide el snapshot vía `TrackingService.snapshot()` para no esperar el primer mensaje WS.

### `LiveTrackingSessionHolder` — keep-alive del cubit

```dart
@lazySingleton
class LiveTrackingSessionHolder {
  LiveTrackingCubit? _cubit;
  String? _eventId;

  LiveTrackingCubit obtainForEvent({eventId, eventOwnerId}) {
    // Reutiliza el cubit si es el mismo evento
    // Si es diferente evento → cierra el anterior, crea uno nuevo
    // Llama cubit.start() automáticamente
  }

  stopSessionForEvent(String eventId) // llamado cuando organizador termina la rodada
}
```

**Por qué existe:** cuando el usuario navega fuera del LiveMapPage, el cubit NO se cierra. El GPS y la sesión WS continúan activos hasta que el organizador termine la rodada o el usuario cierre sesión.

### Throtling del backend push

El cubit actualiza el estado de la UI con cada posición GPS, pero solo hace push al backend si han pasado **≥ 4 segundos** desde el último envío:
```dart
if (now.difference(_lastBackendPush!) < const Duration(seconds: 4)) {
  // solo actualiza estado local, no envía al WS
  emit(state.copyWith(totalDistanceMeters: ..., currentUserLatitude: ...));
  return;
}
```

### Roles en tracking

- `RiderTrackingRole.lead` → el `ownerId` del evento
- `RiderTrackingRole.rider` → todos los demás
- El organizador (lead) puede ver `OrganizerControlBar` con el botón de "Terminar rodada".

---

## 7. Rutas de navegación

```dart
// Definidas en lib/shared/router/app_routes.dart
AppRoutes.events              → '/events'
AppRoutes.myEvents            → '/events/mine'
AppRoutes.myDrafts            → '/events/drafts'
AppRoutes.createEvent         → '/events/create'
AppRoutes.editEvent           → '/events/edit'           extra: EventModel
AppRoutes.eventDetail         → '/events/detail'         extra: EventModel
AppRoutes.eventDetailById     → '/events/detail-by-id'   extra: String (eventId)
AppRoutes.eventRegistration   → '/events/registration'   extra: EventRegistrationParams
AppRoutes.eventAttendees      → '/events/attendees'      extra: EventModel
AppRoutes.liveMap             → '/events/live-map'       extra: EventModel
AppRoutes.participants        → '/events/participants'
AppRoutes.myRegistrations     → '/events/my-registrations'
AppRoutes.registrationDetail  → '/events/registration-detail'  extra: RegistrationDetailExtra
AppRoutes.riderProfile        → '/events/attendees/rider-profile'
```

**Consideraciones de navegación:**
- `EventDetailPage` vs `EventDetailByIdPage`: la primera recibe el modelo completo (desde la lista), la segunda solo el `id` y lo carga desde el API (usado en deep links).
- Al editar un evento, `context.pushNamed(AppRoutes.editEvent, extra: event)` y el resultado es `EventModel?` — si es no-null, el detalle actualiza su `currentEvent` local.
- `EventDetailView` tiene `PopScope` custom: si viene desde `EventDetailByIdPage`, hace pop normal; si viene desde la lista, retorna el `EventModel` actualizado para que la lista lo refleje sin refetch.

---

## 8. API endpoints

### Eventos
| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/events` | Listar eventos (filtros: type, dateFrom, dateTo, city) |
| `GET` | `/events/my` | Mis eventos como organizador |
| `GET` | `/events/:id` | Detalle de evento |
| `POST` | `/events` | Crear evento (body: `EventDto.toJson()`) |
| `PATCH` | `/events/:id` | Actualizar evento |
| `DELETE` | `/events/:id` | Eliminar evento |
| `PATCH` | `/events/:id/publish` | Publicar borrador → scheduled |
| `POST` | `/events/generate-cover` | Generar portada con IA (`{title, eventType, city}`) |

### Tracking
| Método | Endpoint | Descripción |
|---|---|---|
| `POST` | `/events/:id/tracking/start` | Iniciar rodada (state → inProgress) |
| `POST` | `/events/:id/tracking/end` | Terminar rodada (state → finished) |
| `POST` | `/events/:id/tracking/session/start` | Registrar rider en sesión tracking |
| `POST` | `/events/:id/tracking/session/stop` | Retirar rider de sesión |
| `GET` | `/events/:id/tracking/snapshot` | Estado actual de todos los riders |
| `WS` | `/tracking/ws?eventId=…&token=…` | WebSocket de tracking en tiempo real |

### Inscripciones
| Método | Endpoint | Descripción |
|---|---|---|
| `POST` | `/events/:id/registrations` | Crear inscripción (+ `saveToProfile?`) |
| `GET` | `/events/:id/registrations` | Listar inscripciones del evento (owner) |
| `GET` | `/events/:id/registrations/me` | Mi inscripción en este evento |
| `PATCH` | `/registrations/:id` | Actualizar inscripción |
| `POST` | `/registrations/:id/cancel` | Cancelar |
| `POST` | `/registrations/:id/approve` | Aprobar (owner) |
| `POST` | `/registrations/:id/reject` | Rechazar (owner) |
| `POST` | `/registrations/:id/ready-for-edit` | Permitir que el rider edite |
| `GET` | `/registrations/me` | Mis inscripciones como rider |

---

## 9. Sub-features en detalle

### 9.1 Lista de eventos (`/events`)

**Archivo principal:** `presentation/list/events_page.dart`  
**Cubit:** `EventsCubit`

`EventsCubit` tiene **dos constructores factory**:
```dart
EventsCubit(GetEventsUseCase, ...)          // todos los eventos
EventsCubit.myEvents(GetMyEventsUseCase, .) // solo mis eventos como organizador
```
Ambos exponen la misma interfaz. La diferencia está en `_fetchFn` que se inyecta en el constructor.

**Filtrado híbrido:**
- Filtros de servidor: `type`, `dateFrom`, `dateTo`, `city` → enviados al API.
- Filtros locales (en `_applyFiltersAndEmit()`): `difficulties`, `freeOnly`, `multiBrandOnly`, `searchQuery`.

`_allEvents` es el cache en memoria. Cuando cambian filtros de servidor → `fetchEvents()`. Cuando cambian filtros locales o searchQuery → solo `_applyFiltersAndEmit()` sin refetch.

**`EventFilters`** (clase value):
```dart
types: Set<EventType>
difficulties: Set<EventDifficulty>
city: String?
startDate / endDate: DateTime?
freeOnly: bool
multiBrandOnly: bool
```

**Actualización optimista de la lista:**
- `addEvent(event)` → prepend al cache local, sin refetch.
- `updateEvent(event)` → reemplaza in-place por ID.
- `removeEvent(eventId)` → filtra del cache.
- `startEvent(event)` → hace update al API y si éxito, llama `updateEvent`.

---

### 9.2 Formulario de evento

**Archivos clave:**
- `event_form_page.dart` → provee `EventFormCubit` + `FormImageCubit`
- `event_form_view.dart` → bottom bar con botones guardar/publicar
- `event_form_content.dart` → scroll con todas las secciones
- `event_form_cubit.dart` → lógica de negocio del form

**Secciones del form (en orden de la UI):**
1. Cover (imagen local o generada con IA)
2. `EventFormBasicInfoSection` → nombre + descripción (Quill) + ciudad
3. `EventFormDateTimeSection` → fecha rango + toggle multi-día + hora de concentración
4. `EventFormLocationsSection` → tipo de ruta + punto encuentro + destino (o constructor custom)
5. `EventFormDifficultySection` → selector de chiles (1–5)
6. `EventFormEventTypeSection` → chips de tipo
7. `EventFormMultiBrandSection` → toggle + selector de marcas
8. `EventFormMaxParticipantsSection` → contador manual
9. `EventFormPriceSection` → input precio (vacío = gratis)

**Constantes de campos:** `EventFormFields` (clase abstracta con string constants).

**Flujo de guardado:**
```
Usuario toca "Guardar y publicar"
  → EventFormCubit.buildEventToSave()    // valida form, construye EventModel
  → EventFormCubit.saveEvent(event, localCoverImagePath?, remoteCoverImageUrl?)
     → isEditing ? _saveExistingEvent() : _createNewEvent()
        → Si hay imagen local: uploadEventImage() → PATCH/POST con imageUrl
        → Si hay URL remota (IA): PATCH/POST con esa URL
        → Si no hay imagen: PATCH/POST sin cambios de imagen

Usuario toca "Guardar como borrador"
  → EventFormCubit.buildDraftToSave()    // no valida, solo requiere nombre
  → EventFormCubit.saveDraft()
     → mismo flujo pero state = EventState.draft
```

**Construcción del `routeGeoJson`:**
```dart
_buildRouteGeoJson(routeType) → {
  'routeType': 'simple' | 'custom',
  'points': [{'lat': ..., 'lng': ..., 'label': ...}]
}
```
- `simple`: 2 puntos → meetingPoint + destination
- `custom`: N waypoints (hasta 9) con sus coordenadas

---

### 9.3 Constructor de ruta personalizada

**Archivo:** `presentation/form/screens/event_route_config_screen.dart`  
**Límite:** 9 waypoints máximo (`_maxWaypoints = 9`)

**Dos formas de agregar waypoints:**
1. **Búsqueda textual** (`WaypointSearchField` → `PlaceService` Mapbox Geocoding) → devuelve nombre + coordenadas.
2. **"Seleccionar en mapa" (pick mode):** overlay de pin centrado en el mapa → usuario mueve el mapa → confirma → geocodificación inversa del punto central.

**Renderizado en mapa (Mapbox):**
- Pin numerado de color (verde para el primero, naranja para el resto) via `buildNumberedPinImage`.
- Polyline naranja (`#F98C1F`, ancho 3) como `LineLayer` sobre `GeoJsonSource`.
- Al agregar/quitar waypoint → `_renderWaypointMode()` regenera pins y polilínea.
- Camera se ajusta automáticamente con `cameraForCoordinatesPadding` para mostrar todos los puntos.

**Persistencia del estado:** las coordenadas se guardan en el cubit como `waypointLocations: List<AddressLocation?>` (paralelas a `waypoints: List<String>`). Si el índice no tiene coordenadas, el pin no se renderiza pero el waypoint sí queda registrado.

---

### 9.4 Detalle de evento

**Archivos:**
- `event_detail_page.dart` → recibe `EventModel` completo por `extra`
- `event_detail_by_id_page.dart` → recibe `String id`, llama `loadEvent()` al init
- `event_detail_view.dart` → StatefulWidget con `currentEvent` mutable local
- `event_route_map_screen.dart` → pantalla full-screen con la ruta del evento en Mapbox

**Lógica de `EventDetailView`:**
- Mantiene `currentEvent` como estado local (actualizado por listeners de cubit).
- Detecta si el usuario es owner (`currentEvent.ownerId == currentUserId`).
- Si es owner: muestra `EventDetailOwnerLifecycleBar` (botones start/stop/publish/mapa).
- Si no es owner: muestra `EventDetailCTABar` (botones inscribirse/seguir en vivo/estado inscripción).

**Acciones del bottom bar:**

*Owner (`EventDetailOwnerLifecycleBar`):*
| Estado | Acciones disponibles |
|---|---|
| `draft` | Publicar |
| `scheduled` | Iniciar rodada, Ver mapa en vivo |
| `inProgress` | Terminar rodada, Ver mapa en vivo |
| `finished` / `cancelled` | (sin barra) |

*Rider (`EventDetailCTABar`):*
| Estado inscripción | Acción |
|---|---|
| ninguna | Inscribirse |
| `pending` | Ver estado (bottom sheet: ver detalle / cancelar) |
| `approved` | Seguir en vivo + ver estado |
| `cancelled` | Inscribirse de nuevo |
| `readyForEdit` | Editar inscripción |

**Manejo del `PopScope`:**
Si viene de la lista de eventos (`isFromEventDetailByIdPage = false`), el pop retorna el `currentEvent` actualizado para que la lista actualice su cache sin refetch.

---

### 9.5 Formulario de inscripción

**Archivos:**
- `event_registration_page.dart` → provee `RegistrationFormCubit`
- `registration_form_view.dart` → scroll + bottom bar
- `registration_form_content.dart` → campos del form

**Cubit `RegistrationFormCubit`:**

Pre-llenado en cascada (primer match gana, sin sobreescribir campos ya llenos):
1. Si hay `existingRegistration` → pre-llena desde los datos existentes.
2. Si es nueva inscripción → pre-llena desde `AuthService.currentUser`.
3. Asíncrono (100ms delay) → intenta pre-llenar desde `RiderProfileModel`.

**Modo edición vs. creación:**
- `isEditing = (existingRegistration != null)`
- En modo edición: `update()` al API (PATCH), no `create()`.
- `resetFormToEmpty()` solo funciona si no está en modo edición.

**`saveToProfile` checkbox:**
Si el usuario marca "Guardar para futuros eventos", el flag se incluye en el body del request. El backend persiste los datos como `RiderProfileModel`. Localmente también se llama `SaveRiderProfileUseCase` al guardar con éxito.

**Campos del form** (`RegistrationFormFields`):
```
fullName, identificationNumber, birthDate, phone, email, residenceCity,
eps, medicalInsurance, bloodType, emergencyContactName, emergencyContactPhone,
vehicleId
```

**Selector de vehículo:**
- `VehicleSelectorField` lee del `VehicleCubit` (global).
- Muestra `VehicleSelectorLoading` o `VehicleSelectorEmpty` según el estado.
- El vehicleId seleccionado se guarda como form field.

---

### 9.6 Gestión de asistentes (organizador)

**Archivos:**
- `attendees/attendees_page.dart` → provee `AttendeesCubit`
- `attendees/attendees_cubit.dart`
- `attendees/attendee_action_confirmation.dart` → dialog de confirmación
- `attendees/widgets/attendees_data_view.dart` → vista con filtros y lista

**`AttendeesCubit`:**
- `fetchAttendees(eventId)` → GET `/events/:id/registrations`
- `approveRegistration(id)` → **optimistic**: actualiza estado local primero, luego llama API en background (`unawaited`). No hace refetch.
- `rejectRegistration(id)` → igual que approve.
- `setReadyForEdit(id)` → espera resultado, luego hace `fetchAttendees()` de nuevo.

**Filtro de asistentes:**
`AttendeeFilterBottomSheet` permite filtrar por `RegistrationStatus`.  
Los registros se muestran en dos secciones:
- Pendientes → `AttendeePendingRequestCard` (con botones aprobar/rechazar)
- Procesados → `AttendeeProcessedItem`

---

### 9.7 Live Tracking (mapa en vivo)

**Archivos:**
- `live_map_page.dart` → provee `LiveTrackingCubit` via `LiveTrackingSessionHolder`
- `live_map_body.dart` → lógica de UI
- `live_map_widget.dart` → Mapbox MapWidget con markers
- `live_map_app_bar.dart`
- `organizer_control_bar.dart` → botón "Terminar rodada" (solo lead)
- `rider_telemetry_panel.dart` + `rider_telemetry_card.dart` → telemetría de riders
- `sos_button.dart` / `sos_confirm_dialog.dart` / `sos_banner.dart` → flujo SOS

**Flujo de inicio:**
```
LiveMapPage.initState()
  → LiveTrackingSessionHolder.obtainForEvent(eventId, eventOwnerId)
     → crea LiveTrackingCubit via LiveTrackingCubitFactory
     → llama cubit.start() automáticamente

cubit.start()
  → pide permisos de ubicación
  → obtiene posición inicial
  → llama StartTrackingUseCase → POST session/start
  → inicia GPS stream (_listenPosition)
  → suscribe a riders WS stream (_subscribeToRiders)
  → suscribe a SOS alerts (_subscribeToSosAlerts)
  → suscribe a evento terminado (_subscribeToEventEnded)
```

**Flujo de finalización por organizador:**
```
Usuario toca "Terminar rodada" → EndRideConfirmDialog
  → LiveTrackingCubit.endRide(eventId)
     → TrackingRepository.endRide() → POST /events/:id/tracking/end
     → WS broadcast: tracking.event.ended
  → Todos los riders: isFinished = true → auto-pop de LiveMapPage
  → EventDetailCubit.stopEvent() también es llamado (actualiza estado del evento a finished)
  → LiveTrackingSessionHolder.stopSessionForEvent() → cierra el cubit
```

**Flujo SOS:**
```
Rider toca SOS → SosConfirmDialog
  → LiveTrackingCubit.triggerSos()
     → TrackingRepository.publishSos() → WS tracking.sos
     → hasSentSos = true → muestra SosActiveOverlay
Otros riders reciben: sosAlertResult = Data(SosAlertModel)
  → SosBanner con nombre + teléfono del rider en emergencia
```

**Marcadores en el mapa:**
- `InitialsMarkerIcon` → avatar con iniciales del rider (pintado como imagen PNG para Mapbox annotations).
- Colores diferenciados: lead (verde), riders (naranja).
- Actualización: cada vez que `ridersResult` cambia, se regeneran todas las annotations.

---

### 9.8 Mis inscripciones

**Archivos:**
- `my_registrations_page.dart` → top-level page
- `my_registrations_cubit.dart` → `@injectable`, inyectado globalmente en `main.dart`

**`MyRegistrationsCubit`** emite `List<RegistrationWithEvent>`:
```dart
class RegistrationWithEvent {
  final EventRegistrationModel registration;
  final EventModel? event;  // puede ser null si falló la carga
}
```

Al cargar, hace `Future.wait` para obtener el `EventModel` de cada inscripción (por `eventId`). Esto puede hacer muchas llamadas en paralelo si hay muchas inscripciones.

**Filtros:**
- `statusFilter: Set<RegistrationStatus>` → filtrado en memoria.
- `searchQuery` → filtra por `fullName` y `eventName`.

**Al cancelar una inscripción:**
- `cancelRegistration()` → llama API, actualiza `_registrations` localmente, re-emite.
- `onChangeRegistration()` → actualizado desde `EventDetailView` cuando el rider cancela desde ahí.

---

### 9.9 Mis borradores

**Archivo:** `drafts/my_drafts_page.dart`  
Usa `EventsCubit.myEvents` con filtro `EventState.draft` aplicado localmente.  
Desde aquí se puede continuar editando un borrador → navega a `AppRoutes.editEvent`.

---

## 10. Patrones y trampas conocidas

### DTO hereda de Model (patrón especial en eventos)
`EventDto extends EventModel` es inusual. El resto del codebase usa DTOs separados.  
**Impacto:** nunca crees un `EventDto` manualmente fuera del repositorio; usa siempre `EventModel` y la extension `toJson()`.

### `routeGeoJson` y `waypoints` — dos representaciones
Existe duplicación entre `waypoints: List<String>` (nombres) y `routeGeoJson.points` (coordenadas).  
- `waypoints` se usa para mostrar la lista de paradas textuales.
- `routeGeoJson.points` contiene coordenadas y se usa para renderizar el mapa.
- Al detectar si es ruta custom: `waypoints.isNotEmpty || routeGeoJson['routeType'] == 'custom'`.

### `_applyFiltersAndEmit()` emite `ResultState.initial()` antes del dato
```dart
void _applyFiltersAndEmit() {
  emit(const ResultState.initial());  // ← fuerza rebuild en la UI
  // ...
  emit(ResultState.data(data: filtered));
}
```
Esto es intencional para forzar que `BlocBuilder` detecte el cambio cuando el nuevo dato es idéntico al anterior.

### `AttendeesCubit` — approve/reject es fire-and-forget
```dart
unawaited(_approveUseCase(registrationId));
```
Si la llamada API falla, la UI ya mostró el estado aprobado. No hay rollback. Tener esto en cuenta si se implementa manejo de errores en el futuro.

### `LiveTrackingCubit` no se registra en DI directamente
Se crea via `LiveTrackingCubitFactory` que inyecta todas las dependencias. `LiveTrackingSessionHolder` es el único punto de acceso.

### Pre-llenado del form de inscripción — timing con delays
`RegistrationFormCubit.initialize()` usa `Future.delayed` para pre-llenar campos:
- 50ms → auth user
- 100ms → existing registration
- 120ms → rider profile

Esto es necesario porque `formKey.currentState` puede ser null si el widget no ha montado aún. Si se refactoriza la inicialización, verificar que el form esté listo antes de llamar `patchValue`.

### `MyRegistrationsCubit.fetchMyRegistrations()` — N+1 de eventos
Hace una llamada por evento distinto. Con muchas inscripciones esto puede ser lento.  
Futuro: el backend podría retornar el snapshot del evento inline en la inscripción.

### `EventDetailView.currentEvent` — estado local mutable
`currentEvent` es un campo de `State<EventDetailView>` que se actualiza via `setState()`.  
Listeners de `EventDetailCubit.lastUpdatedEventResult` sincronizan este campo cuando el organizador cambia el estado del evento.

---

## 11. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Modelo del evento | `lib/features/events/domain/model/event_model.dart` |
| CRUD del evento (API) | `lib/features/events/data/service/event_service.dart` |
| CRUD del evento (repo) | `lib/features/events/data/repository/event_repository_impl.dart` |
| Listado + filtros cubit | `lib/features/events/presentation/list/events_cubit.dart` |
| Formulario cubit | `lib/features/events/presentation/form/cubit/event_form_cubit.dart` |
| Formulario UI (secciones) | `lib/features/events/presentation/form/widgets/event_form_content.dart` |
| Constructor de ruta | `lib/features/events/presentation/form/screens/event_route_config_screen.dart` |
| Detalle cubit | `lib/features/events/presentation/detail/cubit/event_detail_cubit.dart` |
| Detalle UI principal | `lib/features/events/presentation/detail/event_detail_view.dart` |
| WebSocket de tracking | `lib/features/events/data/service/tracking_ws_client.dart` |
| Live tracking cubit | `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart` |
| Keep-alive tracking | `lib/features/events/presentation/tracking/live_tracking_session_holder.dart` |
| Modelo inscripción | `lib/features/event_registration/domain/model/event_registration_model.dart` |
| Form inscripción cubit | `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` |
| Asistentes cubit | `lib/features/events/presentation/attendees/attendees_cubit.dart` |
| Mis inscripciones cubit | `lib/features/event_registration/presentation/my_registrations_cubit.dart` |
| Rutas de navegación | `lib/shared/router/app_routes.dart` |
| Endpoints API | `lib/core/http/api_routes.dart` |
| Constantes del form | `lib/features/events/constants/event_form_fields.dart` |
