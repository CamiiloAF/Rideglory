# Documentación del Feature: Maintenance

> Última actualización: 2026-07-04  
> Alcance: `lib/features/maintenance/`

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Arquitectura por capas](#3-arquitectura-por-capas)
   - 3.1 [Domain](#31-domain)
   - 3.2 [Data](#32-data)
   - 3.3 [Presentation](#33-presentation)
4. [Cubits y estados](#4-cubits-y-estados)
5. [Cálculo de estado dinámico](#5-cálculo-de-estado-dinámico)
6. [Filtros server-side vs client-side](#6-filtros-server-side-vs-client-side)
7. [Auto-creación de scheduled tras completed](#7-auto-creación-de-scheduled-tras-completed)
8. [Flujo de creación / edición](#8-flujo-de-creación--edición)
9. [Rutas de navegación](#9-rutas-de-navegación)
10. [API endpoints](#10-api-endpoints)
11. [Conexiones con otros features](#11-conexiones-con-otros-features)
12. [Patrones y trampas conocidas](#12-patrones-y-trampas-conocidas)
13. [Archivos clave de referencia rápida](#13-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

El feature **Maintenance** registra los mantenimientos de cada moto. Maneja dos "modos":

- **`completed`** — servicio ya realizado (taller, fecha, odómetro, costo, etc.).
- **`scheduled`** — próximo servicio planeado (`nextDate` y/o `nextOdometer`).

A diferencia de inscripciones o vehículos, `maintenance` **no** sube fotos ni adjuntos: solo texto (notas, taller) y números (costo, odómetro). El estado del mantenimiento (`overdue` / `next` / `upToDate`) se **calcula en runtime** comparando con el odómetro actual del vehículo y los umbrales constantes (500 km / 30 días).

Cuando un usuario registra un servicio completado con próximo recordatorio, **el backend devuelve 1 o 2 records**: el completed y, opcionalmente, un scheduled auto-creado.

---

## 2. Modelo de dominio

### `MaintenanceModel`
> `lib/features/maintenance/domain/model/maintenance_model.dart`

```
MaintenanceModel
  id: String?
  userId: String?
  vehicleId: String?
  type: MaintenanceType        (requerido)
  mode: MaintenanceMode        (requerido)
  serviceDate: DateTime?       — solo si mode == completed
  odometerAtService: int?      — solo si mode == completed
  workshop: String?
  cost: double?
  notes: String?
  nextDate: DateTime?          — próximo servicio
  nextOdometer: int?           — próximo servicio
  createdDate: DateTime?
  updatedDate: DateTime?
```

**Getter:** `name → type.label` (etiqueta en español).

### Enums

**`MaintenanceType`** — 8 valores con `@JsonValue`:

| Enum | JsonValue | Label |
|---|---|---|
| `oilChange` | `'OIL_CHANGE'` | Cambio de aceite |
| `brakeCheck` | `'BRAKE_CHECK'` | Revisión de frenos |
| `tireChange` | `'TIRE_CHANGE'` | Cambio de llantas |
| `preventive` | `'PREVENTIVE'` | Revisión general |
| `airFilter` | `'AIR_FILTER'` | Filtro de aire |
| `chainSprocket` | `'CHAIN_SPROCKET'` | Cadena y piñones |
| `electrical` | `'ELECTRICAL'` | Electricidad |
| `other` | `'OTHER'` | Otro |

**`MaintenanceMode`** — 2 valores: `completed`, `scheduled`.

**`MaintenanceStatus`** (calculado, no persistido) — 3 valores: `overdue`, `next`, `upToDate`. Solo aplica a registros `scheduled`; los `completed` no tienen status.

### Constantes globales
```dart
const int kMaintenanceUmbralKm   = 500;
const int kMaintenanceUmbralDays = 30;
```

### Modelos agregados

**`MaintenanceUserListAggregate`** (`domain/model/maintenance_user_list_aggregate.dart`):
```dart
items: List<MaintenanceModel>                          // todos los items de todos los vehículos
summariesByVehicleId: Map<String, MaintenanceListSummary>
```

**`MaintenanceVehicleListResult`** (`domain/model/maintenance_vehicle_list_result.dart`):
```dart
items: List<MaintenanceModel>
summary: MaintenanceListSummary
```

**`MaintenanceListSummary`** (`domain/model/maintenance_list_summary.dart`):
```dart
lastServiceDate: DateTime?
lastServiceMileage: int?
nextServiceDate: DateTime?
```

El backend devuelve `MaintenanceListSummary` por vehículo. La UI usa la summary cuando se filtra por un solo vehículo (header del list view).

---

## 3. Arquitectura por capas

### 3.1 Domain
```
lib/features/maintenance/domain/
├── model/
│   ├── maintenance_model.dart
│   ├── maintenance_list_summary.dart
│   ├── maintenance_user_list_aggregate.dart
│   └── maintenance_vehicle_list_result.dart
├── repository/
│   └── maintenance_repository.dart
└── use_cases/
    ├── add_maintenance_use_case.dart
    ├── update_maintenance_use_case.dart
    ├── delete_maintenance_use_case.dart
    ├── get_maintenance_list_use_case.dart
    └── get_maintenances_by_vehicle_id_use_case.dart
```

**`MaintenanceRepository`** (interface):
```dart
Future<Either<DomainException, MaintenanceUserListAggregate>> getMaintenancesByUserId({
  List<MaintenanceType>? types,
  DateTime? startDate,
  DateTime? endDate,
});

Future<Either<DomainException, MaintenanceVehicleListResult>> getMaintenancesByVehicleId(
  String vehicleId, {
  List<MaintenanceType>? types,
  DateTime? startDate,
  DateTime? endDate,
});

Future<Either<DomainException, List<MaintenanceModel>>> addMaintenance(
  MaintenanceModel maintenance,
  int? nextKmInterval,
);

Future<Either<DomainException, MaintenanceModel>> updateMaintenance(
  MaintenanceModel maintenance,
);

Future<Either<DomainException, Nothing>> deleteMaintenance(
  MaintenanceModel maintenance,
);
```

Notar que `addMaintenance` retorna `List<MaintenanceModel>` (1 o 2 records — ver §7).

**Use cases:**

| Use case | Signature |
|---|---|
| `AddMaintenanceUseCase` | `call(MaintenanceModel, {int? nextKmInterval}) → Future<Either<DomainException, List<MaintenanceModel>>>` |
| `UpdateMaintenanceUseCase` | `call(MaintenanceModel) → Future<Either<DomainException, MaintenanceModel>>` |
| `DeleteMaintenanceUseCase` | `call(MaintenanceModel) → Future<Either<DomainException, Nothing>>` |
| `GetMaintenancesByVehicleIdUseCase` | `execute(String vehicleId) → Future<Either<DomainException, MaintenanceVehicleListResult>>` |
| `GetMaintenanceListUseCase` | `execute({vehicleId?, types?, startDate?, endDate?}) → Future<Either<DomainException, MaintenanceUserListAggregate>>` |

**`GetMaintenanceListUseCase` decide el scoping según `vehicleId`:**
- Si viene `vehicleId` → un único `GET` a `getMaintenancesByVehicleId()`, y envuelve el resultado en un `MaintenanceUserListAggregate` de un solo vehículo (`summariesByVehicleId: {vehicleId: summary}`).
- Si no viene `vehicleId` → `getMaintenancesByUserId()` (fan-out a todos los vehículos del usuario, ver §3.2).

Esto es lo que usa `MaintenancesCubit.fetchMaintenances()` para evitar N requests cuando el filtro de vehículo ya está acotado a **exactamente 1** vehículo (ver §4).

---

### 3.2 Data
```
lib/features/maintenance/data/
├── dto/
│   ├── maintenance_dto.dart                          (@JsonSerializable)
│   ├── vehicle_maintenances_list_response_dto.dart   (items + summary)
│   └── create_maintenance_response_dto.dart          (created: List<MaintenanceDto>)
├── service/
│   └── maintenance_service.dart                      (@singleton @RestApi)
└── repository/
    └── maintenance_repository_impl.dart              (@Injectable(as: MaintenanceRepository))
```

**`MaintenanceDto`** sigue el **Pattern B** (DTO extends Model): `MaintenanceDto extends MaintenanceModel`, con `apiJsonDateTimeConverters`. **Renombra fechas**: `createdDate`/`updatedDate` en model ↔ `createdAt`/`updatedAt` en JSON (`@JsonKey(name: 'createdAt'|'updatedAt')`). Métodos: `MaintenanceDto.fromJson`, `dto.toJson()`; para serializar un `MaintenanceModel` puro se usa la extensión `MaintenanceModelExtension.toJson()` (construye un `MaintenanceDto` temporal y llama su `toJson()`). **No existen** `toModel()`/`fromModel()`/`.toDto()` — un `MaintenanceDto` ya *es* un `MaintenanceModel` (herencia), se puede usar directamente donde se espere el modelo de dominio.

**`CreateMaintenanceResponseDto`**:
```dart
created: List<MaintenanceDto>     // 1 o 2 records
```
La key `'created'` la define el backend; cuando el cliente envía un completed con `nextKmInterval` o `nextDate`, el backend devuelve además el record `scheduled` auto-creado.

**`MaintenanceService` (Retrofit)**:
| Método | HTTP | Path | Body / Query |
|---|---|---|---|
| `getByVehicleId(vehicleId, filter?)` | `GET` | `/maintenances/vehicle/{vehicleId}` | `@Queries() Map<String, dynamic>?` |
| `create(vehicleId, body)` | `POST` | `/maintenances/vehicle/{vehicleId}` | `Map<String, dynamic>` |
| `update(vehicleId, id, body)` | `PATCH` | `/maintenances/vehicle/{vehicleId}/{id}` | `Map<String, dynamic>` |
| `delete(vehicleId, id)` | `DELETE` | `/maintenances/vehicle/{vehicleId}/{id}` | — |

**Query filter** (construido en `MaintenanceRepositoryImpl._buildFilterMap()`):
```
{
  'types': ['OIL_CHANGE', 'TIRE_CHANGE', ...],   // JsonValue strings
  'startDate': '2026-01-01T00:00:00.000Z',
  'endDate':   '2026-12-31T23:59:59.999Z',
}
```

**Body de POST create** (en `_buildCreateBody()`):
```dart
{
  'type':            'OIL_CHANGE' (enum → string),
  'mode':            'COMPLETED' | 'SCHEDULED',
  'serviceDate':     ISO8601?,
  'odometerAtService': int?,
  'workshop':        string?,
  'notes':           string?,
  'nextKmInterval':  int?,           // relativo: 5000 km a partir de ahora
  'nextOdometer':    int?,           // absoluto (redundante; servidor puede calcularlo)
  'nextDate':        ISO8601?,
  'cost':            double?,
}
```

`MaintenanceRepositoryImpl.getMaintenancesByUserId()` hace **N requests paralelas** (uno por vehículo): obtiene los vehículos vía `VehicleRepository.getMyVehicles()` y dispara `getMaintenancesByVehicleId()` para cada uno con `Future.wait`. Después agrega items + `summariesByVehicleId`, y ordena el agregado por `serviceDate ?? createdDate` descendente (más reciente primero) — este es solo el orden "crudo" del repository; la UI reordena por urgencia (ver §4/§5).

`updateMaintenance()` llama a `MaintenanceService.update()`, que ya retorna un `MaintenanceDto` (Pattern B) directamente utilizable como `MaintenanceModel` — no hay paso intermedio `.toModel()`.

---

### 3.3 Presentation
```
lib/features/maintenance/presentation/
├── list/maintenances/
│   ├── maintenances_cubit.dart
│   ├── maintenances_page.dart
│   └── widgets/
│       ├── maintenances_page_view.dart
│       ├── maintenances_data_widget.dart
│       ├── maintenance_grouped_list_item.dart
│       ├── maintenance_section_group.dart
│       ├── maintenance_summary_card.dart
│       ├── maintenance_vehicle_selector.dart
│       └── ... (varios más)
├── form/
│   ├── cubit/maintenance_form_cubit.dart
│   ├── maintenance_form_page.dart
│   └── widgets/
│       ├── maintenance_form_view.dart
│       ├── maintenance_form_content.dart
│       ├── maintenance_type_selection.dart
│       ├── maintenance_status_toggle.dart
│       ├── maintenance_mileage_update_banner.dart
│       └── ... (más)
├── detail/
│   ├── maintenance_detail_page.dart
│   └── widgets/
│       ├── maintenance_detail_view.dart
│       ├── maintenance_type_card.dart
│       ├── maintenance_info_card.dart
│       ├── maintenance_next_service_card.dart
│       ├── maintenance_notes_card.dart
│       └── maintenance_cta_bar.dart
├── delete/
│   └── cubit/
│       ├── maintenance_delete_cubit.dart
│       └── maintenance_delete_state.dart   (freezed)
├── widgets/
│   ├── filter_sheet/...
│   ├── item_card/...
│   ├── maintenance_filters.dart            (data + enums)
│   └── maintenance_filters_bottom_sheet.dart
└── maintenance_type_style.dart             (mapeo enum → color + icon)
```

---

## 4. Cubits y estados

| Cubit | Archivo | DI | Estado |
|---|---|---|---|
| `MaintenancesCubit` | `list/maintenances/maintenances_cubit.dart` | manual (factory) | `ResultState<List<MaintenanceModel>>` |
| `MaintenanceFormCubit` | `form/cubit/maintenance_form_cubit.dart` | `@injectable` | `ResultState<MaintenanceModel>` |
| `MaintenanceDeleteCubit` | `delete/cubit/maintenance_delete_cubit.dart` | `@injectable` | `MaintenanceDeleteState` (freezed) |

### `MaintenancesCubit`

**Estado interno:**
```
_allMaintenances: List<MaintenanceModel>
_summariesByVehicleId: Map<String, MaintenanceListSummary>
_filters: MaintenanceFilters
_searchQuery: String
_currentVehicleMileage: int                  // necesario para calcular status
```

**Métodos:**
- `setCurrentVehicleMileage(int)` — actualiza el odómetro de referencia para cálculo de status.
- `setInitialVehicleFilter(String vehicleId)` — preset al entrar desde una ruta con `initialVehicleId`.
- `summaryForHeader() → MaintenanceListSummary?` — retorna summary del único vehículo filtrado (o null si hay más de uno).
- `fetchMaintenances()` — server-side filters (types, dateRange); **scoping por vehículo activo**: si `_filters.vehicleIds` tiene exactamente 1 elemento, pasa ese `vehicleId` al use case (un único `GET /maintenances/vehicle/{id}` en vez de fan-out a todos los vehículos); si no, deja `vehicleId: null` (fan-out). Al resolver, dispara `AnalyticsEvents.maintenanceHistoryViewed` con `resultCount`, y aplica client filters después.
- `updateSearchQuery(String)` — refiltra localmente (por nombre del tipo).
- `updateFilters(MaintenanceFilters)` — si cambian server filters → fetch; si solo cambian client filters → refiltro local.
- `addMaintenanceLocally(MaintenanceModel)` / `addMaintenancesLocally(List<MaintenanceModel>)` — insertan localmente (lista de 1-2 records) e invalidan la summary cacheada del vehículo afectado (`_summariesByVehicleId.remove(vehicleId)`).
- `updateMaintenanceLocally(MaintenanceModel)`, `deleteMaintenanceLocally(String id)` — ídem, invalidan la summary del vehículo afectado.

**Constructor:** `MaintenancesCubit(GetMaintenanceListUseCase, AnalyticsService)`.

### `MaintenanceFormCubit`

**Estado interno:**
```
formKey: GlobalKey<FormBuilderState>
_editingMaintenance: MaintenanceModel?
preselectedVehicle: VehicleModel?
userId: String?
_resolvedVehicleId: String?
_currentVehicleMileage: int?
_selectedType: MaintenanceType?
_mode: MaintenanceMode = completed
lastSavedRecords: List<MaintenanceModel>?    // 1 o 2 records tras save
```

**Métodos:**
- `initialize({maintenance?, preselectedVehicle?})` — set mode + tipo.
- `setVehicleId(String?)`, `setCurrentVehicleMileage(int?)`.
- `updateSelectedType(MaintenanceType)`, `updateMode(MaintenanceMode)`.
- `saveMaintenance(MaintenanceModel, {int? nextKmInterval})` — si tiene `id` → UPDATE (`UpdateMaintenanceUseCase`, dispara `AnalyticsEvents.maintenanceUpdated`), si no → CREATE (`AddMaintenanceUseCase`, dispara `AnalyticsEvents.maintenanceAdded`). Ambos eventos llevan `maintenanceType` y `maintenanceMode` (completed/scheduled) como params.
- `buildMaintenanceToSave() → MaintenanceModel?` — valida form, construye modelo desde `MaintenanceFormFields`.
- `buildNextKmInterval() → int?` — extrae el km relativo del campo `nextMaintenanceMileage`.
- `shouldChangeVehicleMileage(currentMileage, newMileage)` — helper para banner.

**Constructor:** `MaintenanceFormCubit(AddMaintenanceUseCase, UpdateMaintenanceUseCase, AnalyticsService)`.

### `MaintenanceDeleteCubit`

**Estado** (freezed):
```dart
MaintenanceDeleteState.initial()
MaintenanceDeleteState.loading()
MaintenanceDeleteState.success({required String deletedId})
MaintenanceDeleteState.error({required String message})
```

Método único `deleteMaintenance(MaintenanceModel)` valida `id != null`, llama use case; en éxito dispara `AnalyticsEvents.maintenanceDeleted` (con `maintenanceType`) y emite `success(deletedId)`. También expone `reset()` para volver a `initial()`.

**Constructor:** `MaintenanceDeleteCubit(DeleteMaintenanceUseCase, AnalyticsService)`.

---

## 5. Cálculo de estado dinámico

`MaintenanceModel.calculateStatus(maintenance, currentVehicleMileage)`:

```
Si mode == completed → null (sin status)

overdueByKm   = nextOdometer != null && currentVehicleMileage > nextOdometer
overdueByDate = nextDate     != null && now > nextDate
Si overdueByKm || overdueByDate → overdue

nextByKm   = nextOdometer != null && (nextOdometer - currentVehicleMileage) ≤ 500
nextByDate = nextDate     != null && (nextDate - now).inDays ≤ 30
Si nextByKm || nextByDate → next

Else → upToDate
```

Los umbrales son `kMaintenanceUmbralKm = 500` y `kMaintenanceUmbralDays = 30`.

**Importante:** la UI usa **dos enums** distintos:
- `MaintenanceStatus` (`overdue`, `next`, `upToDate`) en el domain.
- `MaintenanceItemStatus` (`overdue`, `upcoming`, `current`, `completed`) en presentation (`maintenance_grouped_list_item.dart`).

La función `maintenanceStatusOf(MaintenanceModel, int mileage)` mapea:
- completed → `completed`
- `next` → `upcoming`
- `upToDate` → `current`
- `overdue` → `overdue`

### Orden por urgencia (`MaintenancesCubit._compareByUrgency`)

`_applyClientFiltersAndEmit()` ordena el listado filtrado con `filtered.sort(_compareByUrgency)` — **no** es un simple orden por fecha. La regla:

1. **Rank de urgencia** (`_statusRank`), de mayor a menor prioridad:
   - `0` — `scheduled` + `overdue`
   - `1` — `scheduled` + `next`
   - `2` — `scheduled` + `upToDate` (o status `null`)
   - `3` — `completed` (siempre al final, sin importar status)
2. Si dos registros comparten rank, se desempata por fecha más reciente primero: `serviceDate ?? nextDate ?? createdDate` descendente.

Esto reemplaza el orden simple por `serviceDate`/`createdDate` que hacía antes `MaintenanceRepositoryImpl.getMaintenancesByUserId()` (ese orden "crudo" del repository sigue existiendo como fallback, pero la UI siempre reordena por urgencia después de aplicar filtros).

---

## 6. Filtros server-side vs client-side

| Filtro | Where | Tipo |
|---|---|---|
| `types` | Server (query) | `List<MaintenanceType>` |
| `startDate` / `endDate` | Server (query) | `DateTime` |
| `vehicleIds` | **Client** (post-fetch) | `List<String>` |
| `statusFilter` | **Client** | `MaintenanceStatusFilter` (all / overdue / next / upToDate) |
| `searchQuery` | **Client** | `String` (busca solo en `type.label`) |
| orden final | **Client (fijo)** | `MaintenancesCubit._compareByUrgency` — overdue → next → upToDate → completed (ver §5) |

**`MaintenanceFilters.sortBy` (`MaintenanceSortOption`) existe en el modelo de filtros pero no se usa en `MaintenancesCubit`** — el orden real siempre es el fijo por urgencia (`_compareByUrgency`); es un campo vestigial que puede llevar a pensar que el sort es configurable por el usuario cuando no lo es (ver §12).

**Razón de mezclar:** `getMaintenancesByUserId()` agrega resultados de todos los vehículos en un solo aggregate, y el cubit puede filtrar por vehículo sin reqfetch. El cálculo de status depende del odómetro del vehículo, lo cual conviene resolver client-side.

**Search por nombre solamente:** la búsqueda actual filtra `m.name.toLowerCase().contains(query)`, lo que solo cubre la etiqueta del tipo (ej. "Cambio de aceite"). **NO busca** en `workshop`, `notes`, fechas o mileage.

---

## 7. Auto-creación de scheduled tras completed

Cuando el usuario completa un servicio y proporciona `nextKmInterval` o `nextDate`, el backend devuelve **dos** records en `CreateMaintenanceResponseDto.created`:

1. El completed original.
2. Un scheduled auto-creado con `nextOdometer` (calculado server-side) y/o `nextDate`.

Si no hay próximo recordatorio, el backend devuelve solo el completed.

**En el cliente:**
- `AddMaintenanceUseCase.call` retorna `Future<Either<…, List<MaintenanceModel>>>`.
- `MaintenanceFormCubit.saveMaintenance` guarda `lastSavedRecords = savedList`.
- `MaintenanceFormPage.build` hace pop con la lista completa.
- `MaintenancesPageView._onAddMaintenance()` distingue: si recibe `List<MaintenanceModel>`, llama `addMaintenancesLocally`; si recibe un solo `MaintenanceModel`, `addMaintenanceLocally`.

---

## 8. Flujo de creación / edición

```
MaintenanceFormPage(maintenance?, preselectedVehicle?)
  └─ Provee MaintenanceFormCubit
     └─ initialize(maintenance, preselectedVehicle)
        ├─ Si no hay maintenance → muestra MaintenanceTypeSelection (grid de 8 tipos)
        │  └─ updateSelectedType(MaintenanceType)
        │     └─ Muestra MaintenanceFormView
        └─ Si hay maintenance → MaintenanceFormView directamente

MaintenanceFormView
  ├─ MaintenanceStatusToggle (completed vs scheduled)
  ├─ Campos de form (FormBuilder con formKey del cubit):
  │   ├─ vehicleId (si no preselectedVehicle)
  │   ├─ MileageUpdateBanner si user.currentMileage < newMileage
  │   ├─ Si mode == completed:
  │   │   ├─ serviceDate (date picker)
  │   │   ├─ currentMileage (odometerAtService)
  │   │   ├─ workshop, notes, cost
  │   ├─ Common:
  │   │   ├─ nextMaintenanceMileage (relativo, ej. 5000)
  │   │   └─ nextMaintenanceDate (date picker)
  │   └─ MaintenanceContextCard (lectura del vehículo)
  └─ SaveMaintenanceButton → cubit.saveMaintenance()

Listener en MaintenanceFormPage:
  ├─ data(saved) → pop(lastSavedRecords ?? [saved])
  └─ error → snackbar
```

**`buildMaintenanceToSave`** lee del form:
- `type` (de `_selectedType` o campo).
- `mode` (de `_mode`).
- `serviceDate` (default `DateTime.now()` si completed).
- `odometerAtService` (campo `currentMileage` → parsed int, default `_currentVehicleMileage` si completed; `null` si scheduled).
- `nextOdometer`: `baseKm + nextMaintenanceMileage` (relative km field).
- `nextDate`, `workshop`, `notes`, `cost`.

---

## 9. Rutas de navegación

| Ruta | Constante | Builder | Extra |
|---|---|---|---|
| `/maintenances` | `AppRoutes.maintenances` | `MaintenancesPage(initialVehicleId: extra as String?)` | `String?` (vehicleId) |
| `/maintenances/create` | `AppRoutes.createMaintenance` | `MaintenanceFormPage(preselectedVehicle: extra as VehicleModel?)` | `VehicleModel?` |
| `/maintenances/edit` | `AppRoutes.editMaintenance` | `MaintenanceFormPage(maintenance: extra as MaintenanceModel?)` | `MaintenanceModel?` |
| `/maintenances/detail` | `AppRoutes.maintenanceDetail` | `MaintenanceDetailPage(maintenance: extra as MaintenanceModel)` | `MaintenanceModel` (required) |

**Pop results:**
- `createMaintenance` / `editMaintenance` → `List<MaintenanceModel>` o `MaintenanceModel` o `null`.
- `maintenanceDetail` → `MaintenanceModel` (si se editó) o `{action: 'deleted', deletedId: String}` (si se eliminó) o `null`.

---

## 10. API endpoints

| Operación | Método | Endpoint |
|---|---|---|
| Listar de un vehículo | `GET` | `/maintenances/vehicle/{vehicleId}` (query: `types[]`, `startDate`, `endDate`) |
| Crear | `POST` | `/maintenances/vehicle/{vehicleId}` |
| Actualizar | `PATCH` | `/maintenances/vehicle/{vehicleId}/{id}` |
| Eliminar | `DELETE` | `/maintenances/vehicle/{vehicleId}/{id}` |

Base: `ApiRoutes.maintenances = '/maintenances'`. **No hay endpoint "all by user"** — el repository hace fan-out a múltiples requests para listar todos los vehículos del usuario.

---

## 11. Conexiones con otros features

| Feature | Cómo se conecta |
|---|---|
| `vehicles` | `MaintenanceRepositoryImpl.getMaintenancesByUserId()` consume `VehicleRepository.getMyVehicles()` para enumerar vehículos. `MaintenancesCubit.setCurrentVehicleMileage()` lee del `VehicleCubit.currentVehicle.currentMileage`. `MaintenanceFormCubit` sugiere update de odómetro via `MaintenanceMileageUpdateBanner` |
| `profile` | Menú "Mantenimientos" navega a `/maintenances` sin `initialVehicleId` |
| `vehicles/detail` | `VehicleMaintenancesCubit` muestra los últimos mantenimientos del vehículo en la pantalla de detalle |

> **Nota:** El feature no comparte cubits globales (no es `@singleton` ni `@lazySingleton`). Cada pantalla crea su `MaintenancesCubit` o `MaintenanceFormCubit` localmente.

---

## 12. Patrones y trampas conocidas

### 1 o 2 records en respuesta de create
`POST /maintenances/vehicle/{vehicleId}` retorna `CreateMaintenanceResponseDto.created: List<MaintenanceDto>`. Si el cliente envió `nextKmInterval` o `nextDate` en mode completed, el backend devuelve **2 records** (el completed + el scheduled auto-creado). Si solo se creó scheduled puro, devuelve **1 record**.

**Tener cuidado al hacer pop**: pasar la lista completa, no solo `data` (que es el primero).

### Filtros server vs client
`updateFilters(filters)` decide si re-fetch o solo refiltrar:
- Si `types` o `dateRange` cambiaron → `fetchMaintenances()` (HTTP).
- Si solo `vehicleIds` / `statusFilter` / `searchQuery` → `_applyClientFiltersAndEmit()` (sin HTTP).

Si se agregan filtros nuevos, decidir su lado y agregarlos a `_buildFilterMap()` o a `_applyClientFiltersAndEmit()`.

### Dos enums de status (domain vs presentation)
- `MaintenanceStatus` (domain): `overdue` / `next` / `upToDate`.
- `MaintenanceItemStatus` (presentation): `overdue` / `upcoming` / `current` / `completed`.

La función `maintenanceStatusOf()` traduce entre ambos. Conviene mantener el dominio aislado de la representación visual.

### `nextKmInterval` (relativo) vs `nextOdometer` (absoluto)
El campo del form es `nextMaintenanceMileage` (relativo, ej. "5000 km a partir de ahora"). El cubit calcula `nextOdometer = baseKm + relativeKm` y envía **ambos** al backend (`nextKmInterval` + `nextOdometer`). El servidor puede recalcular y el `nextOdometer` final viene en la respuesta.

### Búsqueda solo por nombre
`_searchQuery` filtra `m.name.toLowerCase().contains(...)`, donde `name = type.label`. **No busca** en workshop, notes, fechas o mileage. Si se quiere búsqueda completa, ampliar `_applyClientFiltersAndEmit()`.

### Sin upload de fotos/recibos
`MaintenanceModel` no tiene `imageUrl`/`receiptUrl`. Si se quiere agregar, hay que:
1. Añadir campo al modelo y DTO.
2. Subir a Firebase Storage (similar al patrón de vehículos).
3. Actualizar form para incluir image picker.

### `VehicleRepository` como dependencia
`MaintenanceRepositoryImpl` inyecta `VehicleRepository` (no `VehicleCubit`). Es la única forma de obtener vehículos de forma síncrona sin estar atado al estado del cubit. Si `VehicleRepository` cambia su interfaz, este código también.

### `FormBuilderState` accesible vía `GlobalKey` en el cubit
`MaintenanceFormCubit.formKey` se expone para que la UI lo use. El cubit puede llamar `formKey.currentState!.saveAndValidate()` directamente sin necesidad de context. Es un patrón cómodo pero ata el cubit al `FormBuilder` específico.

### `setInitialVehicleFilter` solo se llama una vez
Es el mecanismo para pre-filtrar la lista al entrar desde `vehicleSoat` o `vehicle_detail`. Si se llama de nuevo durante el ciclo de vida del cubit, sobreescribe los filtros. Verificar antes de re-invocar.

### Sin paginación
`getMaintenancesByVehicleId()` devuelve toda la lista. Si un usuario tiene 1000+ mantenimientos por vehículo, el response puede ser pesado. Considerar paginación si crece.

### `MaintenanceVehicleSelector` solo se muestra si no hay `initialVehicleId`
Si entras a `/maintenances` sin extra → muestra selector y filtra. Si entras con extra (`vehicleId`) → no muestra selector. La summary del header se renderiza solo cuando hay **un solo vehículo** en `_filters.vehicleIds`.

### Scoping automático por vehículo activo (evita fan-out)
`GetMaintenanceListUseCase.execute({vehicleId, ...})` y `MaintenancesCubit.fetchMaintenances()` colaboran para evitar el fan-out de N requests cuando la lista ya está acotada a un solo vehículo: si `_filters.vehicleIds.length == 1`, se pasa ese id al use case y se hace **un único** `GET /maintenances/vehicle/{id}`; si hay 0 o 2+ vehículos en el filtro, se usa `getMaintenancesByUserId()` (fan-out). Esto es puramente una optimización de red — el resultado final (`MaintenanceUserListAggregate`) tiene la misma forma en ambos casos.

### Orden fijo por urgencia, no por selección del usuario
`MaintenanceFilters.sortBy` (`MaintenanceSortOption`: `nextMaintenance`/`date`/`name`) **existe en el modelo pero no se lee en ningún lado** — `MaintenancesCubit._applyClientFiltersAndEmit()` siempre ordena con `_compareByUrgency` (overdue → next → upToDate → completed, empate por fecha reciente). Si se expone un selector de orden en la UI, hay que cablear `sortBy` dentro de `_applyClientFiltersAndEmit()`; hoy cualquier UI que lo use no tendría efecto real.

### Pattern B en `MaintenanceDto` (DTO extends Model)
`MaintenanceDto extends MaintenanceModel` — no hay `toModel()`/`fromModel()`. Para persistir un `MaintenanceModel` de dominio se usa la extensión `MaintenanceModelExtension.toJson()` (crea un `MaintenanceDto` temporal internamente). `MaintenanceRepositoryImpl.updateMaintenance()` envía `maintenance.toJson()` y el `MaintenanceService.update()` ya retorna un `MaintenanceDto` usable directamente como `MaintenanceModel`.

### Analytics de mantenimiento
Los tres cubits reciben `AnalyticsService` inyectado y disparan eventos "fire and forget" (`.ignore()`): `maintenanceHistoryViewed` (con `resultCount`, en `fetchMaintenances()`), `maintenanceAdded`/`maintenanceUpdated` (con `maintenanceType` + `maintenanceMode`, en `MaintenanceFormCubit.saveMaintenance()`) y `maintenanceDeleted` (con `maintenanceType`, en `MaintenanceDeleteCubit`).

---

## 13. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Modelo + enums + umbrales | `lib/features/maintenance/domain/model/maintenance_model.dart` |
| Interface del repository | `lib/features/maintenance/domain/repository/maintenance_repository.dart` |
| Use cases | `lib/features/maintenance/domain/use_cases/` |
| DTO + converters | `lib/features/maintenance/data/dto/maintenance_dto.dart` |
| Service Retrofit | `lib/features/maintenance/data/service/maintenance_service.dart` |
| Repository impl + filter builder | `lib/features/maintenance/data/repository/maintenance_repository_impl.dart` |
| Cubit de lista (con filtros mix) | `lib/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart` |
| Cubit de formulario | `lib/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart` |
| Cubit de borrado | `lib/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart` |
| Filtros (data + enums) | `lib/features/maintenance/presentation/widgets/maintenance_filters.dart` |
| Bottom sheet de filtros | `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart` |
| Style de tipos (color + icon) | `lib/features/maintenance/presentation/maintenance_type_style.dart` |
| Page de lista | `lib/features/maintenance/presentation/list/maintenances/maintenances_page.dart` |
| Page del formulario | `lib/features/maintenance/presentation/form/maintenance_form_page.dart` |
| Page de detalle | `lib/features/maintenance/presentation/detail/maintenance_detail_page.dart` |
| Mapeo enum→status item | `lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_grouped_list_item.dart` |
| Constantes del form | `lib/features/maintenance/constants/maintenance_form_fields.dart` |
| Endpoints API | `lib/core/http/api_routes.dart` (`/maintenances*`) |
