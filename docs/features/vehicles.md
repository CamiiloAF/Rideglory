# Documentación del Feature: Vehicles

> Última actualización: 2026-05-28  
> Alcance: `lib/features/vehicles/`

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Arquitectura por capas](#3-arquitectura-por-capas)
   - 3.1 [Domain](#31-domain)
   - 3.2 [Data](#32-data)
   - 3.3 [Presentation](#33-presentation)
4. [Cubits y estados](#4-cubits-y-estados)
5. [Flujo de creación / edición](#5-flujo-de-creación--edición)
6. [Vehículo principal y selección](#6-vehículo-principal-y-selección)
7. [Subida de imagen](#7-subida-de-imagen)
8. [Archivado y borrado](#8-archivado-y-borrado)
9. [Sub-features](#9-sub-features)
10. [Rutas de navegación](#10-rutas-de-navegación)
11. [API endpoints](#11-api-endpoints)
12. [Conexiones con otros features](#12-conexiones-con-otros-features)
13. [Patrones y trampas conocidas](#13-patrones-y-trampas-conocidas)
14. [Archivos clave de referencia rápida](#14-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

El feature **Vehicles** es el "garage" del usuario. Gestiona el inventario de motocicletas con sus datos técnicos, foto, odómetro, placa, SOAT vinculado, archivado/desarchivado, y selección del vehículo principal.

Es un feature **central**: otras features lo consumen como fuente de verdad para "qué vehículo tengo":
- `event_registration` selecciona un vehículo al inscribirse.
- `maintenance` filtra mantenimientos por vehículo y actualiza el odómetro.
- `profile` muestra el garage.
- `home` destaca el vehículo principal.
- `soat` se ancla a un vehículo específico.

`VehicleCubit` es `@singleton` y vive en el árbol global de `BlocProvider`s desde `main.dart` (no se recrea).

---

## 2. Modelo de dominio

### `VehicleModel`
> `lib/features/vehicles/domain/models/vehicle_model.dart`

```
VehicleModel
  id: String?                  — null si aún no persiste
  name: String                 (requerido)
  brand: String?               — ej. "Honda"
  model: String?
  year: int?
  currentMileage: int          (requerido, default conceptual 0)
  licensePlate: String?
  vin: String?
  purchaseDate: DateTime?
  imageUrl: String?            — URL Firebase Storage
  createdAt: DateTime?
  updatedAt: DateTime?
  isArchived: bool             (default false)
  isMainVehicle: bool          (default false)
  soatStatus: SoatStatus?      — re-exportado desde soat feature
  soatExpiryDate: DateTime?
  color: String?
  engine: String?
  horsepower: String?
  torque: String?
  weight: String?
```

**Re-exporta** `SoatStatus` (enum del feature `soat`) — ver `vehicle_model.dart:3`.

**`copyWith()`** usa **sentinel pattern `_unset = Object()`** para distinguir "no pasado" de "pasado como `null`" en campos opcionales (color, engine, horsepower, torque, weight). Esto permite explícitamente borrar el color via `copyWith(color: null)` sin que se confunda con "mantén el valor anterior".

> El `copyWith` recibe `createdDate` y `updatedDate` como parámetros pero los asigna a `createdAt` y `updatedAt` internamente. Es una rareza heredada: probablemente la API usaba `createdDate`/`updatedDate` antes. Mantener el alias para no romper llamadas existentes.

**Igualdad:** valores de campo por campo (`==` y `hashCode`).

### `SoatModel`
> `lib/features/vehicles/domain/models/soat_model.dart` (versión re-exportada en este feature)

> Importante: existen **dos** `SoatModel`/`SoatStatus` en el repo: el del feature `vehicles` y el del feature `soat`. El de `vehicles` se usa por `VehicleRepository.upsertSoat()` / `getSoat()`. Ver `soat.md` para el flujo completo de SOAT.

---

## 3. Arquitectura por capas

### 3.1 Domain
```
lib/features/vehicles/domain/
├── models/
│   ├── vehicle_model.dart
│   └── soat_model.dart       (espejo del de feature soat)
├── repository/
│   └── vehicle_repository.dart
└── usecases/
    ├── get_vehicles_usecase.dart
    ├── add_vehicle_usecase.dart
    ├── update_vehicle_usecase.dart
    ├── delete_vehicle_usecase.dart
    ├── set_main_vehicle_usecase.dart
    ├── archive_vehicle_usecase.dart
    └── unarchive_vehicle_usecase.dart
```

**`VehicleRepository`** (interface):
```dart
Future<Either<DomainException, List<VehicleModel>>> getMyVehicles();
Future<Either<DomainException, VehicleModel>>       setMainVehicle(String vehicleId);
Future<Either<DomainException, VehicleModel>>       addVehicle(VehicleModel vehicle);
Future<Either<DomainException, VehicleModel>>       updateVehicle(VehicleModel vehicle);
Future<Either<DomainException, void>>               deleteVehicle(String id);
Future<Either<DomainException, String>>             uploadVehicleImage({vehicleId, localImagePath});
Future<Either<DomainException, SoatModel>>          upsertSoat({vehicleId, soat});
Future<Either<DomainException, SoatModel>>          getSoat(String vehicleId);
```

**Use cases:**

| Use case | Decorador | Signature |
|---|---|---|
| `GetMyVehiclesUseCase` | `@injectable` | `call() → Future<Either<DomainException, List<VehicleModel>>>` |
| `AddVehicleUseCase` | `@injectable` | `call(VehicleModel) → Future<Either<DomainException, VehicleModel>>` |
| `UpdateVehicleUseCase` | `@injectable` | `call(VehicleModel) → Future<Either<DomainException, VehicleModel>>` |
| `DeleteVehicleUseCase` | `@injectable` | `call(String id) → Future<Either<DomainException, void>>` |
| `SetMainVehicleUseCase` | `@injectable` | `call(String vehicleId) → Future<Either<DomainException, VehicleModel>>` |
| `ArchiveVehicleUseCase` | `@injectable` | Copia `isArchived: true` + `updatedDate: now`, llama `UpdateVehicleUseCase` |
| `UnarchiveVehicleUseCase` | `@injectable` | Copia `isArchived: false` + `updatedDate: now`, llama `UpdateVehicleUseCase` |

---

### 3.2 Data
```
lib/features/vehicles/data/
├── dto/
│   ├── vehicle_dto.dart           (extends VehicleModel)
│   ├── soat_dto.dart
│   └── *.g.dart                   (generados)
├── service/
│   └── vehicle_service.dart       (@singleton @RestApi)
└── repository/
    └── vehicle_repository_impl.dart (@Injectable(as: VehicleRepository))
```

**`VehicleDto extends VehicleModel`** (patrón especial): hereda todos los campos y añade `@JsonSerializable`. Esto permite que `VehicleService` retorne `VehicleDto` y se use directamente como `VehicleModel` sin un `.toModel()` extra (excepto en `getMyVehicles` que sí mapea con `.toModel()` por consistencia).

**`SoatDto`** es independiente (no hereda de `SoatModel`); su `toModel()` parsea `startDate`/`expiryDate` desde strings ISO.

**`VehicleService` (Retrofit)** — endpoints:
| Método | HTTP | Path | Body |
|---|---|---|---|
| `getMyVehicles()` | `GET` | `/vehicles/my` | — |
| `setMyMainVehicle(vehicleId)` | `PUT` | `/vehicles/my/{vehicleId}/main` | — |
| `createMyVehicle(request)` | `POST` | `/vehicles/my` | `Map<String, dynamic>` |
| `updateVehicle(id, request)` | `PATCH` | `/vehicles/{id}` | `Map<String, dynamic>` |
| `deleteVehicle(id)` | `DELETE` | `/vehicles/hard-delete/{id}` | — |
| `upsertSoat(vehicleId, body)` | `POST` | `/vehicles/{vehicleId}/soat` | `Map<String, dynamic>` |
| `getSoat(vehicleId)` | `GET` | `/vehicles/{vehicleId}/soat` | — |

**Importante:** el endpoint de `DELETE` es `/vehicles/hard-delete/{id}`, no `/vehicles/{id}` — borrado físico, no soft delete.

**`VehicleRepositoryImpl`** — body builder `_vehicleRequest()`:
```dart
{
  'name', 'brand', 'model', 'year', 'currentMileage',
  'licensePlate', 'vin',
  'purchaseDate': ISO8601 via toApiIso8601String(),
  'imageUrl', 'isArchived',
  'engine', 'horsepower', 'torque', 'weight',
}..removeWhere((_, value) => value == null);
```

> El body **NO envía** `color`, `soatStatus`, `soatExpiryDate`, `isMainVehicle`, `createdAt`, `updatedAt`, `id`. El `id` va en el path. Si se agregan campos nuevos al modelo, recordar agregarlos aquí también.

**Imagen vehículo (Firebase Storage):**
```
vehicles/{vehicleId}/cover.jpg
```
Subido directamente por `VehicleRepositoryImpl.uploadVehicleImage()` (no por el backend).

**SOAT body** (en `upsertSoat`):
```dart
{
  'policyNumber': soat.policyNumber,
  'startDate':  ISO8601,
  'expiryDate': ISO8601,
  'insurer':    soat.insurer,
  if (soat.documentUrl != null) 'documentUrl': soat.documentUrl,
}
```

---

### 3.3 Presentation
```
lib/features/vehicles/presentation/
├── cubit/
│   ├── vehicle_cubit.dart
│   ├── vehicle_form_cubit.dart
│   ├── vehicle_form_state.dart           (freezed)
│   └── vehicle_form_state.freezed.dart
├── delete/
│   └── cubit/
│       ├── vehicle_delete_cubit.dart
│       ├── vehicle_delete_state.dart     (freezed)
│       └── vehicle_delete_state.freezed.dart
├── garage/
│   ├── cubit/
│   │   └── vehicle_maintenances_cubit.dart
│   ├── garage_page.dart
│   └── widgets/
│       └── ...                             (≥40 widgets)
├── detail/
│   └── vehicle_detail_page.dart
├── form/
│   ├── vehicle_form_page.dart
│   └── widgets/
│       ├── vehicle_form_view.dart
│       └── sections/...
└── widgets/
    ├── vehicle_card.dart
    ├── vehicle_selector.dart
    └── ...
```

---

## 4. Cubits y estados

| Cubit | Archivo | DI | Estado | Notas |
|---|---|---|---|---|
| `VehicleCubit` | `cubit/vehicle_cubit.dart` | `@singleton` | `ResultState<List<VehicleModel>>` | Mantiene `_vehicles` + `_selectedVehicleId` (memoria) |
| `VehicleFormCubit` | `cubit/vehicle_form_cubit.dart` | `@injectable` | `VehicleFormState` (freezed) | Crea/edita, sube imagen, captura SOAT |
| `VehicleDeleteCubit` | `delete/cubit/vehicle_delete_cubit.dart` | `@injectable` | `VehicleDeleteState` (freezed) | Emite `success(deletedId)` o error |
| `VehicleMaintenancesCubit` | `garage/cubit/vehicle_maintenances_cubit.dart` | `@injectable` | `ResultState<List<MaintenanceModel>>` | Lista mantenimientos del vehículo en detalle |

### `VehicleCubit` — API pública

**Getters:**
```dart
List<VehicleModel> get availableVehicles;   // unmodifiable copy
VehicleModel? get currentVehicle;           // selección actual o main o primero
int? get currentMileage;                    // currentVehicle?.currentMileage
```

`currentVehicle` resuelve en cascada:
1. Si `_selectedVehicleId` apunta a un id existente → ese vehículo.
2. Si no, busca el primero con `isMainVehicle == true`.
3. Si no hay main, retorna `_vehicles.first`.

**Métodos:**
| Método | Efecto |
|---|---|
| `fetchMyVehicles()` | API call → carga `_vehicles`, resetea `_selectedVehicleId` al default (main o first), emite `data`/`empty` |
| `selectVehicle(VehicleModel)` | Actualiza `_selectedVehicleId` y re-emite (no persiste a backend) |
| `updateMileage(int newMileage)` | **Optimistic**: actualiza local primero, luego llama `UpdateVehicleUseCase` (fire-and-forget en lo que respecta a errores — no se manejan) |
| `applySavedVehicleEdit(VehicleModel)` | Reemplaza vehículo en lista local por ID (usado tras `VehicleFormCubit.save`) |
| `setMainVehicle(String vehicleId)` | Llama `SetMainVehicleUseCase`. Si éxito, marca `isMainVehicle: true` en el ganador y `false` en los demás, y selecciona el nuevo main |
| `addVehicleLocally(VehicleModel)` | Append a la lista; si es el primero, lo selecciona |
| `updateSoatLocally(vehicleId, expiryDate)` | Recalcula `SoatStatus` (umbral 30 días) y actualiza `soatExpiryDate` localmente |
| `deleteVehicleLocally(String vehicleId)` | Elimina de lista. Si era la selección, restaura default. Si queda vacío, emite `empty` |
| `clearVehicles()` | Vacía todo y emite `empty` (usado en logout) |

**Cálculo de SoatStatus** (`_soatStatusFrom`, líneas 106–111):
```
daysRemaining < 0  → expired
daysRemaining ≤ 30 → expiringSoon
else               → valid
```

---

### `VehicleFormCubit` — API pública

**Estado** `VehicleFormState` (freezed):
```dart
ResultState<VehicleModel> vehicleResult;
VehicleModel? vehicle;                      // null si creando
String? localImagePath;
String? soatLocalPath;                      // imagen SOAT subida durante form
String? techReviewLocalPath;                // (no integrado a backend aún)
PendingManualSoat? pendingManualSoat;       // SOAT manual capturado pre-creación
```

**`PendingManualSoat`** (clase auxiliar):
```dart
String? policyNumber;
String insurer;            // requerido
DateTime startDate;        // requerido
DateTime expiryDate;       // requerido
String? localImagePath;    // documento opcional
```

**Métodos:**
| Método | Efecto |
|---|---|
| `initialize(VehicleModel? vehicle)` | Setea modo edit/create |
| `pickSoatDocument()`, `setSoatFromLocalPath(path)`, `clearSoatDocument()` | Galería/picker, guarda en `soatLocalPath` |
| `pickTechReviewDocument()`, `clearTechReviewDocument()` | Galería para revisión técnica (placeholder) |
| `storePendingManualSoat(data)`, `clearPendingManualSoat()` | SOAT manual antes de tener vehicleId |
| `saveVehicle(VehicleModel, localImagePath?)` | CREATE o UPDATE + sube imagen si hay |
| `buildVehicleToSave() → VehicleModel?` | Valida form (`saveAndValidate`), construye modelo desde campos `VehicleFormFields` |
| `reset()` | Vuelve a `initial` |

**`buildVehicleToSave`** desarchiva automáticamente si edita un vehículo archivado (`isArchived: false` en el copyWith) — ver §13.

---

### `VehicleDeleteCubit`

**Estado** `VehicleDeleteState` (freezed):
```dart
initial()
loading()
success(String deletedId)
error(String message)
errorLastVehicle(String message)   // declarado pero no usado actualmente
```

`deleteVehicle(vehicleId, availableVehicles)`:
1. Llama `DeleteVehicleUseCase(vehicleId)`.
2. Si éxito, llama `_vehicleCubit.deleteVehicleLocally(vehicleId)`.
3. Emite `success(deletedId)` o `error`.

---

### `VehicleMaintenancesCubit`

`ResultState<List<MaintenanceModel>>`. Getters:
- `lastCompleted: MaintenanceModel?` — último completado (sort serviceDate DESC).
- `nextScheduled: MaintenanceModel?` — próximo scheduled (sort nextDate ASC).

Métodos: `fetchMaintenances(vehicleId)`, `addMaintenanceLocally(...)`, `updateMaintenanceLocally(...)`, `deleteMaintenanceLocally(...)`.

---

## 5. Flujo de creación / edición

```
VehicleFormPage(vehicle?)
  ├─ MultiBlocProvider: FormImageCubit + VehicleFormCubit + VehicleDeleteCubit
  └─ VehicleFormView
     ├─ if (vehicle != null && vehicle.isArchived) → dialog "este vehículo está archivado"
     ├─ Form sections: Cover, BasicInfo, Identification, Specs, Docs
     └─ AppButton "Guardar"
         → VehicleFormCubit.buildVehicleToSave()  (valida form)
            └─ Si vehicle existente está archived → unarchive automáticamente
         → VehicleFormCubit.saveVehicle(vehicle, localImagePath)
            ├─ _createNewVehicle() o _saveExistingVehicle()
            ├─ uploadImage() si hay localImagePath
            └─ Emite ResultState.data(vehicle)
```

**Listener en `VehicleFormView`** post-save (data state):
1. `VehicleCubit.applySavedVehicleEdit(saved)` (si editaba) o `VehicleCubit.addVehicleLocally(saved)` (si creaba).
2. **Si CREANDO + `soatLocalPath != null`** → `pushReplacement` a `SoatConfirmationPage` (mantiene VehicleForm fuera del back stack).
3. **Si CREANDO + `pendingManualSoat != null`** → `_savePendingManualSoatAndPop()` sube documento (si hay) + `upsertSoat()` + pop.
4. Otro caso → `pop(savedVehicle)`.

---

## 6. Vehículo principal y selección

- **Persistido en backend**: bandera `isMainVehicle` (flag por vehículo). API: `PUT /vehicles/my/{vehicleId}/main`.
- **Selección en UI (`_selectedVehicleId`)**: en memoria, **no persiste**. Cada `fetchMyVehicles()` reseta al main vehicle (o primero si no hay).
- **Consumidores de `currentVehicle`:**
  - `event_registration` para defaultear el selector de vehículo.
  - `maintenance` para defaultear el vehículo + sugerir odómetro.
  - `home` para mostrar el vehículo destacado.
- **Cambio de main**: `VehicleCubit.setMainVehicle(vehicleId)` actualiza todas las banderas localmente tras éxito del API.

---

## 7. Subida de imagen

Hay **dos imágenes** distintas:

### Imagen de portada del vehículo
- Path Firebase: `vehicles/{vehicleId}/cover.jpg`.
- Subida por `VehicleRepositoryImpl.uploadVehicleImage()`.
- Disparada desde `VehicleFormCubit._buildVehicleWithImage()` antes de `addVehicle` / `updateVehicle`.
- La URL resultante se incluye en el body como `imageUrl`.

### Documento SOAT (cuando se sube desde el form de vehículo)
- Path Firebase: `soat/{vehicleId}/{timestamp}.{ext}`.
- Manejado por `VehicleFormView._savePendingManualSoatAndPop()` para SOAT manual (modo creación) o por `SoatConfirmationPage` para SOAT con documento (post-creación).
- Si la subida de imagen falla, el SOAT se guarda **sin documentUrl** (catch silencioso). Ver §13.

---

## 8. Archivado y borrado

| Acción | Use case | Efecto |
|---|---|---|
| Archivar | `ArchiveVehicleUseCase` | `vehicle.copyWith(isArchived: true)` → `UpdateVehicleUseCase` |
| Desarchivar | `UnarchiveVehicleUseCase` | `vehicle.copyWith(isArchived: false)` → `UpdateVehicleUseCase` |
| Eliminar (hard) | `DeleteVehicleUseCase` | `DELETE /vehicles/hard-delete/{id}` |

Hard delete = remoción definitiva. **No hay soft delete a nivel del feature vehicles** (el backend puede archivar `maintenances` relacionados, pero el vehículo se elimina).

**Auto-unarchive al editar**: `VehicleFormCubit.buildVehicleToSave()` desarchiva si el vehículo siendo editado tenía `isArchived: true`. Se complementa con el dialog de advertencia previo en `VehicleFormView`.

---

## 9. Sub-features

### Garage (`presentation/garage/`)
- `GaragePage` ↔ tab 1 del bottom navigation.
- `GaragePageView` carga `fetchMyVehicles()` en `initState`.
- `BlocBuilder` maneja estados Initial/Loading/Empty/Error/Data.
- Tap en card → `pushNamed(vehicleDetail, extra: vehicle)`. Al retornar, hace refresh.

### Detail (`presentation/detail/`)
- `VehicleDetailPage` — StatefulWidget que mantiene `currentEvent` local y refresh ticks.
- Provee `VehicleMaintenancesCubit` localmente.
- Sub-secciones: foto + specs + último mantenimiento + próximo + lista de mantenimientos.

### Form (`presentation/form/`)
- `VehicleFormPage` (envuelve form en 3 cubits).
- `VehicleFormView` — listeners + secciones + bottom bar.

### Widget compartido — `VehicleSelector`
> `lib/features/vehicles/presentation/widgets/vehicle_selector.dart`

Dropdown que lee del `VehicleCubit` y muestra solo `!isArchived`. Lo consume `event_registration` (al inscribirse).

### Widget compartido — `VehicleSelectionBottomSheet`
> `lib/shared/widgets/vehicle_selection_bottom_sheet.dart`

Bottom sheet alternativo al dropdown. Usado por `VehicleSelectorField` en el registro de evento.

---

## 10. Rutas de navegación

| Ruta | Constante | Builder | Extras |
|---|---|---|---|
| `/garage` | `AppRoutes.garage` | `GaragePage` | — |
| `/vehicles/detail` | `AppRoutes.vehicleDetail` | `VehicleDetailPage(vehicle: extra as VehicleModel)` | `VehicleModel` |
| `/vehicles/create` | `AppRoutes.createVehicle` | `VehicleFormPage()` | — |
| `/vehicles/edit` | `AppRoutes.editVehicle` | `VehicleFormPage(vehicle: extra as VehicleModel?)` | `VehicleModel?` |
| `/vehicles/soat` | `AppRoutes.vehicleSoat` | `SoatUploadPage(vehicle: extra as VehicleModel)` | `VehicleModel` (delega a feature `soat`) |

`/garage` vive dentro del segundo `StatefulShellBranch` (tab del bottom nav).

---

## 11. API endpoints

| Operación | Método | Endpoint |
|---|---|---|
| Mis vehículos | `GET` | `/vehicles/my` |
| Crear vehículo | `POST` | `/vehicles/my` |
| Actualizar vehículo | `PATCH` | `/vehicles/{id}` |
| Eliminar (hard) | `DELETE` | `/vehicles/hard-delete/{id}` |
| Asignar principal | `PUT` | `/vehicles/my/{vehicleId}/main` |
| Upsert SOAT | `POST` | `/vehicles/{vehicleId}/soat` |
| Get SOAT | `GET` | `/vehicles/{vehicleId}/soat` |

Constantes en `lib/core/http/api_routes.dart` (`vehicles = '/vehicles'`, `myVehicles = '/vehicles/my'`, `vehicleSoat(id)`).

---

## 12. Conexiones con otros features

| Feature | Cómo se conecta |
|---|---|
| `event_registration` | `VehicleSelectorField` lee `VehicleCubit.state`; al inscribirse guarda `vehicleId` y `vehicleSummary` (snapshot placa+marca) |
| `maintenance` | `MaintenanceRepositoryImpl.getMaintenancesByUserId()` consume `VehicleRepository.getMyVehicles()`; `MaintenanceFormCubit` lee `VehicleCubit.currentMileage` para pre-llenar odómetro y propone update si aumentó |
| `profile` | Logout llama `VehicleCubit.clearVehicles()` |
| `home` | `HomeGarageSection` lee `VehicleCubit.state` para destacar el vehículo principal (o el primer no archivado) — además del `HomeData.mainVehicle` que viene del API home |
| `soat` | `VehicleFormView` puede iniciar el flujo SOAT (`SoatConfirmationPage`) durante la creación; el detalle del vehículo muestra el badge SOAT |

---

## 13. Patrones y trampas conocidas

### `VehicleDto extends VehicleModel`
Patrón inusual: el DTO hereda del modelo. Funciona porque Retrofit puede deserializar a `VehicleDto` y devolverlo donde se espera un `VehicleModel`. **Trampa:** si se decide separar DTO de modelo en el futuro, hay que actualizar todos los call sites que reciben `VehicleDto` y lo usan como `VehicleModel`.

### Sentinel `_unset` en `copyWith`
`color`, `engine`, `horsepower`, `torque`, `weight` usan `Object? param = _unset` para distinguir "no pasado" de "pasado como null". Esto sí permite borrar el campo con `copyWith(color: null)`. Si se agregan campos opcionales nullables que se quieran poder borrar, replicar el patrón.

### `createdDate`/`updatedDate` en `copyWith`
El `copyWith` recibe `createdDate`/`updatedDate` como parámetros pero asigna a `createdAt`/`updatedAt`. Es un alias heredado. Si se llaman `copyWith(createdAt: ...)` directamente, **no compila** — hay que usar `createdDate`.

### `updateMileage` es optimistic sin rollback
```dart
Future<void> updateMileage(int newMileage) async {
  // actualiza local primero
  _vehicles = _vehicles.map(...).toList();
  _emitLoadedOrEmpty();
  await _updateVehicleUseCase(updated);   // ← sin await del resultado, sin rollback
}
```
Si la API falla, el odómetro local queda desincronizado hasta el próximo `fetchMyVehicles()`. Aceptable hoy porque el usuario no recibe error, pero considerar rollback si esto crece.

### Selección de vehículo es **session-scoped en RAM**
`_selectedVehicleId` no persiste. Al reiniciar la app o volver del background, se pierde la selección y vuelve al main vehicle. Si quieres recordarla, persistir en `SharedPreferences` y restaurar en `fetchMyVehicles()`.

### Hard delete + dependencias
`DELETE /vehicles/hard-delete/{id}` borra el vehículo físicamente. El backend se encarga de soft-delete-ar maintenances relacionados, pero **inscripciones** que referencian al vehículo via `vehicleSummary` quedan con datos congelados (la inscripción tiene snapshot, no FK).

### `_vehicleRequest` omite campos
El body solo envía 14 campos. **No envía** `color`, `soatStatus`, `soatExpiryDate`, `isMainVehicle`, `id`, `createdAt`, `updatedAt`. Si en el futuro la API soporta más campos, agregarlos aquí también.

### `_savePendingManualSoatAndPop` se traga la excepción de imagen
`VehicleFormView._savePendingManualSoatAndPop()` envuelve `uploadImage()` en `try-catch (_) { }`. Si la imagen falla pero el SOAT (sin documentUrl) se guarda OK, se muestra un warning pero el usuario no sabe en qué falló. Considerar separar los errores.

### Dual flujo SOAT en creación
- **Flujo "con imagen"**: usuario adjunta documento durante el form → al guardar, `pushReplacement` a `SoatConfirmationPage`.
- **Flujo "manual"**: usuario llena `PendingManualSoat` (con o sin imagen) → al guardar el vehículo, `_savePendingManualSoatAndPop()` invoca `upsertSoat` + pop.

Verificar en `VehicleFormView` listener cuál branch se ejecuta según el state del cubit.

### Auto-unarchive silencioso
Si editas un vehículo archivado y guardas, el form **lo desarchiva sin avisar de nuevo**. El dialog inicial sí avisa, pero el save no muestra confirmación extra. Si quieres mantener archivado mientras editas detalles, el comportamiento actual lo impide.

### `availableVehicles` siempre incluye archivados
El getter retorna toda la lista. Si un consumidor (como `VehicleSelector`) necesita solo no-archivados, debe filtrar explícitamente con `.where((v) => !v.isArchived)`. Considerar exponer `unarchivedVehicles` getter.

### `currentVehicle` con lista grande es lineal
`currentVehicle` itera para buscar por id. Hoy las listas son pequeñas (< 10 vehículos por usuario en promedio), pero si crece, considerar usar `Map<String, VehicleModel>`.

### `VehicleCubit` es `@singleton`
No crear instancias nuevas; siempre obtener via `getIt<VehicleCubit>()` o `context.read<VehicleCubit>()`. El BlocProvider raíz en `main.dart` ya lo expone.

---

## 14. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Modelo de vehículo | `lib/features/vehicles/domain/models/vehicle_model.dart` |
| Interface del repository | `lib/features/vehicles/domain/repository/vehicle_repository.dart` |
| Cubit principal (global) | `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` |
| Cubit del formulario | `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart` |
| Estado del formulario | `lib/features/vehicles/presentation/cubit/vehicle_form_state.dart` |
| Cubit de borrado | `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart` |
| Cubit de mantenimientos | `lib/features/vehicles/presentation/garage/cubit/vehicle_maintenances_cubit.dart` |
| Service HTTP | `lib/features/vehicles/data/service/vehicle_service.dart` |
| Repository impl | `lib/features/vehicles/data/repository/vehicle_repository_impl.dart` |
| Page del garage | `lib/features/vehicles/presentation/garage/garage_page.dart` |
| Page del detalle | `lib/features/vehicles/presentation/detail/vehicle_detail_page.dart` |
| Page del formulario | `lib/features/vehicles/presentation/form/vehicle_form_page.dart` |
| View del formulario (listeners) | `lib/features/vehicles/presentation/form/widgets/vehicle_form_view.dart` |
| Selector reutilizable | `lib/features/vehicles/presentation/widgets/vehicle_selector.dart` |
| Constantes del form | `lib/features/vehicles/constants/vehicle_form_fields.dart` |
| API endpoints | `lib/core/http/api_routes.dart` (`/vehicles*`) |
