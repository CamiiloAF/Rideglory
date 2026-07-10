# Documentación del Feature: Vehicles

> Última actualización: 2026-07-04  
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

`VehicleCubit` se registra como `@injectable` (factory) y su instancia única vive en el `BlocProvider` raíz desde `main.dart` (sobre `MaterialApp`); se comparte vía `context.read<VehicleCubit>()`, nunca por `getIt`.

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

### `VehicleSoatFormData`
> `lib/features/vehicles/domain/models/vehicle_soat_form_data.dart`

Ya **no existe** un `SoatModel` propio del feature `vehicles` (el archivo `soat_model.dart` fue eliminado). En su lugar, `VehicleRepository.upsertSoat()` / `getSoat()` usan `VehicleSoatFormData`, un contenedor de datos liviano (no implementa `VehicleDocumentModel`) con `id?`, `vehicleId`, `policyNumber?`, `startDate`, `expiryDate`, `insurer`, `documentUrl?`. El modelo de dominio canónico del SOAT vive en el feature `soat` (`SoatModel`); ver `soat.md` para el flujo completo.

---

## 3. Arquitectura por capas

### 3.1 Domain
```
lib/features/vehicles/domain/
├── models/
│   ├── vehicle_model.dart
│   └── vehicle_soat_form_data.dart   (form data, no es el SoatModel del feature soat)
├── repository/
│   └── vehicle_repository.dart
└── usecases/
    ├── get_vehicles_usecase.dart
    ├── add_vehicle_usecase.dart
    ├── update_vehicle_usecase.dart
    ├── permanently_delete_vehicle_usecase.dart
    ├── set_main_vehicle_usecase.dart
    ├── archive_vehicle_usecase.dart
    └── unarchive_vehicle_usecase.dart
```

**`VehicleRepository`** (interface actual):
```dart
Future<Either<DomainException, List<VehicleModel>>> getMyVehicles();
Future<Either<DomainException, VehicleModel>>       setMainVehicle(String vehicleId);
Future<Either<DomainException, VehicleModel>>       addVehicle(VehicleModel vehicle);
Future<Either<DomainException, VehicleModel>>       updateVehicle(VehicleModel vehicle);
Future<Either<DomainException, void>>               permanentlyDeleteVehicle(String id);
Future<Either<DomainException, String>>             uploadVehicleImage({vehicleId, localImagePath});
Future<Either<DomainException, VehicleSoatFormData>> upsertSoat({vehicleId, soat});
Future<Either<DomainException, VehicleSoatFormData>> getSoat(String vehicleId);
```

> Ya no existe `deleteVehicle()`/`DeleteVehicleUseCase` (hard delete). El único método de borrado es `permanentlyDeleteVehicle()`, que en el backend es un **soft-delete** (ver §8).

**Use cases:**

| Use case | Decorador | Signature |
|---|---|---|
| `GetMyVehiclesUseCase` | `@injectable` | `call() → Future<Either<DomainException, List<VehicleModel>>>` |
| `AddVehicleUseCase` | `@injectable` | `call(VehicleModel) → Future<Either<DomainException, VehicleModel>>` |
| `UpdateVehicleUseCase` | `@injectable` | `call(VehicleModel) → Future<Either<DomainException, VehicleModel>>` |
| `PermanentlyDeleteVehicleUseCase` | `@injectable` | `call(String id) → Future<Either<DomainException, void>>` — delega en `VehicleRepository.permanentlyDeleteVehicle()` |
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

**`SoatDto`** (en `data/dto/soat_dto.dart`) es independiente (no hereda de ningún modelo); expone `.toFormData()` para convertirse a `VehicleSoatFormData`, parseando `startDate`/`expiryDate` desde strings ISO.

**`VehicleService` (Retrofit)** — endpoints:
| Método | HTTP | Path | Body |
|---|---|---|---|
| `getMyVehicles()` | `GET` | `/vehicles/my` | — |
| `setMyMainVehicle(vehicleId)` | `PUT` | `/vehicles/my/{vehicleId}/main` | — |
| `createMyVehicle(request)` | `POST` | `/vehicles/my` | `Map<String, dynamic>` |
| `updateVehicle(id, request)` | `PATCH` | `/vehicles/{id}` | `Map<String, dynamic>` |
| `permanentlyDeleteVehicle(id)` | `DELETE` | `/vehicles/my/{id}` | — |
| `upsertSoat(vehicleId, body)` | `POST` | `/vehicles/{vehicleId}/soat` | `Map<String, dynamic>` |
| `getSoat(vehicleId)` | `GET` | `/vehicles/{vehicleId}/soat` | — |

**Importante:** ya no existe el endpoint `/vehicles/hard-delete/{id}` en el service (ni en ningún otro lugar del código Flutter). El único borrado expuesto a la app es `DELETE /vehicles/my/{id}`, que en el backend es un **soft-delete** (`isDeleted: true`, fila conservada) — ver §8.

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
│   └── vehicle_form_cubit.freezed.dart
├── delete/
│   └── cubit/
│       ├── vehicle_action_cubit.dart
│       ├── vehicle_action_state.dart     (freezed, part of vehicle_action_cubit.dart)
│       └── vehicle_action_cubit.freezed.dart
├── garage/
│   ├── cubit/
│   │   └── vehicle_maintenances_cubit.dart
│   ├── garage_page.dart
│   ├── garage_page_view.dart
│   └── widgets/
│       └── ...                             (≥45 widgets)
├── detail/
│   └── vehicle_detail_page.dart
├── form/
│   ├── vehicle_form_page.dart
│   ├── vehicle_form_body.dart
│   └── widgets/
│       ├── vehicle_form_view.dart
│       └── ...                             (secciones: cover, básica, identificación, specs, docs — incl. slots SOAT/RTM)
└── widgets/
    ├── vehicle_card.dart
    ├── vehicle_selector.dart
    └── ...
```

> **Nota de nomenclatura:** la carpeta se sigue llamando `delete/` mismo aunque el cubit que contiene (`VehicleActionCubit`) ya no solo borra — también archiva y desarchiva (ver §4 y §8). No renombrada para minimizar el diff histórico.

---

## 4. Cubits y estados

| Cubit | Archivo | DI | Estado | Notas |
|---|---|---|---|---|
| `VehicleCubit` | `cubit/vehicle_cubit.dart` | `@injectable` (instancia única en BlocProvider raíz) | `ResultState<List<VehicleModel>>` | Mantiene `_vehicles` + `_selectedVehicleId` (memoria); inyecta `AnalyticsService` |
| `VehicleFormCubit` | `cubit/vehicle_form_cubit.dart` | `@injectable` | `VehicleFormState` (freezed) | Crea/edita, sube imagen, captura SOAT y RTM pendientes |
| `VehicleActionCubit` | `delete/cubit/vehicle_action_cubit.dart` | `@injectable` (instancia scoped, obtenida vía `getIt` por `GarageOptionsBottomSheet.show()`) | `VehicleActionState` (freezed) | Reemplazó a `VehicleDeleteCubit`. Unifica archivar/desarchivar/eliminar permanentemente en un solo cubit |
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
| `fetchMyVehicles()` | API call → carga `_vehicles`, asegura un principal local (`_ensureLocalMain`), resetea `_selectedVehicleId` al default (main o first), setea la user property de analytics `has_vehicle` (`'1'`/`'0'`), emite `data`/`empty` |
| `selectVehicle(VehicleModel)` | Actualiza `_selectedVehicleId` y re-emite (no persiste a backend) |
| `updateMileage(int newMileage, {String? vehicleId})` | **Solo avanza el odómetro**: si `newMileage <= currentMileage` del vehículo objetivo, no hace nada (ignora valores menores o iguales). Si avanza, actualiza local primero (optimistic) y luego llama `UpdateVehicleUseCase` (no se manejan errores del await) |
| `applySavedVehicleEdit(VehicleModel)` | Reemplaza vehículo en lista local por ID (usado tras `VehicleFormCubit.save`) |
| `setMainVehicle(String vehicleId)` | Llama `SetMainVehicleUseCase`. Si éxito, marca `isMainVehicle: true` en el ganador y `false` en los demás, selecciona el nuevo main y registra el evento de analytics `vehicleSetMain`. Retorna `String?` con el mensaje de error (o `null` si OK) |
| `addVehicleLocally(VehicleModel)` | Append a la lista; si es el primero, lo selecciona |
| `updateSoatLocally(vehicleId, {required expiryDate})` | Recalcula `SoatStatus` (umbral 30 días) y actualiza `soatExpiryDate` localmente |
| `clearSoatLocally(String vehicleId)` | Reconstruye el `VehicleModel` completo con `soatStatus: SoatStatus.noSoat` y sin `soatExpiryDate` (el `copyWith` normal no puede setear ese campo a `null`) |
| `archiveLocally(String id)` | Marca `isArchived: true, isMainVehicle: false`. Si era principal, promueve el siguiente activo con `_promoteNewMain()` |
| `unarchiveLocally(String id)` | Marca `isArchived: false`. Si no queda ningún vehículo activo con `isMainVehicle: true`, promueve el vehículo recién desarchivado a principal |
| `deleteLocally(String id)` | Elimina de lista. Si era la selección, restaura default. Si queda vacío, emite `empty` |
| `clearVehicles()` | Vacía todo y emite `empty` (usado en logout, ver §12 `VehicleSessionSync`) |

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
PendingRtm? pendingRtm;                     // RTM (tecnomecánica) capturada pre-creación
```

**`PendingManualSoat`** (clase auxiliar):
```dart
String? policyNumber;
String insurer;            // requerido
DateTime startDate;        // requerido
DateTime expiryDate;       // requerido
String? localImagePath;    // documento opcional
```

**`PendingRtm`** (clase auxiliar, agregada con la integración de tecnomecánica al form de vehículo):
```dart
String cdaName;             // requerido
DateTime startDate;         // requerido
DateTime expiryDate;        // requerido
String? documentUrl;
String? localImagePath;     // documento opcional
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

### `VehicleActionCubit`

Reemplazó a `VehicleDeleteCubit` (eliminado). Unifica las tres acciones destructivas/de estado sobre un vehículo — archivar, desarchivar y eliminar permanentemente — en un solo cubit, cada una con su propio use case pero compartiendo estado de loading/error.

**Estado** `VehicleActionState` (freezed):
```dart
initial()
loading()
archiveSuccess({required String archivedId})
unarchiveSuccess({required String unarchivedId})
permanentDeleteSuccess({required String deletedId})
error({required String message})
errorLastVehicle({required String message})   // declarado pero no usado actualmente
```

**Constructor:** recibe `PermanentlyDeleteVehicleUseCase`, `ArchiveVehicleUseCase`, `UnarchiveVehicleUseCase`, la instancia de `VehicleCubit` (inyectada, no vía `context.read` — el cubit la usa para actualizar la lista local tras éxito) y `AnalyticsService`.

**Métodos:**
| Método | Efecto |
|---|---|
| `permanentlyDeleteVehicle(String vehicleId)` | Llama `PermanentlyDeleteVehicleUseCase`. Si éxito, registra el evento `vehicleDeleted` y emite `permanentDeleteSuccess`. **No** actualiza `VehicleCubit` directamente — eso lo hace el listener de `GarageOptionsBottomSheet` (`vehicleCubit.deleteLocally(...)`) al recibir el estado |
| `archiveVehicle(VehicleModel vehicle)` | Llama `ArchiveVehicleUseCase`. Si éxito, sí llama `_vehicleCubit.archiveLocally(vehicle.id!)` directamente, registra `vehicleArchived` y emite `archiveSuccess` |
| `unarchiveVehicle(VehicleModel vehicle)` | Llama `UnarchiveVehicleUseCase`. Si éxito, llama `_vehicleCubit.unarchiveLocally(vehicle.id!)`, registra `vehicleUnarchived` y emite `unarchiveSuccess` |
| `reset()` | Vuelve a `initial` |

> Inconsistencia menor: `archiveVehicle`/`unarchiveVehicle` sincronizan `VehicleCubit` desde dentro del cubit; `permanentlyDeleteVehicle` delega esa sincronización al widget consumidor (`GarageOptionsBottomSheet`). Funciona porque ese es el único consumidor hoy, pero si se agrega otro punto de entrada para borrar, hay que recordar llamar `deleteLocally` manualmente.

**Instanciación:** no vive en el `BlocProvider` raíz — `GarageOptionsBottomSheet.show()` crea una instancia scoped por bottom sheet vía `getIt<VehicleActionCubit>()..reset()` y la provee con `BlocProvider<VehicleActionCubit>.value(...)` solo dentro del sheet.

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
  ├─ MultiBlocProvider: FormImageCubit + VehicleFormCubit
  │    (VehicleDeleteCubit ya no se provee aquí — el borrado vive en VehicleActionCubit, scoped al garage)
  └─ VehicleFormView
     ├─ if (vehicle != null && vehicle.isArchived) → dialog "este vehículo está archivado"
     ├─ Form sections: Cover, BasicInfo, Identification, Specs, Docs (incl. slots SOAT y RTM)
     └─ AppButton "Guardar"
         → VehicleFormCubit.buildVehicleToSave()  (valida form)
            └─ Si vehicle existente está archived → unarchive automáticamente
         → VehicleFormCubit.saveVehicle(vehicle, localImagePath)
            ├─ _createNewVehicle() o _saveExistingVehicle()
            ├─ uploadImage() si hay localImagePath
            └─ Emite ResultState.data(vehicle)
```

**Listener en `VehicleFormView._formListener`** post-save (data state):
1. `VehicleCubit.applySavedVehicleEdit(saved)` (si editaba) o `VehicleCubit.addVehicleLocally(saved)` (si creaba).
2. **Si CREANDO + `soatLocalPath != null`** → `pushReplacementNamed(soatManualCapture, SoatManualCaptureParams(vehicle: saved, initialLocalImagePath: soatPath))` (mantiene VehicleForm fuera del back stack; `SoatConfirmationPage` fue eliminada).
3. **Si CREANDO + (`pendingManualSoat != null` o `pendingRtm != null`)** → `_savePendingDocumentsAndPop()` (renombrado desde `_savePendingManualSoatAndPop`) sube el/los documento(s) pendiente(s) (si hay) y guarda **SOAT y/o RTM** vía `VehicleRepository.upsertSoat()` y `SaveTecnomecanicaUseCase`, luego muestra snackbar de éxito y hace pop.
4. Otro caso (sin documentos pendientes) → snackbar de éxito inmediato + `pop(savedVehicle)`.

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
- Path Firebase: `soat/{vehicleId}/{timestamp}_soat.{ext}`.
- Manejado por `VehicleFormView._savePendingDocumentsAndPop()` para SOAT manual (modo creación) o por `SoatManualCapturePage` (pantalla unificada) para SOAT con documento (post-creación).
- Si la subida de imagen falla, el SOAT se guarda **sin documentUrl** (catch silencioso). Ver §13.

### Documento RTM / tecnomecánica (cuando se sube desde el form de vehículo)
- Path Firebase: `tecnomecanica/{vehicleId}/{timestamp}_rtm.{ext}`.
- Mismo método `_savePendingDocumentsAndPop()`, que ahora sube SOAT y RTM pendientes en el mismo paso post-creación (antes solo manejaba SOAT). Usa `SaveTecnomecanicaUseCase` del feature `tecnomecanica`.
- Mismo catch silencioso que SOAT si la subida de imagen falla.

---

## 8. Archivado y borrado

| Acción | Use case | Efecto |
|---|---|---|
| Archivar | `ArchiveVehicleUseCase` | `vehicle.copyWith(isArchived: true)` → `UpdateVehicleUseCase` (PATCH). Si el vehículo era principal, el backend promueve el siguiente activo. `VehicleCubit.archiveLocally()` espeja la lógica localmente. |
| Desarchivar | `UnarchiveVehicleUseCase` | `vehicle.copyWith(isArchived: false)` → `UpdateVehicleUseCase` (PATCH). Si no queda ningún vehículo activo con `isMainVehicle: true`, el backend promueve el vehículo desarchivado a principal. `VehicleCubit.unarchiveLocally()` espeja la misma lógica. |
| Eliminar permanentemente | `PermanentlyDeleteVehicleUseCase` | `DELETE /vehicles/my/{id}` → soft-delete en backend (`isDeleted: true`, fila conservada en BD). Si el vehículo era principal, el backend promueve el siguiente activo. `VehicleCubit.deleteLocally(id)` lo elimina de la lista local. |

> **Nota:** ya no existe ningún endpoint `/vehicles/hard-delete/{id}` en el código Flutter (ni `DeleteVehicleUseCase`). El único borrado expuesto a la app es `DELETE /vehicles/my/{id}` (soft-delete), vía `VehicleActionCubit.permanentlyDeleteVehicle()`.

**Auto-unarchive al editar**: `VehicleFormCubit.buildVehicleToSave()` desarchiva si el vehículo siendo editado tenía `isArchived: true`. Se complementa con el dialog de advertencia previo en `VehicleFormView`.

**Promoción a principal al desarchivar**: si el usuario desarchiva el único vehículo activo (o el primero cuando no hay ningún principal), el backend (`vehicles.service.ts → update()`) y `VehicleCubit.unarchiveLocally()` lo promueven a `isMainVehicle: true` automáticamente.

**Entry point único**: las tres acciones (archivar, desarchivar, eliminar permanentemente) se disparan desde `GarageOptionsBottomSheet` (`presentation/garage/widgets/garage_options_bottom_sheet.dart`), que muestra opciones distintas según `vehicle.isArchived` — si está archivado: "Restaurar" + "Eliminar permanentemente"; si no: "Marcar como principal" (si no lo es ya), "Editar", "Agregar mantenimiento", "Archivar". Cada acción destructiva pasa antes por `ConfirmationDialog.show()`.

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
- `VehicleFormPage` (envuelve form en 2 cubits: `FormImageCubit` + `VehicleFormCubit`; ya no provee `VehicleDeleteCubit`).
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

> La ruta `/vehicles/soat` (`AppRoutes.vehicleSoat`) y `SoatUploadPage` fueron eliminadas. Para agregar/renovar SOAT, la sección de documentos usa `SoatEntryFlow.start(context, ...)` del feature `soat`.

`/garage` vive dentro del segundo `StatefulShellBranch` (tab del bottom nav).

---

## 11. API endpoints

| Operación | Método | Endpoint |
|---|---|---|
| Mis vehículos | `GET` | `/vehicles/my` |
| Crear vehículo | `POST` | `/vehicles/my` |
| Actualizar vehículo | `PATCH` | `/vehicles/{id}` |
| Eliminar permanentemente (soft-delete) | `DELETE` | `/vehicles/my/{id}` |
| Asignar principal | `PUT` | `/vehicles/my/{vehicleId}/main` |
| Upsert SOAT | `POST` | `/vehicles/{vehicleId}/soat` |
| Get SOAT | `GET` | `/vehicles/{vehicleId}/soat` |
| Eliminar SOAT | `DELETE` | `/vehicles/{vehicleId}/soat` (vía `DeleteSoatUseCase`; ver `soat.md` §6.5) |

Constantes en `lib/core/http/api_routes.dart` (`vehicles = '/vehicles'`, `myVehicles = '/vehicles/my'`, `vehicleSoat(id)`).

---

## 12. Conexiones con otros features

| Feature | Cómo se conecta |
|---|---|
| `event_registration` | `VehicleSelectorField` lee `VehicleCubit.state`; al inscribirse guarda `vehicleId` y `vehicleSummary` (snapshot placa+marca) |
| `maintenance` | `MaintenanceRepositoryImpl.getMaintenancesByUserId()` consume `VehicleRepository.getMyVehicles()`; `MaintenanceFormCubit` lee `VehicleCubit.currentMileage` para pre-llenar odómetro y propone update si aumentó |
| `profile` | Logout llama `VehicleCubit.clearVehicles()` |
| `home` | `HomeGarageSection` lee **exclusivamente** `VehicleCubit.state`. Filtra activos (`!isArchived`) antes de mostrar el principal. `MainShell` dispara `fetchMyVehicles()` al montar para que Home tenga datos de inmediato |
| `authentication` (ciclo de vida de sesión) | `VehicleSessionSync` (`lib/shared/widgets/vehicle_session_sync.dart`), montado en `MyApp` envolviendo `MaterialApp.router`, escucha `AuthCubit` y llama `VehicleCubit.fetchMyVehicles()` al autenticar o `clearVehicles()` al desautenticar — evita que el garage de la sesión anterior quede visible tras cambiar de cuenta sin reiniciar la app (ver §13) |
| `tecnomecanica` | `VehicleFormView` puede capturar una RTM pendiente (`PendingRtm`) durante la creación del vehículo y guardarla junto al SOAT vía `SaveTecnomecanicaUseCase` en `_savePendingDocumentsAndPop()`; el detalle y el slot del form de edición muestran el estado RTM de forma análoga al SOAT |
| `soat` | `VehicleFormView` puede iniciar el flujo SOAT (`SoatManualCapturePage`, ruta `soatManualCapture`) durante la creación; el detalle del vehículo (`vehicle_soat_card.dart`) y el slot del form de edición (`vehicle_soat_form_slot.dart`) muestran el estado SOAT y permiten eliminarlo (`DeleteSoatUseCase` + `VehicleCubit.clearSoatLocally`) |

---

## 13. Patrones y trampas conocidas

### `VehicleDto extends VehicleModel`
Patrón inusual: el DTO hereda del modelo. Funciona porque Retrofit puede deserializar a `VehicleDto` y devolverlo donde se espera un `VehicleModel`. **Trampa:** si se decide separar DTO de modelo en el futuro, hay que actualizar todos los call sites que reciben `VehicleDto` y lo usan como `VehicleModel`.

### Sentinel `_unset` en `copyWith`
`color`, `engine`, `horsepower`, `torque`, `weight` usan `Object? param = _unset` para distinguir "no pasado" de "pasado como null". Esto sí permite borrar el campo con `copyWith(color: null)`. Si se agregan campos opcionales nullables que se quieran poder borrar, replicar el patrón.

### `createdDate`/`updatedDate` en `copyWith`
El `copyWith` recibe `createdDate`/`updatedDate` como parámetros pero asigna a `createdAt`/`updatedAt`. Es un alias heredado. Si se llaman `copyWith(createdAt: ...)` directamente, **no compila** — hay que usar `createdDate`.

### `updateMileage` solo avanza, y es optimistic sin rollback
```dart
Future<void> updateMileage(int newMileage, {String? vehicleId}) async {
  // ...
  if (newMileage <= vehicle.currentMileage) return;   // ← ignora retrocesos
  // actualiza local primero
  _vehicles = _vehicles.map(...).toList();
  _emitLoadedOrEmpty();
  await _updateVehicleUseCase(updated);   // ← sin manejar el resultado, sin rollback
}
```
Si la API falla, el odómetro local queda desincronizado hasta el próximo `fetchMyVehicles()`. Aceptable hoy porque el usuario no recibe error, pero considerar rollback si esto crece. El guard `newMileage <= currentMileage` es intencional: el odómetro no puede retroceder desde la UI.

### Selección de vehículo es **session-scoped en RAM**
`_selectedVehicleId` no persiste. Al reiniciar la app o volver del background, se pierde la selección y vuelve al main vehicle. Si quieres recordarla, persistir en `SharedPreferences` y restaurar en `fetchMyVehicles()`.

### Ya no existe "hard delete" en el código Flutter
Hasta antes de la fase de "eliminación permanente", el service tenía un endpoint `/vehicles/hard-delete/{id}` (borrado físico). Fue eliminado: hoy el único borrado es `DELETE /vehicles/my/{id}` (soft-delete, `PermanentlyDeleteVehicleUseCase` → `VehicleActionCubit.permanentlyDeleteVehicle`). El backend se encarga de soft-delete-ar maintenances relacionados, pero **inscripciones** que referencian al vehículo via `vehicleSummary` quedan con datos congelados (la inscripción tiene snapshot, no FK).

### `_vehicleRequest` omite campos
El body solo envía 14 campos. **No envía** `color`, `soatStatus`, `soatExpiryDate`, `isMainVehicle`, `id`, `createdAt`, `updatedAt`. Si en el futuro la API soporta más campos, agregarlos aquí también.

### `_savePendingDocumentsAndPop` se traga la excepción de imagen
`VehicleFormView._savePendingDocumentsAndPop()` (renombrado desde `_savePendingManualSoatAndPop` al integrar RTM) envuelve cada `uploadImage()` (SOAT y RTM) en `try-catch (_) { }`. Si la imagen falla pero el documento (sin `documentUrl`) se guarda OK, se muestra un warning pero el usuario no sabe en qué falló. Considerar separar los errores.

### Dual flujo SOAT en creación (y ahora también RTM)
- **Flujo "con imagen" (solo SOAT)**: usuario adjunta documento SOAT durante el form → al guardar, `pushReplacementNamed(soatManualCapture, ...)` (la pantalla unificada `SoatManualCapturePage`).
- **Flujo "manual" (SOAT y/o RTM)**: usuario llena `PendingManualSoat` y/o `PendingRtm` (con o sin imagen) → al guardar el vehículo, `_savePendingDocumentsAndPop()` invoca `upsertSoat` y/o `SaveTecnomecanicaUseCase` + pop.

Verificar en `VehicleFormView._formListener` cuál branch se ejecuta según el state del cubit.

### `VehicleSessionSync` — sin él, el garage "recuerda" al usuario anterior
`VehicleCubit` es una instancia única de larga vida (vive en el `BlocProvider` raíz, no se recrea entre logins). Sin `VehicleSessionSync` (`lib/shared/widgets/vehicle_session_sync.dart`, envolviendo `MaterialApp.router` en `main.dart`), cerrar sesión y entrar con otra cuenta sin reiniciar la app dejaría el garage de la cuenta anterior visible: el guard `if (state is Initial)` de `MainShell` no vuelve a disparar el fetch. `VehicleSessionSync` escucha `AuthCubit` y llama `fetchMyVehicles()`/`clearVehicles()` en cada transición de autenticación.

### Auto-unarchive silencioso
Si editas un vehículo archivado y guardas, el form **lo desarchiva sin avisar de nuevo**. El dialog inicial sí avisa, pero el save no muestra confirmación extra. Si quieres mantener archivado mientras editas detalles, el comportamiento actual lo impide.

### `availableVehicles` siempre incluye archivados
El getter retorna toda la lista. Si un consumidor (como `VehicleSelector`) necesita solo no-archivados, debe filtrar explícitamente con `.where((v) => !v.isArchived)`. Considerar exponer `unarchivedVehicles` getter.

### `currentVehicle` con lista grande es lineal
`currentVehicle` itera para buscar por id. Hoy las listas son pequeñas (< 10 vehículos por usuario en promedio), pero si crece, considerar usar `Map<String, VehicleModel>`.

### `VehicleDeleteCubit` fue reemplazado por `VehicleActionCubit`
No buscar `vehicle_delete_cubit.dart`/`vehicle_delete_state.dart`; fueron eliminados. `VehicleActionCubit` (`presentation/delete/cubit/vehicle_action_cubit.dart`) asume archivar, desarchivar y eliminar permanentemente. La carpeta se sigue llamando `delete/` por compatibilidad histórica del path.

### `VehicleCubit` es global pero NO singleton de DI
Está registrado como `@injectable` (factory). Su instancia única vive en el `BlocProvider` raíz de `main.dart` (sobre `MaterialApp`), que maneja su ciclo de vida. Para acceder a esa instancia compartida usar SIEMPRE `context.read<VehicleCubit>()` (nunca `getIt<VehicleCubit>()`, que crearía una instancia nueva y duplicaría el estado). El `StatefulShellRoute` la reexpone con `BlocProvider.value(value: context.read<VehicleCubit>())` en `main_shell.dart`.

---

## 14. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Modelo de vehículo | `lib/features/vehicles/domain/models/vehicle_model.dart` |
| Form data del SOAT (no es el modelo de dominio) | `lib/features/vehicles/domain/models/vehicle_soat_form_data.dart` |
| Interface del repository | `lib/features/vehicles/domain/repository/vehicle_repository.dart` |
| Use case de eliminación permanente (soft-delete) | `lib/features/vehicles/domain/usecases/permanently_delete_vehicle_usecase.dart` |
| Cubit principal (global) | `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` |
| Cubit del formulario | `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart` |
| Estado del formulario | `lib/features/vehicles/presentation/cubit/vehicle_form_state.dart` |
| Cubit de archivar/desarchivar/eliminar | `lib/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart` |
| Cubit de mantenimientos | `lib/features/vehicles/presentation/garage/cubit/vehicle_maintenances_cubit.dart` |
| Service HTTP | `lib/features/vehicles/data/service/vehicle_service.dart` |
| Repository impl | `lib/features/vehicles/data/repository/vehicle_repository_impl.dart` |
| Page del garage | `lib/features/vehicles/presentation/garage/garage_page.dart` |
| Page del detalle | `lib/features/vehicles/presentation/detail/vehicle_detail_page.dart` |
| Page del formulario | `lib/features/vehicles/presentation/form/vehicle_form_page.dart` |
| View del formulario (listeners) | `lib/features/vehicles/presentation/form/widgets/vehicle_form_view.dart` |
| Bottom sheet de acciones (archivar/eliminar/editar) | `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` |
| Selector reutilizable | `lib/features/vehicles/presentation/widgets/vehicle_selector.dart` |
| Constantes del form | `lib/features/vehicles/constants/vehicle_form_fields.dart` |
| Sincronización con ciclo de vida de sesión | `lib/shared/widgets/vehicle_session_sync.dart` |
| API endpoints | `lib/core/http/api_routes.dart` (`/vehicles*`) |
