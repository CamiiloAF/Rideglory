# Fase 2 — Vehicle Image Cleanup

**Timestamp:** 2026-06-19T20:30:37Z (corregido: 2026-06-19T20:30:37Z)
**Slug:** `storage-hygiene`
**Depende de:** Fase 1 (Storage Delete Utility)
**Nivel rg-exec recomendado:** normal

---

## Objetivo

Al reemplazar la imagen de un vehículo o eliminar el vehículo permanentemente, el archivo anterior en Firebase Storage se borra de forma automática, sin acumulación silenciosa de imágenes huérfanas. Archivar un vehículo no borra su imagen — este comportamiento se preserva y se documenta explícitamente.

---

## Alcance (entra / no entra)

### Entra

- Inyectar `ImageStorageService` en `VehicleRepositoryImpl` en lugar del `FirebaseStorage` directo para el borrado; mantener `FirebaseStorage` solo si el upload via repositorio no se migra en esta fase (ver Sub-tarea A).
- **Sub-tarea A (diferible):** migrar el upload de imagen de vehículo desde `VehicleRepositoryImpl.uploadVehicleImage` (que usa `FirebaseStorage` directamente) a `ImageStorageService.uploadImage`. Si el tiempo es limitado, diferir la migración de upload pero garantizar que `ImageStorageService` quede inyectado en el repositorio para consistencia de DI.
- **Sub-tarea B (obligatoria):** integrar `ImageStorageService.deleteByUrl` en dos flujos:
  1. **Reemplazo de imagen:** en `VehicleFormCubit._saveExistingVehicle`, capturar `state.vehicle?.imageUrl` como `oldImageUrl` antes de cualquier operación asincrónica. Tras el update exitoso al backend, retornar el resultado al llamador (`saveVehicle`). En `saveVehicle`, dentro del fold de éxito y DESPUÉS de `emit(ResultState.data(...))`, llamar `deleteByUrl(oldImageUrl)` fire-and-forget.
  2. **Eliminación permanente:** `VehicleActionCubit.permanentlyDeleteVehicle` cambia su firma de `String vehicleId` a `VehicleModel vehicle`. Emite `permanentDeleteSuccess(deletedId: vehicle.id!)` ANTES de llamar `deleteByUrl(vehicle.imageUrl)` fire-and-forget.
- Anotar `VehicleRepositoryImpl._vehicleRequest` con `// TODO(debt): migrar a DTO.toJson() — ver plan storage-hygiene`.
- Actualizar **todos** los call sites de `permanentlyDeleteVehicle` para pasar `vehicle` en lugar de `vehicle.id!`. Los call sites conocidos son:
  - `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart`
  - `test/features/vehicles/presentation/delete/vehicle_permanent_delete_dialog_test.dart` (líneas 203–204)
  - `test/features/vehicles/presentation/delete/vehicle_permanent_delete_flow_test.dart` (múltiples invocaciones directas)
- Agregar `MockImageStorageService` como 6to parámetro al constructor de `VehicleActionCubit` en los **cuatro** archivos de test que lo instancian directamente (ya sea vía `GetIt.registerFactory` o en línea):
  1. `test/features/vehicles/presentation/delete/vehicle_permanent_delete_dialog_test.dart` (setUp líneas ~120–128, ctor en línea ~121)
  2. `test/features/vehicles/presentation/delete/vehicle_permanent_delete_flow_test.dart` (`_setUp` líneas ~124–134, ctor en línea ~127 y también el ctor en línea del test TC-perm-B ~194–200 y TC-7B-2 ~304–309)
  3. `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart` (setUp líneas ~121–136, ctor en línea ~129)
  4. `test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart` (setUp líneas ~119–145, ctor en línea ~138)
  En cada setUp agregar el stub: `when(() => mockImageStorageService.deleteByUrl(any())).thenAnswer((_) async {})`.
- Tests unitarios con `verifyInOrder` para ambos flujos.

### No entra

- Borrado de imágenes de eventos, SOAT o RTM (Fases 3–5).
- Archivar vehículo (`ArchiveVehicleUseCase`): la imagen **no** se borra. No se toca este flujo.
- Unarchive: no se toca.
- Barrido retroactivo de imágenes huérfanas preexistentes.
- Corrección del `Map<String, dynamic>` manual en `_vehicleRequest` (solo se anota como deuda).
- Cambios en rideglory-api o Firebase Storage rules.

---

## Que se debe hacer (pasos concretos y ordenados)

### Paso 1 — Importar helpers de test (prerequisito de tests)

Verificar que `test/helpers/storage_mocks.dart` existe (creado en Fase 1). Los tests de esta fase lo importan directamente. No crear nuevas clases mock de `FirebaseStorage`/`Reference` en los archivos de test de esta fase.

### Paso 2 — Inyectar `ImageStorageService` en `VehicleRepositoryImpl`

En `lib/features/vehicles/data/repository/vehicle_repository_impl.dart`:

1. Agregar `ImageStorageService` al constructor (junto a `VehicleService`). Si Sub-tarea A se ejecuta, remover `FirebaseStorage` del constructor y migrar `uploadVehicleImage` a `ImageStorageService.uploadImage`. Si Sub-tarea A se difiere, mantener `FirebaseStorage` para el upload pero agregar `ImageStorageService` al constructor.
2. El repositorio NO llama `deleteByUrl` directamente en esta fase — el borrado ocurre en los cubits (pasos 3 y 4). `ImageStorageService` queda disponible para Sub-tarea A futura o para que el repositorio lo use si el diseño evoluciona.
3. Agregar el comentario `// TODO(debt)` en `_vehicleRequest` (ver Paso 6).

> **Nota sobre build_runner:** agregar `ImageStorageService` al constructor del repositorio **no** requiere regen de freezed (el repositorio no tiene partes generadas por freezed). Sí requiere que DI resuelva correctamente, pero `ImageStorageService` ya es `@injectable`, por lo que el graph de GetIt se genera sin cambios manuales. Correr `dart run build_runner build --delete-conflicting-outputs` al final de la fase para refrescar el archivo `injection.config.dart`.

### Paso 3 — Borrado en reemplazo de imagen (`VehicleFormCubit`)

`VehicleFormCubit` **ya inyecta `_imageStorageService`** (línea 26 del archivo actual). No es necesario modificar el constructor ni agregar ninguna dependencia nueva.

Modificar `_saveExistingVehicle` para capturar `oldImageUrl` y retornarla junto al resultado, y modificar `saveVehicle` para ejecutar el borrado fire-and-forget DESPUÉS de emitir `ResultState.data`:

**En `_saveExistingVehicle`:** capturar `oldImageUrl` antes de cualquier operación asincrónica y retornar un record con el resultado y la URL vieja:

```dart
// Dentro de _saveExistingVehicle — retorna (result, oldImageUrl) o ajustar
// según el patrón que prefiera el implementador para pasar oldImageUrl a saveVehicle.
// La forma más limpia es capturar oldImageUrl en saveVehicle antes de llamar
// a _saveExistingVehicle, ya que state.vehicle está disponible en ambos:
```

**Implementación preferida — capturar en `saveVehicle` antes de delegar:**

```dart
Future<void> saveVehicle(VehicleModel vehicle, {String? localImagePath}) async {
  emit(state.copyWith(vehicleResult: const ResultState.loading()));

  // Capturar oldImageUrl ANTES del update (state.vehicle puede cambiar tras emit)
  final oldImageUrl = state.isEditing ? state.vehicle?.imageUrl : null;

  final result = state.isEditing
      ? await _saveExistingVehicle(vehicle, localImagePath: localImagePath)
      : await _createNewVehicle(vehicle, localImagePath: localImagePath);

  result.fold(
    (error) => emit(state.copyWith(vehicleResult: ResultState.error(error: error))),
    (savedVehicle) {
      final eventName = state.isEditing
          ? AnalyticsEvents.vehicleUpdated
          : AnalyticsEvents.vehicleAdded;
      _analytics.logEvent(eventName, {
        AnalyticsParams.hadPhoto: savedVehicle.imageUrl != null ? 1 : 0,
      }).ignore();

      // Emitir ResultState.data PRIMERO — la UI no espera el borrado de Storage
      emit(state.copyWith(vehicleResult: ResultState.data(data: savedVehicle)));

      // Borrado fire-and-forget DESPUÉS de emitir data
      // Solo borrar si: (1) hay URL anterior, (2) la imagen cambió
      final newImageUrl = savedVehicle.imageUrl;
      if (oldImageUrl != null && oldImageUrl != newImageUrl) {
        _imageStorageService.deleteByUrl(oldImageUrl).ignore();
      }
    },
  );
}
```

`_saveExistingVehicle` no cambia su estructura interna más allá de los cambios necesarios para el upload (Sub-tarea A).

**Reglas de implementación:**
- `oldImageUrl` se captura en `saveVehicle` ANTES de cualquier operación asincrónica.
- `emit(ResultState.data(...))` va ANTES de `deleteByUrl` — el borrado es siempre fire-and-forget (`.ignore()`).
- No borrar si `oldImageUrl == newImageUrl` (el usuario no cambió la imagen).
- No borrar si `oldImageUrl == null` (el vehículo no tenía imagen previa).
- No borrar si el resultado es `Left` (error en el backend).

### Paso 4 — Borrado en eliminación permanente (`VehicleActionCubit`)

En `lib/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart`:

1. Agregar `ImageStorageService` al constructor.
2. Cambiar la firma de `permanentlyDeleteVehicle(String vehicleId)` a `permanentlyDeleteVehicle(VehicleModel vehicle)`.
3. El guard anti doble-tap `if (state is _Loading) return` se preserva — no se elimina.
4. En el bloque de éxito del fold, emitir `permanentDeleteSuccess` ANTES de `deleteByUrl`:

```dart
Future<void> permanentlyDeleteVehicle(VehicleModel vehicle) async {
  if (state is _Loading) return;  // guard anti doble-tap — se preserva

  emit(const VehicleActionState.loading());

  final result = await _permanentlyDeleteVehicleUseCase(vehicle.id!);

  result.fold(
    (error) => emit(VehicleActionState.error(message: error.message)),
    (_) {
      _analytics.logEvent(AnalyticsEvents.vehicleDeleted).ignore();
      // Emitir success PRIMERO — la UI no espera el borrado de Storage
      emit(VehicleActionState.permanentDeleteSuccess(deletedId: vehicle.id!));
      // Fire-and-forget: borrar imagen post-delete exitoso
      if (vehicle.imageUrl != null) {
        _imageStorageService.deleteByUrl(vehicle.imageUrl).ignore();
      }
    },
  );
}
```

### Paso 5 — Actualizar call sites de `permanentlyDeleteVehicle`

El cambio de firma tiene **múltiples call sites** — actualizar todos:

**Call site de producción:**

`lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart`:

```dart
// Antes:
actionCubit.permanentlyDeleteVehicle(vehicle.id!);

// Después:
actionCubit.permanentlyDeleteVehicle(vehicle);
```

El `vehicle` completo ya está disponible en el contexto del bottom sheet (se pasa como parámetro al widget).

**Call sites en tests (también deben actualizarse en Paso 8):**

- `test/features/vehicles/presentation/delete/vehicle_permanent_delete_dialog_test.dart` líneas 203–204: `permanentlyDeleteVehicle(_archivedVehicle.id!)` → `permanentlyDeleteVehicle(_archivedVehicle)`.
- `test/features/vehicles/presentation/delete/vehicle_permanent_delete_flow_test.dart`: todas las invocaciones directas de `permanentlyDeleteVehicle(_archivedVehicle.id!)` → `permanentlyDeleteVehicle(_archivedVehicle)`.

### Paso 6 — Anotar deuda en `_vehicleRequest`

En `VehicleRepositoryImpl._vehicleRequest`, agregar al inicio del método:

```dart
// TODO(debt): este Map<String, dynamic> manual viola el estándar DTO.toJson()
// del proyecto. Migrar a VehicleDto.toJson() en un cleanup posterior.
// Ver plan storage-hygiene.
Map<String, dynamic> _vehicleRequest(VehicleModel vehicle) {
```

### Paso 7 — Correr build_runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Qué requiere regeneración y qué no:**

- El cambio de firma del método `permanentlyDeleteVehicle` en `VehicleActionCubit` **no** requiere regen — los métodos de cubit no son parte del código generado por freezed. `vehicle_action_cubit.freezed.dart` solo refleja el estado (`VehicleActionState`), no los métodos del cubit.
- Agregar `ImageStorageService` al constructor de `VehicleActionCubit` **sí** requiere regen del archivo `injection.config.dart` (el graph de DI de GetIt/Injectable). Esto se resuelve con el `build_runner build` mencionado.
- `VehicleFormCubit` **ya tiene `ImageStorageService` inyectado** en su constructor (línea 26) — no se agrega nada nuevo al constructor de `VehicleFormCubit`. No hay regen adicional por este cambio.

### Paso 8 — Escribir y actualizar tests

Ver sección "Pruebas" para los archivos y casos concretos. Los **cuatro** archivos de test existentes que instancian `VehicleActionCubit` directamente y que romperán la compilación al agregar el 6to parámetro son:

1. `test/features/vehicles/presentation/delete/vehicle_permanent_delete_dialog_test.dart`
2. `test/features/vehicles/presentation/delete/vehicle_permanent_delete_flow_test.dart`
3. `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart`
4. `test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart`

Todos deben recibir `MockImageStorageService` como 6to argumento del constructor y el stub `when(() => mockImageStorageService.deleteByUrl(any())).thenAnswer((_) async {})` en su `setUp`. No omitir los archivos de garage — aunque no verifican borrado de Storage, el constructor ampliado no compila sin el parámetro adicional.

### Paso 9 — Validar

```bash
dart analyze
flutter test test/features/vehicles/
```

Sin errores nuevos de lint ni regresiones.

---

## Archivos a crear/modificar (rutas reales)

| Ruta | Acción | Qué cambia |
|------|--------|------------|
| `lib/features/vehicles/data/repository/vehicle_repository_impl.dart` | Modificar | Agregar `ImageStorageService` al constructor; si Sub-tarea A se ejecuta, reemplazar `FirebaseStorage` y migrar `uploadVehicleImage`; si no, mantener ambos; agregar `TODO(debt)` en `_vehicleRequest`. |
| `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart` | Modificar | `saveVehicle`: capturar `oldImageUrl` antes del update; llamar `deleteByUrl(oldImageUrl)` fire-and-forget DESPUÉS de `emit(ResultState.data(...))` cuando la imagen cambia. Constructor sin cambios (`_imageStorageService` ya existe). |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart` | Modificar | Agregar `ImageStorageService` al constructor; cambiar firma de `permanentlyDeleteVehicle` de `String vehicleId` a `VehicleModel vehicle`; emitir `permanentDeleteSuccess` ANTES de llamar `deleteByUrl` fire-and-forget. Guard anti doble-tap se preserva. |
| `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` | Modificar | Pasar `vehicle` en lugar de `vehicle.id!` a `permanentlyDeleteVehicle`. |
| `test/features/vehicles/presentation/cubit/vehicle_form_cubit_image_cleanup_test.dart` | Crear | Tests unitarios de `VehicleFormCubit.saveVehicle` para el flujo de borrado de imagen anterior: `verifyInOrder`, fire-and-forget, casos de skip. |
| `test/features/vehicles/presentation/delete/vehicle_action_cubit_storage_test.dart` | Crear | Tests unitarios de `VehicleActionCubit.permanentlyDeleteVehicle` con la firma nueva: `verifyInOrder`, fire-and-forget, guard doble-tap con `VehicleModel`. |
| `test/features/vehicles/presentation/delete/vehicle_permanent_delete_dialog_test.dart` | Modificar | Actualizar líneas 203–204: `permanentlyDeleteVehicle(_archivedVehicle.id!)` → `permanentlyDeleteVehicle(_archivedVehicle)`. Agregar `MockImageStorageService` como 6to parámetro al ctor en `setUp` (~línea 121) y al ctor en línea de TC-perm-B (~líneas 194–200). Stub `deleteByUrl` en setUp. |
| `test/features/vehicles/presentation/delete/vehicle_permanent_delete_flow_test.dart` | Modificar | Actualizar todas las invocaciones directas de `permanentlyDeleteVehicle(_archivedVehicle.id!)` → `permanentlyDeleteVehicle(_archivedVehicle)`. Agregar `MockImageStorageService` como 6to parámetro al ctor en `_setUp` (~línea 127) y al ctor en línea de TC-7B-2 (~líneas 304–309). Stub `deleteByUrl` en `_setUp`. |
| `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart` | Modificar | Agregar `MockImageStorageService` como 6to parámetro al ctor de `VehicleActionCubit` en `setUp` (~línea 129). Stub `deleteByUrl` en setUp. Sin cambio de call sites de `permanentlyDeleteVehicle` (este archivo no lo invoca directamente). |
| `test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart` | Modificar | Agregar `MockImageStorageService` como 6to parámetro al ctor de `VehicleActionCubit` en `setUp` (~línea 138). Stub `deleteByUrl` en setUp. Sin cambio de call sites de `permanentlyDeleteVehicle` (este archivo no lo invoca directamente). |

> **No se crea** `test/features/vehicles/data/repository/vehicle_repository_impl_storage_test.dart`. En esta fase el repositorio solo recibe `ImageStorageService` por DI pero no lo invoca para el borrado (el borrado ocurre en los cubits). La corrección del constructor queda cubierta por la compilación de los tests existentes del repositorio y por el build_runner. No tiene sentido crear un test cuyo único criterio observable sea "compila".

---

## Contratos / API rideglory-api

**Ninguno.** El backend persiste `imageUrl` como string en la BD pero no gestiona el ciclo de vida del archivo en Firebase Storage. Los endpoints `PATCH /vehicles/{id}` y `DELETE /my-vehicles/{id}` no cambian. No se requieren cambios en `rideglory-api`.

---

## Cambios de datos / migraciones

**Ninguno.** No hay cambios de esquema en base de datos ni en Firebase Storage rules. Los archivos preexistentes en Storage no se tocan.

---

## Criterios de aceptacion

1. **CA-1 (reemplazo de imagen):** Al guardar un vehículo en modo edición con una nueva imagen local seleccionada, el archivo anterior en Storage se borra. Verificable via `verify(() => imageStorageService.deleteByUrl(oldUrl)).called(1)` en tests unitarios.

2. **CA-2 (eliminación permanente + guard doble-tap):** Al confirmar la eliminación permanente de un vehículo, `deleteByUrl(vehicle.imageUrl)` es llamado exactamente una vez después del delete exitoso al backend. La segunda llamada concurrente en estado `_Loading` es ignorada por el guard. Los tests que verifican el guard pasan `VehicleModel` (no `vehicle.id!`) y construyen el fixture con `id` no-nulo para que `vehicle.id!` no lance en el bloque de éxito. Verificable via `verifyInOrder([() => deleteUseCase(vehicle.id!), () => imageStorageService.deleteByUrl(vehicle.imageUrl)])`.

3. **CA-3 (orden y no-bloqueo — reemplazo):** `ResultState.data` es emitido ANTES de que `deleteByUrl` sea llamado en el flujo de reemplazo. El borrado no bloquea la UI. **Mecanismo de verificación observable:** en T-FC-3, `deleteByUrl` se mockea con un `Completer` que no se completa durante el test. Se verifica que el estado del cubit ya es `ResultState.data(...)` mientras `deleteByUrl` sigue pendiente (el `Completer` no se ha completado). Esto garantiza que el emit no espera al borrado.

4. **CA-4 (orden y no-bloqueo — delete):** `VehicleActionState.permanentDeleteSuccess` es emitido ANTES de que `deleteByUrl` sea llamado. El borrado no bloquea la UI. Verificable con el mismo patrón de `Completer` en T-AC-3.

5. **CA-5 (sin borrado en archivo):** Archivar un vehículo (`archiveVehicle(vehicle)`) no llama `deleteByUrl`. Verificable con `verifyNever(() => imageStorageService.deleteByUrl(any()))` en test de archivado existente o nuevo.

6. **CA-6 (sin borrado si imagen no cambia):** Al actualizar un vehículo sin seleccionar nueva imagen (`localImagePath == null`), `oldImageUrl == newImageUrl` y `deleteByUrl` no es llamado. El guard `if (oldImageUrl != null && oldImageUrl != newImageUrl)` previene el borrado.

7. **CA-7 (sin borrado si imageUrl es null):** Si el vehículo no tenía imagen previa (`imageUrl == null`) y se añade una nueva, `deleteByUrl` no es llamado (el guard `if (oldImageUrl != null ...)` lo previene). `ImageStorageService.deleteByUrl(null)` maneja null idempotentemente (Fase 1), pero el cubit no lo llama con null innecesariamente.

8. **CA-8 (firma actualizada y compilación):** `VehicleActionCubit.permanentlyDeleteVehicle` acepta `VehicleModel` como parámetro. El call site en `GarageOptionsBottomSheet` compila con `vehicle`. Los tests en `vehicle_permanent_delete_dialog_test.dart` y `vehicle_permanent_delete_flow_test.dart` pasan `_archivedVehicle` (tipo `VehicleModel` con `id` no-nulo) en lugar de `_archivedVehicle.id!`. El use case `PermanentlyDeleteVehicleUseCase.call(String vehicleId)` **no cambia de firma** — el cubit extrae el ID con `vehicle.id!`.

9. **CA-9 (deuda anotada):** `VehicleRepositoryImpl._vehicleRequest` tiene el comentario `// TODO(debt)` visible en el código fuente.

10. **CA-10 (sin regresión):** `flutter test test/features/vehicles/` pasa sin errores. `dart analyze` no introduce lint violations nuevas.

---

## Pruebas

### Nuevo: `test/features/vehicles/presentation/cubit/vehicle_form_cubit_image_cleanup_test.dart`

Tests unitarios de `VehicleFormCubit.saveVehicle` para el flujo de borrado de imagen anterior. `VehicleFormCubit` ya tiene `_imageStorageService` inyectado — solo se necesita un mock de `ImageStorageService` en el setup del test.

| ID | Caso | Tipo |
|----|------|------|
| T-FC-1 | Edición con nueva imagen → `deleteByUrl(oldUrl)` llamado tras update exitoso | Unitario |
| T-FC-2 | `verifyInOrder([updateVehicleUseCase.call(any()), imageStorageService.deleteByUrl(oldUrl)])` — backend primero, Storage después | Unitario |
| T-FC-3 | `ResultState.data` emitido antes de que `deleteByUrl` complete: mockear `deleteByUrl` con un `Completer` que no se completa → verificar que `cubit.state` ya es `ResultState.data(...)` mientras el `Completer` sigue abierto | Unitario |
| T-FC-4 | Edición sin nueva imagen (`localImagePath == null`) → `deleteByUrl` NO llamado (`verifyNever`) | Unitario |
| T-FC-5 | Update al backend falla (Left) → `deleteByUrl` NO llamado | Unitario |
| T-FC-6 | Vehículo sin imagen previa (`imageUrl == null`) + nueva imagen → `deleteByUrl` NO llamado | Unitario |

Patrón de setup:

> **Nota de imports:** el helper vive bajo `test/helpers/storage_mocks.dart`. El package de la app es `rideglory` (no existe `rideglory_test`), por lo que el import debe ser **relativo** según la profundidad de cada archivo de test:
> - `test/features/vehicles/presentation/cubit/` → `import '../../../../helpers/storage_mocks.dart';` (4 niveles)
> - `test/features/vehicles/presentation/delete/` → `import '../../../../helpers/storage_mocks.dart';` (4 niveles)
> - `test/features/vehicles/presentation/garage/widgets/` → `import '../../../../../helpers/storage_mocks.dart';` (5 niveles)

```dart
// Ejemplo para archivos en test/features/vehicles/presentation/cubit/ (4 niveles):
import '../../../../helpers/storage_mocks.dart';
// Ejemplo para archivos en test/features/vehicles/presentation/garage/widgets/ (5 niveles):
// import '../../../../../helpers/storage_mocks.dart';

class MockImageStorageService extends Mock implements ImageStorageService {}
class MockUpdateVehicleUseCase extends Mock implements UpdateVehicleUseCase {}

// En T-FC-3 (verificar fire-and-forget):
final completer = Completer<void>();
when(() => mockImageStorageService.deleteByUrl(any()))
    .thenAnswer((_) => completer.future);

// ... guardar vehículo ...

// Verificar que el cubit ya emitió data ANTES de que el Completer complete
expect(
  cubit.state.vehicleResult,
  isA<Data<VehicleModel>>(),
  reason: 'ResultState.data debe estar emitido mientras deleteByUrl sigue pendiente',
);
// No completar el Completer — el test valida el estado intermedio
```

### Nuevo: `test/features/vehicles/presentation/delete/vehicle_action_cubit_storage_test.dart`

Tests unitarios de `VehicleActionCubit.permanentlyDeleteVehicle` con la firma nueva. Incluye `MockImageStorageService` en el constructor del cubit.

| ID | Caso | Tipo |
|----|------|------|
| T-AC-1 | Delete exitoso → `deleteByUrl(vehicle.imageUrl)` llamado post-delete | Unitario |
| T-AC-2 | `verifyInOrder([() => permanentlyDeleteUseCase(vehicle.id!), () => imageStorageService.deleteByUrl(vehicle.imageUrl)])` | Unitario |
| T-AC-3 | `permanentDeleteSuccess` emitido antes de que `deleteByUrl` complete: mockear `deleteByUrl` con `Completer` que no completa → verificar que `cubit.state` ya es `permanentDeleteSuccess` mientras el `Completer` sigue abierto | Unitario |
| T-AC-4 | Delete exitoso + vehículo sin imagen (`imageUrl == null`) → `deleteByUrl` NO llamado (`verifyNever`) | Unitario |
| T-AC-5 | Delete falla (Left) → `deleteByUrl` NO llamado, emite `error` state | Unitario |
| T-AC-6 | Guard anti doble-tap: segunda llamada concurrente en estado `_Loading` no llama al use case ni a `deleteByUrl`. El fixture `vehicle` es un `VehicleModel` con `id` no-nulo (ej. `id: 'v-test-1'`) para que `vehicle.id!` no lance. La primera llamada usa un `Completer` pendiente para mantener el cubit en `_Loading`. | Unitario |

Setup del cubit en estos tests:

```dart
final cubit = VehicleActionCubit(
  mockPermanentlyDeleteUseCase,
  mockArchiveUseCase,
  mockUnarchiveUseCase,
  mockVehicleCubit,
  mockAnalytics,
  mockImageStorageService,  // nuevo parámetro
);
```

### Modificar: `test/features/vehicles/presentation/delete/vehicle_permanent_delete_dialog_test.dart`

1. En el `setUp` (líneas ~120–128), agregar `MockImageStorageService` al factory de `VehicleActionCubit`:

```dart
gi.registerFactory<VehicleActionCubit>(
  () => VehicleActionCubit(
    deleteUseCase,
    archiveUseCase,
    unarchiveUseCase,
    vehicleCubit,
    analytics,
    mockImageStorageService,  // agregar
  ),
);
```

2. Actualizar líneas 203–204 (TC-perm-B): `permanentlyDeleteVehicle(_archivedVehicle.id!)` → `permanentlyDeleteVehicle(_archivedVehicle)`. El fixture `_archivedVehicle` ya tiene `id: 'v-arch'` (no-nulo), por lo que `vehicle.id!` en el cubit no lanza.

3. Los tests TC-perm-A, TC-perm-B y TC-perm-C no verifican borrado de Storage — solo agregar el mock al constructor y el stub `when(() => mockImageStorageService.deleteByUrl(any())).thenAnswer((_) async {})` en el setUp.

### Modificar: `test/features/vehicles/presentation/delete/vehicle_permanent_delete_flow_test.dart`

1. Agregar `MockImageStorageService` como 6to parámetro al ctor de `VehicleActionCubit` en `_setUp` (líneas ~124–134) y en el ctor en línea del test TC-7B-2 (~líneas 304–309).
2. Actualizar todas las invocaciones directas de `permanentlyDeleteVehicle(_archivedVehicle.id!)` → `permanentlyDeleteVehicle(_archivedVehicle)`. El fixture ya tiene `id: 'v-del-flow'`.
3. Agregar stub `when(() => mockImageStorageService.deleteByUrl(any())).thenAnswer((_) async {})` en `_setUp`.
4. Import relativo: `import '../../../../helpers/storage_mocks.dart';` (4 niveles desde `test/features/vehicles/presentation/delete/`).
5. Los tests existentes (TC-3-1, TC-3-2, TC-3-4, TC-7B, TC-7B-2) no verifican Storage — siguen siendo válidos tras la actualización de firma.

### Modificar: `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart`

Este archivo instancia `VehicleActionCubit` directamente en el `setUp` (~línea 129, dentro del `GetIt.registerFactory`). Al agregar el 6to parámetro al constructor del cubit, este archivo **no compila** sin la modificación.

1. Declarar `late MockImageStorageService mockImageStorageService;` junto a los otros mocks.
2. En `setUp`, inicializar: `mockImageStorageService = MockImageStorageService();`
3. Agregar stub: `when(() => mockImageStorageService.deleteByUrl(any())).thenAnswer((_) async {});`
4. Agregar `mockImageStorageService` como 6to argumento al `VehicleActionCubit(...)` del `GetIt.registerFactory` (~línea 129).
5. Import relativo: `import '../../../../../helpers/storage_mocks.dart';` (5 niveles desde `test/features/vehicles/presentation/garage/widgets/`).
6. Los tests existentes (TC-arch-1 a TC-arch-5) no verifican Storage — la modificación es mínima.

### Modificar: `test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart`

Este archivo instancia `VehicleActionCubit` directamente en el `setUp` (~línea 138, dentro del `GetIt.registerFactory`). Al agregar el 6to parámetro al constructor del cubit, este archivo **no compila** sin la modificación.

1. Declarar `late MockImageStorageService mockImageStorageService;` junto a los otros mocks.
2. En `setUp`, inicializar: `mockImageStorageService = MockImageStorageService();`
3. Agregar stub: `when(() => mockImageStorageService.deleteByUrl(any())).thenAnswer((_) async {});`
4. Agregar `mockImageStorageService` como 6to argumento al `VehicleActionCubit(...)` del `GetIt.registerFactory` (~línea 138).
5. Import relativo: `import '../../../../../helpers/storage_mocks.dart';` (5 niveles desde `test/features/vehicles/presentation/garage/widgets/`).
6. Los tests existentes (TC-bs-1, TC-bs-2) no verifican Storage — la modificación es mínima.

---

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigacion |
|---|--------|-----------|------------|
| R1 | **Borrado prematuro:** `deleteByUrl` llamado antes de confirmar éxito del backend → imagen borrada con modelo inconsistente | Alta | `deleteByUrl` solo se llama dentro del bloque `fold` de éxito (Right), nunca antes. Verificado con `verifyInOrder` en tests T-FC-2 y T-AC-2. |
| R2 | **UI bloqueada esperando Storage:** si `deleteByUrl` es awaited antes de emitir el estado de éxito, la UI queda congelada durante el borrado | Media | Regla explícita: emitir estado de éxito (`data`/`permanentDeleteSuccess`) ANTES de llamar `deleteByUrl(...)`. El borrado es siempre fire-and-forget (`.ignore()`). CA-3 y CA-4 usan el patrón `Completer` para verificar este orden de forma observable. |
| R3 | **Regresión en tests existentes (4 archivos):** `vehicle_permanent_delete_dialog_test.dart`, `vehicle_permanent_delete_flow_test.dart`, `garage_archived_section_test.dart` y `garage_options_bottom_sheet_test.dart` instancian `VehicleActionCubit` directamente y no compilarán sin el 6to parámetro `MockImageStorageService` | Media | Actualizar los cuatro archivos en el mismo rg-exec. Agregar `MockImageStorageService` como 6to parámetro al constructor y el stub `deleteByUrl` en setUp. Actualizar también las invocaciones de `permanentlyDeleteVehicle` en los dos primeros. |
| R4 | **Borrado accidental en archivado:** si `archiveVehicle` usa un path de código que pasa por `saveVehicle`, podría activar el borrado | Baja | `archiveVehicle` usa `ArchiveVehicleUseCase`, flujo completamente separado de `VehicleFormCubit`. CA-5 verifica con `verifyNever`. |
| R5 | **Borrado si imagen no cambia:** si el usuario guarda sin cambiar imagen, `oldImageUrl == newImageUrl` y se borraría la imagen activa | Alta | La condición `if (oldImageUrl != null && oldImageUrl != newImageUrl)` previene el borrado. CA-6 verifica este caso. |
| R6 | **`vehicle.id!` lanza en tests con fixture sin id:** si el fixture de test tiene `id: null`, `vehicle.id!` en el cubit lanza | Baja | Todos los fixtures de test deben tener `id` no-nulo (ej. `id: 'v-test-1'`). Documentado en T-AC-6 y en la sección de tests de dialog/flow. |
| R7 | **build_runner en entornos frescos** | Baja | Usar `--force-jit` o copiar `pubspec.lock` de main (documentado en MEMORY.md). El código de esta fase no introduce nuevas anotaciones freezed. |

---

## Dependencias (fases prerequisito y por que)

| Prerequisito | Por qué |
|---|---|
| **Fase 1 — Storage Delete Utility** | Provee `ImageStorageService.deleteByUrl(String? url)` con los cuatro casos de manejo (null/vacía, externa, 404, error red), idempotencia y logging. Sin esta utilidad, el borrado en esta fase tendría que reimplementar la lógica de validación de bucket, lo que viola DRY y el principio de responsabilidad única. También provee `test/helpers/storage_mocks.dart` que esta fase importa directamente. |

---

## Ejecucion recomendada (nivel rg-exec: normal)

**Por qué normal:** esta fase toca dos cubits de presentación (`VehicleFormCubit`, `VehicleActionCubit`), un repositorio de datos (`VehicleRepositoryImpl`), y cambia la firma pública de `permanentlyDeleteVehicle` con cascada a múltiples call sites en producción y tests (`GarageOptionsBottomSheet`, `vehicle_permanent_delete_dialog_test.dart`, `vehicle_permanent_delete_flow_test.dart`). La lógica post-éxito tiene ramificación según el flujo (reemplazo de imagen vs. eliminación permanente vs. archivo — este último no borra). Se requiere `verifyInOrder` en tests para garantizar el orden de operaciones (backend primero, Storage después). Riesgo medio de regresión si:

- El orden de `emit(data)`/`emit(permanentDeleteSuccess)` y `deleteByUrl` se invierte, bloqueando la UI.
- La condición `oldImageUrl != newImageUrl` falla, borrando la imagen activa del vehículo.
- Los tests existentes de flujo de eliminación no se actualizan con la nueva firma y fallan silenciosamente.
- Se instancia `VehicleActionCubit` en tests sin el nuevo parámetro `ImageStorageService`.

El nivel `lite` no es suficiente por la ramificación de lógica, el cambio de firma pública con cascada a múltiples call sites y la necesidad de actualizar tests existentes. El nivel `full` no es necesario porque no hay cambios de contratos de API, no hay UI nueva y el blast radius está acotado al feature `vehicles`.
