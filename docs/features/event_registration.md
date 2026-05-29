# Documentación del Feature: Event Registration

> Última actualización: 2026-05-28  
> Alcance: `lib/features/event_registration/`

> Documentación complementaria: el feature de eventos (organización, tracking, etc.) está en [events.md](./events.md). Las inscripciones consumen `EventModel`, `RiderProfileModel`, `SaveRiderProfileUseCase`, `GetRiderProfileUseCase`, `GetEventByIdUseCase` del feature `events/`.

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Arquitectura por capas](#3-arquitectura-por-capas)
   - 3.1 [Domain](#31-domain)
   - 3.2 [Data](#32-data)
   - 3.3 [Presentation](#33-presentation)
4. [Cubits y estados](#4-cubits-y-estados)
5. [Pre-llenado en cascada](#5-pre-llenado-en-cascada)
6. [saveToProfile y rider profile](#6-savetoprofile-y-rider-profile)
7. [Selector de vehículo](#7-selector-de-vehículo)
8. [Sub-features](#8-sub-features)
9. [Rutas de navegación](#9-rutas-de-navegación)
10. [API endpoints](#10-api-endpoints)
11. [Conexiones con otros features](#11-conexiones-con-otros-features)
12. [Patrones y trampas conocidas](#12-patrones-y-trampas-conocidas)
13. [Archivos clave de referencia rápida](#13-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

El feature **Event Registration** gestiona la inscripción de un rider a un evento:

1. **Formulario de inscripción** con datos personales, médicos, de emergencia y vehículo asociado.
2. **Aprobación/rechazo** por parte del organizador (`AttendeesCubit` en feature `events/`).
3. **Cancelación** por parte del rider.
4. **Vista "Mis inscripciones"** con filtros por estado + búsqueda.
5. **Detalle de la inscripción** mostrando todos los datos + botón de contacto al rider (para el organizador).
6. **Persistencia opcional** de los datos como `RiderProfileModel` para pre-llenar futuras inscripciones.

`MyRegistrationsCubit` es `@injectable` y se inyecta globalmente en `main.dart` (root `MultiBlocProvider`) para que el badge/UI de "mis inscripciones" funcione desde cualquier pantalla.

---

## 2. Modelo de dominio

### `EventRegistrationModel`
> `lib/features/event_registration/domain/model/event_registration_model.dart`

```
EventRegistrationModel
  id: String?
  eventId: String                          (requerido)
  eventName: String                        (requerido)  — snapshot del nombre
  userId: String                           (requerido)
  status: RegistrationStatus               (default pending)

  fullName, identificationNumber           (requerido)
  birthDate: DateTime                      (requerido)
  phone, email, residenceCity              (requerido)

  eps: String                              (requerido)
  medicalInsurance: String?
  bloodType: BloodType                     (requerido)

  emergencyContactName / emergencyContactPhone   (requerido)

  vehicleId: String?
  vehicleSummary: VehicleSummaryModel?     — snapshot placa+marca

  createdAt: DateTime?
  updatedAt: DateTime?
```

**Igualdad:** solo por `id`. Mismas precauciones que `EventModel` — dos registros con `id == null` se consideran iguales.

**Getter:** `registrationTitle → 'Inscripción al evento $eventName'`.

### Enums

**`RegistrationStatus`** (con `@JsonValue`):

| Enum | JsonValue | Label |
|---|---|---|
| `pending` | `'PENDING'` | Pendiente |
| `approved` | `'APPROVED'` | Aprobado |
| `rejected` | `'REJECTED'` | Rechazado |
| `cancelled` | `'CANCELLED'` | Cancelado |
| `readyForEdit` | `'READY_FOR_EDIT'` | Listo para editar |

**`BloodType`** — 8 valores (también usado por `UserModel` y `RiderProfileModel`). Ver tabla en [users.md §2](./users.md#2-modelo-de-dominio).

### `VehicleSummaryModel`
> `lib/features/event_registration/domain/model/vehicle_summary_model.dart`

```
id: String (requerido)
brand: String?, model: String?, licensePlate: String?, vin: String?

displayName getter → "$brand $model" (combinado, trim, sin vacíos)
```

Es un snapshot de los datos del vehículo en el momento de la inscripción. Si el rider luego cambia su vehículo, esta `summary` permanece (el organizador verá los datos originales).

### `RegistrationWithEvent` (agregado)
> `domain/model/registration_with_event.dart`

```dart
class RegistrationWithEvent {
  final EventRegistrationModel registration;
  final EventModel? event;   // null si falló la carga del evento
}
```

Usado por `MyRegistrationsCubit` para mostrar nombre/imagen del evento junto a cada inscripción.

---

## 3. Arquitectura por capas

### 3.1 Domain
```
lib/features/event_registration/domain/
├── model/
│   ├── event_registration_model.dart     (modelo + RegistrationStatus + BloodType)
│   ├── vehicle_summary_model.dart
│   └── registration_with_event.dart
├── repository/
│   └── event_registration_repository.dart
└── use_cases/
    ├── add_event_registration_use_case.dart
    ├── update_event_registration_use_case.dart
    ├── cancel_event_registration_use_case.dart
    ├── get_event_registrations_use_case.dart       (admin)
    ├── get_my_registrations_use_case.dart
    ├── get_my_registration_for_event_use_case.dart
    ├── approve_registration_use_case.dart          (admin)
    ├── reject_registration_use_case.dart           (admin)
    └── set_registration_ready_for_edit_use_case.dart (admin)
```

**`EventRegistrationRepository`** (interface):
```dart
addRegistration(EventRegistrationModel, {saveToProfile = false}) → Either<…, EventRegistrationModel>
updateRegistration(EventRegistrationModel, {saveToProfile = false}) → Either<…, EventRegistrationModel>
cancelRegistration(String registrationId)                     → Either<…, Nothing>
getRegistrationsByEvent(String eventId)                       → Either<…, List<EventRegistrationModel>>
getMyRegistrations()                                          → Either<…, List<EventRegistrationModel>>
getMyRegistrationForEvent(String eventId)                     → Either<…, EventRegistrationModel?>
approveRegistration(String registrationId)                    → Either<…, EventRegistrationModel>
rejectRegistration(String registrationId)                     → Either<…, EventRegistrationModel>
setRegistrationReadyForEdit(String registrationId)            → Either<…, EventRegistrationModel>
```

> El flag `saveToProfile` viaja al body del POST/PATCH para que el backend persista los datos como `RiderProfileModel`. Es independiente de la inscripción misma; la inscripción se guarda igual, pero opcionalmente actualiza el rider profile.

**Use cases** (todos `@injectable`): un use case por método, con `call()` directo al repository.

---

### 3.2 Data
```
lib/features/event_registration/data/
├── dto/
│   ├── event_registration_dto.dart         (@JsonSerializable + apiJsonDateTimeConverters)
│   ├── event_registration_dto.g.dart
│   └── vehicle_summary_dto.dart
├── repository/
│   └── event_registration_repository_impl.dart   (@Injectable(as: EventRegistrationRepository))
└── service/
    └── registration_service.dart           (@singleton, Dio manual, sin Retrofit)
```

**`EventRegistrationDto`** — campos idénticos al modelo + métodos `fromJson`, `toModel`, y extensión `EventRegistrationModel.toDto() → EventRegistrationDto`. Maneja `birthDate` con `apiEncodeRequiredDateTime()`.

**`VehicleSummaryDto`** — `@JsonSerializable` con campos `id`, `brand`, `model`, `licensePlate`, `vin`. Métodos `fromJson`, `toJson`, `toModel`.

**`RegistrationService`** (Dio manual, **no** Retrofit):

| Método | HTTP | Endpoint | Body |
|---|---|---|---|
| `create({eventId, body, saveToProfile})` | `POST` | `/events/{eventId}/registrations` | `{...body, saveToProfile: bool}` |
| `update({registrationId, body, saveToProfile})` | `PATCH` | `/registrations/{registrationId}` | `{...body, saveToProfile: bool}` |
| `cancel(registrationId)` | `POST` | `/registrations/{registrationId}/cancel` | — |
| `approve(registrationId)` | `POST` | `/registrations/{registrationId}/approve` | — |
| `reject(registrationId)` | `POST` | `/registrations/{registrationId}/reject` | — |
| `setReadyForEdit(registrationId)` | `POST` | `/registrations/{registrationId}/ready-for-edit` | — |
| `findByEvent(eventId)` | `GET` | `/events/{eventId}/registrations` | — |
| `findMyRegistrationForEvent(eventId)` | `GET` | `/events/{eventId}/registrations/me` | — |
| `findMyRegistrations()` | `GET` | `/registrations/me` | — |

Helper `_parseList(response.data)` filtra `whereType<Map>()` y construye `EventRegistrationDto.fromJson`.

**`EventRegistrationRepositoryImpl`**:
- Usa `executeService()` para wrappear errores.
- `addRegistration` invoca `service.create()` con `_buildBody(registration)` que sale de `registration.toDto().toJson()`.
- `updateRegistration` valida que `registration.id != null` antes de invocar `service.update()`.
- Resto de métodos son thin wrappers que convierten DTO ↔ modelo.

---

### 3.3 Presentation
```
lib/features/event_registration/presentation/
├── cubit/
│   └── registration_form_cubit.dart                (@injectable)
├── my_registrations_cubit.dart                     (@injectable, global)
├── event_registration_page.dart
├── registration_form_view.dart                     (FormBuilder único que envuelve el wizard)
├── registration_form_content.dart                  (orquestador del wizard multipaso)
├── wizard/
│   ├── registration_wizard_controller.dart          (ChangeNotifier: paso actual + next/previous)
│   ├── registration_step_indicator.dart             (dots 1-2-3-4, Pencil dotsRow)
│   ├── registration_step_header.dart                (icono + título + subtítulo por paso)
│   ├── registration_blood_type_selector.dart        (grid de chips RH 4x2, Pencil bts)
│   ├── registration_wizard_navigation_bar.dart      (Atrás / Siguiente / Confirmar)
│   └── steps/
│       ├── registration_personal_step.dart          (paso 1)
│       ├── registration_medical_step.dart           (paso 2)
│       ├── registration_emergency_step.dart         (paso 3)
│       └── registration_vehicle_step.dart           (paso 4 + SaveToProfileCheckbox)
├── my_registrations_page.dart
├── my_registrations_view.dart
├── my_registrations_data_view.dart
├── registration_detail_page.dart
├── registration_detail_extra.dart
└── widgets/
    ├── inscription_card.dart
    ├── inscription_secondary_action_button.dart
    ├── vehicle_selector_field.dart
    ├── vehicle_selector_card.dart
    ├── vehicle_selector_placeholder_card.dart
    ├── vehicle_selector_empty.dart
    ├── vehicle_selector_loading.dart
    ├── save_to_profile_checkbox.dart
    ├── registration_form_scaffold.dart
    ├── registration_detail_rider_summary.dart      (banda owner — Pencil y1Ci1)
    ├── registration_detail_status_banner.dart       (banner piloto — Pencil f0lXw)
    ├── registration_detail_data_card.dart           (tarjeta no colapsable con icono)
    ├── registration_detail_data_row.dart            (fila etiqueta/valor)
    ├── registration_status_pill.dart                (píldora de estado compartida)
    ├── registration_detail_bottom_bar.dart
    └── my_registrations_filter_bottom_sheet.dart
```

---

## 4. Cubits y estados

| Cubit | Archivo | DI | Estado | Notas |
|---|---|---|---|---|
| `RegistrationFormCubit` | `cubit/registration_form_cubit.dart` | `@injectable` | `ResultState<EventRegistrationModel>` | Pre-llenado en cascada (50/100/120 ms) |
| `MyRegistrationsCubit` | `my_registrations_cubit.dart` | `@injectable` + **global** | `ResultState<List<RegistrationWithEvent>>` | N+1 con `GetEventByIdUseCase` |

### `RegistrationFormCubit`

**Estado interno:**
```
formKey: GlobalKey<FormBuilderState>
_eventId, _eventName: String?
_editingRegistration: EventRegistrationModel?      // null = create
_riderProfile: RiderProfileModel?
_saveToProfile: bool = false
_preloadedFromProfile: bool = false
```

**Getters públicos:**
- `isEditing` → `_editingRegistration != null`.
- `saveToProfile`, `isPreloadedFromProfile`.

**Métodos:**
- `initialize({eventId, eventName, existingRegistration?})` — ver §5 para la cascada.
- `toggleSaveToProfile([bool?])` — toggle del checkbox.
- `resetFormToEmpty()` — solo en create mode; resetea form.
- `preloadFromRiderProfile()` — copia datos del profile al form.
- `saveRegistration()` — valida, llama add o update, persiste profile vía `SaveRiderProfileUseCase`.

**Flujo de `saveRegistration()`:**
1. `_buildRegistration()` valida `formKey.currentState.saveAndValidate()` y construye modelo.
2. Emite `loading`.
3. Si editing → `_updateRegistrationUseCase(registration, saveToProfile)`.
4. Si no → `_addRegistrationUseCase(registration, saveToProfile)`.
5. Si éxito → `_saveRiderProfileUseCase(_buildRiderProfile(registration))` + emite `data(saved)`.
6. Si error → emite `error(error)`.

> Nota: `_saveRiderProfileUseCase` se llama **siempre**, no solo cuando el flag `saveToProfile` está activo. El flag actual solo afecta el body del endpoint. Esto significa que el rider profile local siempre se actualiza con los datos del último submit.

### `MyRegistrationsCubit`

**Estado interno:**
```
_registrations: List<EventRegistrationModel>
_eventByEventId: Map<String, EventModel>          // cache de eventos
_statusFilter: Set<RegistrationStatus>            // filtro client-side
_searchQuery: String                              // filtro client-side
```

**Getters públicos:**
- `statusFilter`, `hasFilters`.

**Métodos:**
- `fetchMyRegistrations()` — patrón N+1 (ver §15).
- `updateStatusFilter(Set<RegistrationStatus>)`, `clearFilters()`, `updateSearchQuery(String)`.
- `cancelRegistration(String registrationId)` — async; al éxito hace `onChangeRegistration`.
- `onChangeRegistration(EventRegistrationModel)` — replace por id (o agrega si no existe).

---

## 5. Pre-llenado en cascada

`RegistrationFormCubit.initialize()` ejecuta múltiples pre-llenados con `Future.delayed`:

```
T = 0       initialize() llamado
            ├─ Si existingRegistration != null:
            │   └─ schedule: _preloadFromExistingRegistration en T+100ms
            ├─ Si existingRegistration == null:
            │   └─ schedule: _prefillFromAuthenticatedUser en T+50ms
            └─ _loadRiderProfile()  (async sin delay)

T = 50ms    _prefillFromAuthenticatedUser()   (solo si !isEditing)
            └─ formKey.currentState.patchValue({auth user fields})

T = 100ms   _preloadFromExistingRegistration() (solo si isEditing)
            └─ formKey.currentState.patchValue({existing reg fields})

T = ~ N ms  _loadRiderProfile completa
            └─ Si !isEditing: schedule preloadFromRiderProfile en T+120ms
                              (puede ocurrir antes o después del prefill de auth)
```

**Orden efectivo de prioridad (último escribe gana):**
- Modo edit: solo `existingRegistration` (100ms).
- Modo create: `auth user` (50ms) → `rider profile` (120ms+) — el profile sobreescribe.

**Por qué los delays:** el `formKey.currentState` puede no estar listo (widget no montado) inmediatamente. Los delays garantizan que el FormBuilder esté disponible para `patchValue`. **Si refactorizas la inicialización, asegúrate de que el form esté montado antes de patchear.**

### Auth user fields (50ms)

Lee de `AuthService.currentUser`:
- `fullName`, `identificationNumber`, `birthDate`, `phone`, `email`, `residenceCity`
- `eps`, `medicalInsurance`, `bloodType`
- `emergencyContactName`, `emergencyContactPhone`

Cada campo solo se patchea si `isNotBlank` (extensión interna que valida `!= null && trim().isNotEmpty`).

### Existing registration (100ms)

Patchea **todos** los campos del registro existente, incluyendo `vehicleId` (si existe).

### Rider profile (~120ms post-load)

Solo se ejecuta si **no** está editando. Patchea los mismos campos que auth user. Sobreescribe valores del auth si el profile tiene datos.

Setea `_preloadedFromProfile = true` para ocultar el `SaveToProfileCheckbox` (si ya viene del profile, no tiene sentido ofrecer guardar al profile).

---

## 6. saveToProfile y rider profile

### Flag `saveToProfile`

Visible como `SaveToProfileCheckbox` solo si `!cubit.isPreloadedFromProfile`. El usuario marca "Guardar para futuros eventos" → `_saveToProfile = true`.

**Persistencia:**
- En `saveRegistration()`, el flag se pasa al use case → el repository lo agrega al body del request.
- El backend persiste los datos del rider en su tabla `rider_profiles`.

### `RiderProfileModel`

Definido en `lib/features/events/domain/model/rider_profile_model.dart`. Se obtiene con `GetRiderProfileUseCase` (en feature `events/`) y se guarda con `SaveRiderProfileUseCase`. **Backend storage:** colección Firestore `rider_profiles/{userId}`.

> **`saveRegistration()` también llama `_saveRiderProfileUseCase` siempre**, no solo cuando `_saveToProfile == true`. La diferencia: el flag al endpoint le indica al backend que persista, y la llamada local llena el cache. Si quieres independizar ambos, hay que refactorizar.

---

## 7. Selector de vehículo

### `VehicleSelectorField`
> `presentation/widgets/vehicle_selector_field.dart`

`FormBuilderField<String>` con nombre `RegistrationFormFields.vehicleId`. Validador `required`. Al elegir un vehículo emite `vehicle.id` con `field.didChange()`. El `errorText` se pinta debajo del contenedor con `colorScheme.error`.

Renderiza una tarjeta (radius 16, `AppColors.darkTertiary`, borde `darkBorderPrimary`) con dos sub-estados:
- **Vehículo seleccionado** → `VehicleSelectorCard` (`vehicle_selector_card.dart`): cuadro de ícono `primarySubtle` 60x60 con `Icons.two_wheeler`, `${brand} ${model}`, chip de placa (`darkBgSecondary`, radius 8) + separador `·` + año, y botón "Cambiar" (`registration_changeVehicle`) en `primarySubtle`. Placa/año ausentes se omiten sin dejar el `·` colgando; si no hay marca/modelo cae a `vehicle.name`.
- **Hay vehículos pero ninguno seleccionado** → `VehicleSelectorPlaceholderCard` (`vehicle_selector_placeholder_card.dart`): mismo contenedor en modo invitación con texto `registration_selectVehiclePlaceholder` ("Selecciona tu vehículo") y un chevron; tocar el contenedor abre el bottom sheet.

Ambos sub-estados abren `VehicleSelectionBottomSheet.show(context)` para elegir/cambiar el vehículo.

`VehicleSelectorEmpty` (`vehicle_selector_empty.dart`) — estado sin vehículos en el garage: tarjeta centrada con ícono de moto en cuadro `primarySubtle`, título (`registration_vehicleEmptyStateTitle`), subtítulo gris (`registration_vehicleEmptyStateSubtitle`) y un `AppButton` filled/pill (`registration_createVehicleCta`) que dispara `onCreate`.

### Estados manejados desde `RegistrationFormContent`

```dart
BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
  builder: (context, state) {
    return state.when(
      initial: () => VehicleSelectorLoading(),
      loading: () => VehicleSelectorLoading(),
      data: (vehicles) {
        final available = vehicles.where((v) => !v.isArchived).toList();
        return available.isEmpty
            ? VehicleSelectorEmpty(onCreate: ...)
            : VehicleSelectorField(availableVehicles: available);
      },
      empty: () => VehicleSelectorEmpty(onCreate: ...),
      error: (_) => VehicleSelectorEmpty(onCreate: ...),
    );
  },
)
```

**Auto-fetch si está en `initial`:**
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  context.read<VehicleCubit>().state.maybeWhen(
    initial: () => context.read<VehicleCubit>().fetchMyVehicles(),
    orElse: () {},
  );
});
```

Esto previene loading infinito cuando el usuario llega directo al form sin pasar antes por el garage.

### Validación de marca permitida (`allowedBrands`)

`RegistrationFormContent` lee `event.allowedBrands` y valida que la marca del vehículo seleccionado esté incluida. Si no, snackbar rojo de 6s al intentar enviar y se bloquea el submit. Si `allowedBrands.isEmpty` (multi-marca), no se valida.

---

## 8. Sub-features

### Formulario de inscripción (`/events/registration`)
`EventRegistrationPage` recibe `EventRegistrationParams` (definido en feature `events/`: `event: EventModel` + `registration: EventRegistrationModel?`).

`RegistrationFormCubit` se crea localmente con `getIt` y se inicializa con `eventId` + `eventName` + `existingRegistration?`.

El formulario es un **wizard multipaso** (4 pasos, diseño Pencil `pQCmS` "Registration Form V2"). `RegistrationFormContent` mantiene un único `FormBuilder` (en `registration_form_view.dart`) y un `IndexedStack` que conserva todos los pasos montados, de modo que los valores y `saveAndValidate()` cubren todo el form. El paso activo lo gobierna `RegistrationWizardController` (`ChangeNotifier`).

Pasos (cada uno es su propio widget en `wizard/steps/`):
1. **Información Personal** — fullName, identificationNumber, birthDate, phone, email, residenceCity.
2. **Información Médica** — eps, medicalInsurance (opcional), bloodType (**grid de chips RH 4x2**, no dropdown — `RegistrationBloodTypeSelector`).
3. **Contacto de Emergencia** — emergencyContactName + emergencyContactPhone.
4. **Vehículo de Inscripción** — selector con estados + `SaveToProfileCheckbox` (solo si `!isPreloadedFromProfile`).

**Navegación** (`RegistrationWizardNavigationBar`, barra inferior fija): "Atrás" (oculto en el paso 1), "Siguiente" valida solo los campos del paso actual vía `RegistrationFormCubit.validateStepFields(...)` antes de avanzar; en el último paso el botón es "Confirmar Inscripción" (o "Actualizar inscripción" en edición) y dispara `saveRegistration()` (flujo de submit existente, incluida la validación de `allowedBrands`). El mapeo paso→campos vive en `RegistrationWizardSteps.fieldsByStep`.

**Indicador de pasos** (`RegistrationStepIndicator`): dots numerados 1-2-3-4 unidos por conectores; los pasos alcanzados se resaltan en `AppColors.primary`.

**Focus chain** (`_registrationFocusChainFields`): orden de tab `fullName → identificationNumber → phone → email → residenceCity → eps → medicalInsurance → bloodType → emergencyContactName → emergencyContactPhone`. `birthDate` y `vehicleId` no entran en la chain (se manejan con pickers).

### Mis inscripciones (`/events/my-registrations`)

`MyRegistrationsPage` → `MyRegistrationsView` → `MyRegistrationsDataView`.

**Header:** `SearchTextField` + botón filtros (con indicador si `hasFilters`).

**Lista:** `InscriptionCard` por cada `RegistrationWithEvent`. Cada card muestra:
- Imagen + nombre del evento + status badge.
- Fecha y ubicación (si están disponibles).
- Botón "Ver detalle".
- Botón secundario dinámico según status (ver §17.x más abajo).

**Secondary action por status:**

| Status | Label | Acción |
|---|---|---|
| `approved` | "Mi Inscripción" | Navega a detail con `onCancelRegistration` callback |
| `pending` | "Ver Detalle" | Navega a detail (solo lectura) |
| `readyForEdit` | "Editar" | Navega al form en modo edit |
| `rejected` | "Razón" | Navega a detail |
| `cancelled` | "Re-Registrarse" | Navega al form en modo create |

**Botón "Detalles" (`onDetails`):** ahora pasa por `_openDetail`, que construye `RegistrationDetailExtra` con `onCancelRegistration` (pending/approved/readyForEdit) y `onEditRegistration` (solo `readyForEdit`, abre el form vía `_openEditForm` y propaga el resultado con `onChangeRegistration`). Así el detalle del piloto muestra los CTA correctos del rediseño.

### Detalle de inscripción (`/events/registration-detail`)

`RegistrationDetailPage(params: RegistrationDetailExtra)` con:
- `registration: EventRegistrationModel`.
- `eventOwnerId: String?` (para determinar visibilidad de acciones).
- Callbacks opcionales: `onCancelRegistration`, `onApprove`, `onReject`, `onRequestEdit` (organizador habilita READY_FOR_EDIT), `onEditRegistration` (piloto abre el form en modo edición).

**Estructura (rediseño alineado a Pencil `f0lXw` rider / `y1Ci1` owner):**
1. **Vista organizador** (`!isRegistrantViewer`): banda `RegistrationDetailRiderSummary` (avatar + nombre + fecha + `RegistrationStatusPill`).
   **Vista piloto** (`isRegistrantViewer`): `RegistrationDetailStatusBanner` (banner de estado pendiente/rechazada/para-editar; oculto si aprobada).
2. Cuatro tarjetas `RegistrationDetailDataCard` **no colapsables** (encabezado con icono coloreado + `RegistrationDetailDataRow` etiqueta/valor):
   - Datos Personales (icono naranja).
   - Información Médica (icono rojo).
   - Contacto de Emergencia (icono rojo).
   - Datos de Participación (icono naranja).
3. `RegistrationDetailBottomBar` con CTA dinámico según rol y status:
   - **Organizador**: `Aprobar` (verde sólido `AppColors.statusGreen` + texto/ícono oscuros, full-width) + fila `Rechazar` (fondo `darkTertiary`, borde y texto `error`) / `Solicitar edición` (neutral: `darkCard` + borde). Los tres botones usan los widgets dedicados `RegistrationApproveButton` / `RegistrationRejectButton` / `RegistrationRequestEditButton` (no `AppButton`) para lograr los colores pixel-perfect del diseño TUJA0.
   - **Piloto**: `Editar inscripción` (naranja, solo si `readyForEdit`) + `Cancelar inscripción` (outlined rojo).
   - **Regla READY_FOR_EDIT (organizador):** si `registration.status == readyForEdit`, la barra del organizador NO muestra Aprobar/Rechazar/Solicitar edición (queda oculta). Solo vuelve a habilitarse cuando el piloto edita su inscripción y esta regresa a `pending`. Las acciones del piloto no se ven afectadas. Esta misma regla oculta `ApproveRejectBar` en `AttendeePendingRequestCard`.

> El antiguo `RegistrationDetailHeader`, las secciones expandibles (`RegistrationDetailSectionCard` + `ExpandableContainer`), `RegistrationDetailInfoRow`, `RegistrationDetailEmergencyCard`, `RegistrationVehicleDetailContent` y el `ContactPopupMenuButton` del detalle fueron eliminados en el rediseño.

---

## 9. Rutas de navegación

| Ruta | Constante | Builder | Extra |
|---|---|---|---|
| `/events/registration` | `AppRoutes.eventRegistration` | `EventRegistrationPage(params: extra as EventRegistrationParams)` | `EventRegistrationParams` (de feature `events/`) |
| `/events/my-registrations` | `AppRoutes.myRegistrations` | `MyRegistrationsPage()` | — |
| `/events/registration-detail` | `AppRoutes.registrationDetail` | `RegistrationDetailPage(params: extra as RegistrationDetailExtra)` | `RegistrationDetailExtra` |

> El guard `AppRouter.redirect` detecta cuando el owner del evento intenta entrar a `eventRegistration` y redirige a `eventDetailById` (no debería inscribirse a su propio evento).

---

## 10. API endpoints

| Operación | Método | Endpoint |
|---|---|---|
| Crear inscripción | `POST` | `/events/{eventId}/registrations` |
| Actualizar | `PATCH` | `/registrations/{registrationId}` |
| Cancelar | `POST` | `/registrations/{registrationId}/cancel` |
| Listar de evento (admin) | `GET` | `/events/{eventId}/registrations` |
| Mi inscripción a evento | `GET` | `/events/{eventId}/registrations/me` |
| Aprobar (admin) | `POST` | `/registrations/{registrationId}/approve` |
| Rechazar (admin) | `POST` | `/registrations/{registrationId}/reject` |
| Listo para editar (admin) | `POST` | `/registrations/{registrationId}/ready-for-edit` |
| Mis inscripciones | `GET` | `/registrations/me` |

Constantes en `lib/core/http/api_routes.dart` (`ApiRoutes.eventRegistrations(id)`, `registration(id)`, `cancelRegistration(id)`, `approveRegistration(id)`, `rejectRegistration(id)`, `setRegistrationReadyForEdit(id)`, `myRegistrations`).

Bodies de POST/PATCH incluyen el JSON serializado del modelo + `saveToProfile: bool`.

---

## 11. Conexiones con otros features

| Feature | Conexión |
|---|---|
| `events` | Importa `EventModel`, `EventRegistrationParams`, `RiderProfileModel`, `GetRiderProfileUseCase`, `SaveRiderProfileUseCase`, `GetEventByIdUseCase` |
| `vehicles` | `VehicleSelectorField` lee `VehicleCubit.state`; usa `VehicleSelectionBottomSheet`. Al inscribirse guarda `vehicleId` |
| `authentication` | `AuthService.currentUser` para pre-llenar form y resolver `userId` al guardar |
| `users` | Reutiliza el enum `BloodType` (declarado en este feature pero usado por `UserModel`) |

> **Nota cross-feature:** `BloodType` enum vive aquí pero es importado por `UserModel`, `RiderProfileModel` y todo el flow de auth/profile. Si se mueve, actualizar imports.

---

## 12. Patrones y trampas conocidas

### Pre-llenado en cascada con delays mágicos
50ms / 100ms / 120ms son números empíricos para garantizar que `formKey.currentState` esté listo. Si cambias la estructura del widget tree o el cubit, **verifica que estos timings sigan funcionando**.

### `saveRegistration` siempre persiste el rider profile localmente
Independiente del flag `saveToProfile`, se llama `_saveRiderProfileUseCase`. El flag solo controla qué hace el backend. Si quieres respetar la elección del usuario también localmente, ajustar `saveRegistration()`.

### `MyRegistrationsCubit` hace N+1 lookup de eventos
`fetchMyRegistrations()` llama `getMyRegistrations` (1 query) y luego dispara N `getEventById` en paralelo. Si un usuario tiene muchas inscripciones a eventos distintos, el load inicial puede ser lento. **Idea futura:** el backend podría devolver el evento embebido en la inscripción.

### Filtros y search son **client-side**
`MyRegistrationsCubit._emitFiltered()` aplica `_statusFilter` y `_searchQuery` localmente. Si la lista crece a miles, conviene mover algunos al backend.

### `RegistrationService` usa **Dio manual**, no Retrofit
Diferente al resto del codebase. Razón histórica: necesitaba meter `saveToProfile` en el body sin que Retrofit lo convirtiera en query. Si se migra a Retrofit, considerar `@Body() Map<String, dynamic>` + spread del flag.

### `VehicleSelectorField` puede dejar el form en estado inconsistente
Si el usuario crea un vehículo nuevo desde el bottom sheet (`VehicleSelectionBottomSheet`), `VehicleSelectorField` actualiza el field manualmente con `field.didChange(savedVehicle.id)`. **No usa FormBuilder reactivity**. Si la respuesta del bottom sheet cambia su shape, romper esta navegación silenciosamente.

### `allowedBrands` validation se ejecuta al submit
La validación de marca se hace al pulsar Enviar (no inline). Si el evento es multi-marca (`allowedBrands.isEmpty`), no se valida. Si el evento tiene marcas específicas y la del vehículo no coincide, snackbar 6s y se bloquea submit.

### `RegistrationFormCubit` es `@injectable` (no singleton)
Cada `EventRegistrationPage` crea su instancia. No usar `getIt<RegistrationFormCubit>()` fuera de la página (siempre crea nueva).

### `MyRegistrationsCubit` es `@injectable` pero global
En `main.dart` se inyecta como `BlocProvider(create: (_) => getIt<MyRegistrationsCubit>())` al root. Esto hace que `getIt<MyRegistrationsCubit>()` devuelva instancias nuevas, pero el cubit ya provisto al árbol global es uno solo. Si en algún lado se hace `getIt<MyRegistrationsCubit>()` directamente, no obtendrás el mismo. **Siempre leer con `context.read<MyRegistrationsCubit>()`**.

### `RegistrationStatus.readyForEdit` doble propósito
Cuando el organizador habilita "Listo para editar", el rider puede modificar su inscripción. Para el organizador, `readyForEdit` se ve como un estado pendiente más; para el rider, es la única forma de editar después de aprobar.

### Igualdad por id de `EventRegistrationModel`
Como con `EventModel`, dos inscripciones con `id == null` son iguales. Cuidado al usar `Set<EventRegistrationModel>` o `.contains()` con modelos no persistidos.

### `VehicleSummaryModel` es un snapshot
Si el rider cambia su vehículo después de inscribirse, la inscripción mantiene la `vehicleSummary` original. El organizador verá los datos del momento. Esto es **intencional** para evitar que cambios retroactivos rompan asistencias confirmadas.

### `_buildRiderProfile` no incluye `id`
`RiderProfileModel` se construye sin `id`. El backend (Firestore) usa `userId` como key del documento, así que no se necesita id propio.

### `onChangeRegistration` puede agregar registros nuevos
Si el rider crea una inscripción desde una pantalla diferente, `MyRegistrationsCubit.onChangeRegistration(updatedRegistration)` la inserta en `_registrations`. Es la forma de propagar cambios sin re-fetch.

### `RegistrationFormScaffold` listener actualiza `MyRegistrationsCubit` al guardar
Tras `data(saved)`, hace `context.read<MyRegistrationsCubit>().onChangeRegistration(saved)` para mantener "Mis inscripciones" actualizado sin refetch.

---

## 13. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Modelo + enums | `lib/features/event_registration/domain/model/event_registration_model.dart` |
| Vehicle summary model | `lib/features/event_registration/domain/model/vehicle_summary_model.dart` |
| Aggregate registration + event | `lib/features/event_registration/domain/model/registration_with_event.dart` |
| Repository interface | `lib/features/event_registration/domain/repository/event_registration_repository.dart` |
| Use cases | `lib/features/event_registration/domain/use_cases/` |
| DTO | `lib/features/event_registration/data/dto/event_registration_dto.dart` |
| Service Dio manual | `lib/features/event_registration/data/service/registration_service.dart` |
| Repository impl | `lib/features/event_registration/data/repository/event_registration_repository_impl.dart` |
| Cubit del form (pre-llenado) | `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` |
| Cubit "mis inscripciones" (global) | `lib/features/event_registration/presentation/my_registrations_cubit.dart` |
| Page del form | `lib/features/event_registration/presentation/event_registration_page.dart` |
| View del form | `lib/features/event_registration/presentation/registration_form_view.dart` |
| Content del form (validación marca) | `lib/features/event_registration/presentation/registration_form_content.dart` |
| Page de mis inscripciones | `lib/features/event_registration/presentation/my_registrations_page.dart` |
| Data view (search + filter) | `lib/features/event_registration/presentation/my_registrations_data_view.dart` |
| Page de detalle | `lib/features/event_registration/presentation/registration_detail_page.dart` |
| Bottom bar de detalle | `lib/features/event_registration/presentation/widgets/registration_detail_bottom_bar.dart` |
| Card de inscripción (lista) | `lib/features/event_registration/presentation/widgets/inscription_card.dart` |
| Selector de vehículo | `lib/features/event_registration/presentation/widgets/vehicle_selector_field.dart` |
| Checkbox saveToProfile | `lib/features/event_registration/presentation/widgets/save_to_profile_checkbox.dart` |
| Filter bottom sheet | `lib/features/event_registration/presentation/widgets/my_registrations_filter_bottom_sheet.dart` |
| Constantes form fields | `lib/features/event_registration/constants/registration_form_fields.dart` |
| Endpoints API | `lib/core/http/api_routes.dart` |
| Detalle del flujo SOAT relacionado | [vehicles.md](./vehicles.md), [soat.md](./soat.md) |
