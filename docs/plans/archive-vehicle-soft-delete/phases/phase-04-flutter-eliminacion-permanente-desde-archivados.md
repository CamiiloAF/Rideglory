# Fase 4 — Flutter: eliminación permanente desde archivados

_Generated: 2026-06-16T16:38:33Z_
_Plan: archive-vehicle-soft-delete_
_Nivel de ejecución recomendado: normal_
_Revision: Correcciones Auditor Opus aplicadas (2026-06-16) — v2_

---

## Objetivo

El usuario puede eliminar definitivamente un vehículo **archivado** directamente desde el menú contextual del garaje. La acción requiere confirmación explícita con tono destructivo, muestra el nombre del vehículo, describe la irreversibilidad, y está protegida contra doble-tap mediante un guard en el cubit. Tras la eliminación exitosa, `VehicleCubit` hace un re-fetch completo de la lista; el vehículo desaparece de la sección "Archivados" en la misma sesión sin navegación adicional.

---

## Alcance (entra / no entra)

### Entra

- Renombrar `VehicleRepository.deleteVehicle` → `permanentlyDeleteVehicle` en la interfaz de dominio, la implementación del repositorio, el use case `DeleteVehicleUseCase` (renombrado a `PermanentlyDeleteVehicleUseCase`) y `VehicleDeleteCubit` (método `deleteVehicle` → `permanentlyDeleteVehicle`).
- Eliminar el parámetro `{required List<VehicleModel> availableVehicles}` de la firma del método del cubit: ya no es necesario porque el resultado se sincroniza con un re-fetch completo (`VehicleCubit.fetchMyVehicles()`), no con mutación local.
- Añadir `VehicleService.permanentlyDeleteVehicle` con `@DELETE('${ApiRoutes.myVehicles}/{id}')` apuntando al endpoint `DELETE /api/vehicles/my/:vehicleId` creado en Fase 1. Eliminar la declaración `deleteVehicle` existente (que apunta a `hard-delete`).
- Eliminar **por completo** el punto de entrada de eliminación en el flujo de edición de vehículo. Esto afecta tres widgets en cadena:
  1. `VehicleFormCta` — eliminar el parámetro `required final VoidCallback onDelete` y el bloque `if (state.isEditing) ...[ SizedBox, GestureDetector(onTap: state.isLoading ? null : onDelete, ...) ]` (líneas ~11, 15, 29-53 en el archivo actual). La clave `vehicle_form_delete_vehicle` que este widget consume deja de tener consumidores.
  2. `VehicleFormBody` — eliminar el parámetro `required this.onDelete` (línea 17/23 en el archivo actual) y la línea donde lo pasa a `VehicleFormCta` (`VehicleFormCta(onSave: onSave, onDelete: onDelete)` → `VehicleFormCta(onSave: onSave)`).
  3. `VehicleFormView` — eliminar el método `_confirmDelete` (líneas 101-122), el `BlocListener<VehicleDeleteCubit, VehicleDeleteState>` del `MultiBlocListener` (junto con el método `_deleteListener`, líneas 304-329), y el parámetro `onDelete: _confirmDelete` al construir `VehicleFormBody`.
- Eliminar el `BlocProvider<VehicleDeleteCubit>` del `MultiBlocProvider` en `VehicleFormPage` (líneas 29-31) y el import de `vehicle_delete_cubit` (línea 7), ya que tras eliminar el punto de entrada del form el cubit no tiene consumidores en ese árbol.
- Confirmar que `_deleteListener`, el único consumer que ejecutaba `context.goAndClearStack(AppRoutes.garage)` en success (línea ~316), ya no es necesario: la eliminación ahora ocurre desde el garaje y el usuario ya está en el garaje; no se requiere navegación adicional.
- Conectar la opción "Eliminar permanentemente" en `GarageOptionsBottomSheet`, visible únicamente cuando `vehicle.isArchived == true`.
- El menú final (post-Fase 3 + Fase 4) queda:
  - `if (!vehicle.isArchived)`: "Establecer como principal" (condicional por `!isMainVehicle`), "Editar", "Agregar mantenimiento", "Archivar".
  - `if (vehicle.isArchived)`: "Restaurar", "Eliminar permanentemente" (destructivo).
- Usar `ConfirmationDialog` con `confirmType: DialogActionType.danger` para el diálogo destructivo. `ConfirmationDialog` ya soporta este tipo con variante `AppModalVariant.destructive` (icono + CTA en `colorScheme.error`) — no hay trabajo de shared widgets nuevo.
- Anti doble-tap implementado en el cubit: si `permanentlyDeleteVehicle` es invocado mientras el estado ya es `VehicleDeleteState.loading()`, retorna inmediatamente sin emitir ni llamar al use case.
- Tras `VehicleDeleteState.success`: `VehicleCubit.fetchMyVehicles()` (re-fetch completo) para sincronizar lista y estado de main con el backend.
- Migrar el snackbar de éxito en `GarageOptionsBottomSheet` de `vehicle_vehicleDeleted` → `vehicle_permanentDeleteSuccess`.
- Añadir claves nuevas en `lib/l10n/app_es.arb` y regenerar localización.
- Widget tests para el diálogo destructivo y el guard anti doble-tap en el cubit.
- Pre-flight grep obligatorio (ver Paso 0).

### No entra

- Eliminar vehículos activos (no archivados) — la opción no aparece en el menú de activos ni en el form.
- Cambios en el backend (cubre Fase 1).
- Diseño de nuevos frames en Pencil (cubre Fase 2).
- Lógica de archivar / restaurar (cubre Fase 3).
- Eliminación del alias `hard-delete/:id` en el gateway — coordinación de despliegue de Fase 1.
- Cambios en `HomeGarageSection` ni en `HomeCubit` (cubre Fase 5).
- Deprecación formal de `vehicle_vehicleDeleted`, `vehicle_deleteVehicle` o `vehicle_form_delete_vehicle` en el ARB — solo documentar que quedan sin consumidores.
- Nuevas dependencias de `pubspec.yaml`.

---

## Que se debe hacer (pasos concretos y ordenados)

### Paso 0: Gate de entrada + pre-flight

**Obligatorio antes de cualquier código.**

1. Verificar que el endpoint `DELETE /api/vehicles/my/:vehicleId` (Fase 1) está disponible y respondiendo correctamente en el entorno de prueba. Hacer una llamada manual con `curl` o Postman con un token válido y confirmar respuesta 200. Si el endpoint no está disponible, detener la fase hasta que Fase 1 esté desplegada.

2. Ejecutar el siguiente grep y enumerar todos los hits antes de proceder:
   ```bash
   grep -rn 'deleteVehicle\|DeleteVehicleUseCase\|availableVehicles' lib/ \
     --include='*.dart' | grep -v '\.g\.dart\|\.freezed\.dart'
   ```
   Los archivos con hits de `deleteVehicle` / `DeleteVehicleUseCase` son exactamente los que esta fase modifica. Si aparece un archivo no listado en la tabla de archivos, investigar antes de continuar.

   Hits esperados de `deleteVehicle` / `DeleteVehicleUseCase` (confirmados en scan):
   - `lib/features/vehicles/domain/repository/vehicle_repository.dart`
   - `lib/features/vehicles/domain/usecases/delete_vehicle_usecase.dart`
   - `lib/features/vehicles/data/repository/vehicle_repository_impl.dart`
   - `lib/features/vehicles/data/service/vehicle_service.dart`
   - `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart`
   - `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart`
   - `lib/features/vehicles/presentation/form/widgets/vehicle_form_view.dart`
   - `lib/core/di/injection.config.dart` (auto-generado — se actualiza solo con `build_runner`)

   Los hits de `availableVehicles` en `event_registration`, `maintenance` y `vehicle_selector` son del getter `VehicleCubit.availableVehicles`, no del cubit de eliminación. No tocar esos archivos.

### Paso 1: l10n — añadir claves nuevas

3. Abrir `lib/l10n/app_es.arb` y añadir las cinco claves nuevas (ver sección "Claves l10n"). La clave `vehicle_permanentDeleteMessage` tiene el placeholder `{vehicleName}` con su bloque `@` correspondiente.
4. Ejecutar `flutter gen-l10n` para regenerar `lib/l10n/app_localizations_es.dart` y `app_localizations.dart`.

### Paso 2: Dominio — renombrar interfaz y use case

5. En `lib/features/vehicles/domain/repository/vehicle_repository.dart`: renombrar el método `deleteVehicle(String id)` → `permanentlyDeleteVehicle(String id)`. La firma `Future<Either<DomainException, void>>` no cambia.

6. Renombrar el archivo `lib/features/vehicles/domain/usecases/delete_vehicle_usecase.dart` → `permanently_delete_vehicle_usecase.dart` y actualizar la clase `DeleteVehicleUseCase` → `PermanentlyDeleteVehicleUseCase`. El método `call` pasa a delegar en `_vehicleRepository.permanentlyDeleteVehicle(vehicleId)`. La anotación `@injectable` se mantiene.

### Paso 3: Data — repositorio e implementación Retrofit

7. En `lib/features/vehicles/data/repository/vehicle_repository_impl.dart`: renombrar `deleteVehicle` → `permanentlyDeleteVehicle` (método `@override`). El cuerpo llama a `_vehicleService.permanentlyDeleteVehicle(id)`.

8. En `lib/features/vehicles/data/service/vehicle_service.dart`: reemplazar la declaración `deleteVehicle` (que apuntaba a `@DELETE('${ApiRoutes.vehicles}/hard-delete/{id}')`) por:
   ```dart
   @DELETE('${ApiRoutes.myVehicles}/{id}')
   Future<void> permanentlyDeleteVehicle(@Path('id') String id);
   ```
   `ApiRoutes.myVehicles` vale `'/vehicles/my'` (confirmado en `lib/core/http/api_routes.dart`), por lo que la ruta resuelve a `DELETE /vehicles/my/{id}`, que el gateway enruta a `DELETE /api/vehicles/my/:vehicleId`. No se necesita añadir ninguna constante a `ApiRoutes`.

9. Ejecutar `dart run build_runner build --delete-conflicting-outputs` para regenerar `vehicle_service.g.dart` e `injection.config.dart`.

### Paso 4: Presentation — VehicleDeleteCubit

10. En `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart`:
    - Reemplazar la dependencia `DeleteVehicleUseCase` → `PermanentlyDeleteVehicleUseCase`.
    - Renombrar el método público `deleteVehicle` → `permanentlyDeleteVehicle`.
    - **Eliminar el parámetro `{required List<VehicleModel> availableVehicles}`** de la firma. La nueva firma queda:
      ```dart
      Future<void> permanentlyDeleteVehicle(String vehicleId) async { ... }
      ```
    - Añadir guard anti doble-tap al inicio del método (antes de `emit(loading)`):
      ```dart
      if (state == const VehicleDeleteState.loading()) return;
      ```
    - En el body del `Right(_)` branch: reemplazar `_vehicleCubit.deleteVehicleLocally(vehicleId)` → `await _vehicleCubit.fetchMyVehicles()`. El re-fetch completo sincroniza lista y estado de main con el backend.
    - Mantener el analytics event `AnalyticsEvents.vehicleDeleted` sin cambios.

11. `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_state.dart` **es un archivo separado** con `part of 'vehicle_delete_cubit.dart'`. Los estados existentes (`initial`, `loading`, `success`, `error`, `errorLastVehicle`) cubren el flujo — no se añaden estados nuevos ni se modifica este archivo.

12. Ejecutar `dart run build_runner build --delete-conflicting-outputs` para regenerar `vehicle_delete_cubit.freezed.dart` e `injection.config.dart` (el DI ahora registra `PermanentlyDeleteVehicleUseCase` en lugar de `DeleteVehicleUseCase`).

### Paso 5: UI — GarageOptionsBottomSheet

13. En `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart`:

    **Estado post-Fase 3 asumido:** Fase 3 habrá añadido tiles "Archivar" (activos) / "Restaurar" (archivados) como `ListTile` condicionales. El tile "Eliminar vehículo" sin condición del código actual todavía estará presente (Fase 3 no lo toca). Fase 4 lo convierte en el tile destructivo condicional para archivados.

    **Bifurcación final exacta del menú:**
    ```
    if (!vehicle.isArchived):
      ListTile "Establecer como principal"   ← condicional por !isMainVehicle — sin cambio
      ListTile "Editar"                      ← añadir condición !isArchived si Fase 3 no lo hizo
      ListTile "Agregar mantenimiento"       ← añadir condición !isArchived si Fase 3 no lo hizo
      ListTile "Archivar"                    ← añadido en Fase 3

    if (vehicle.isArchived):
      ListTile "Restaurar"                   ← añadido en Fase 3
      ListTile "Eliminar permanentemente"    ← ESTA FASE (reemplaza al tile sin condición)
    ```

    **Cambios concretos:**
    - Localizar el `ListTile` de "Eliminar vehículo" existente (actualmente sin condición, línea ~162 en el código actual).
    - Reemplazarlo completamente por un nuevo `ListTile` envuelto en `if (vehicle.isArchived)`:
      - `leading`: `Icon(Icons.delete_forever, color: context.colorScheme.error)`
      - `title`: texto `context.l10n.vehicle_permanentDeleteTitle` en `colorScheme.error`
      - `onTap`: cerrar el sheet con `context.pop()`, luego:
        ```dart
        final confirm = await ConfirmationDialog.show(
          context: parentContext,
          title: parentContext.l10n.vehicle_permanentDeleteTitle,
          content: parentContext.l10n.vehicle_permanentDeleteMessage(vehicle.name),
          confirmLabel: parentContext.l10n.vehicle_permanentDeleteAction,
          cancelLabel: parentContext.l10n.cancel,
          confirmType: DialogActionType.danger,
          isDismissible: true,
        );
        if (confirm != true || !parentContext.mounted) return;
        deleteCubit.permanentlyDeleteVehicle(vehicle.id!);
        ```
        Nota: la nueva firma de `permanentlyDeleteVehicle` **no acepta `availableVehicles`**.
    - Envolver los tiles "Editar" y "Agregar mantenimiento" en `if (!vehicle.isArchived)` si Fase 3 no lo hizo. Verificar primero para no duplicar la condición.
    - En el `BlocListener<VehicleDeleteCubit, VehicleDeleteState>` (líneas 50-71 en el código actual), en el case `success`: cambiar `parentContext.l10n.vehicle_vehicleDeleted` → `parentContext.l10n.vehicle_permanentDeleteSuccess`.

### Paso 6: UI — Eliminar punto de entrada de eliminación del form (cadena de 4 archivos)

El form de edición no debe tener botón de eliminar. La decisión PO es que la eliminación permanente es exclusiva para archivados y se inicia desde el garaje. Adicionalmente, `_deleteListener` ejecutaba `context.goAndClearStack(AppRoutes.garage)` en success — esa navegación ya no es necesaria porque la eliminación ahora ocurre desde el garaje y el usuario ya está en esa pantalla.

La cadena exacta de eliminación de `onDelete` a través de los archivos, en orden de ejecución:

**14a. `lib/features/vehicles/presentation/form/widgets/vehicle_form_cta.dart`**

- Eliminar el parámetro `required final VoidCallback onDelete` del constructor y del campo de instancia (líneas ~11 y ~15 en el archivo actual).
- Eliminar el bloque `if (state.isEditing) ...[ const SizedBox(height: 16), GestureDetector(onTap: state.isLoading ? null : onDelete, child: Row(...) ...) ]` completo (líneas ~29-53). La clave `vehicle_form_delete_vehicle` (ARB línea 643) deja de tener consumidores tras este cambio.
- Sin este cambio, la compilación falla porque `VehicleFormBody` seguirá pasando `onDelete` y `VehicleFormCta` lo declarará como `required` — hay que modificar ambos.

**14b. `lib/features/vehicles/presentation/form/vehicle_form_body.dart`**

- Eliminar el parámetro `required this.onDelete` (línea 17 en la declaración del constructor, línea 23 en el campo de instancia del archivo actual).
- Cambiar la línea que instancia `VehicleFormCta`:
  ```dart
  // Antes (línea 54):
  VehicleFormCta(onSave: onSave, onDelete: onDelete),
  // Después:
  VehicleFormCta(onSave: onSave),
  ```

**14c. `lib/features/vehicles/presentation/form/widgets/vehicle_form_view.dart`**

- Eliminar el método `_confirmDelete` (líneas 101-122 en el archivo actual).
- Eliminar el método `_deleteListener` (líneas 304-329 en el archivo actual). Recordar que este listener ejecutaba `context.goAndClearStack(AppRoutes.garage)` en el case `success` — esa navegación ya no aplica porque la eliminación ocurre desde el garaje, no desde el formulario.
- Eliminar el `BlocListener<VehicleDeleteCubit, VehicleDeleteState>` del `MultiBlocListener` (referencia al método `_deleteListener`).
- Eliminar el import de `VehicleDeleteCubit` si ya no se usa en ningún otro lugar del archivo.
- Cambiar la construcción de `VehicleFormBody`:
  ```dart
  // Antes (línea ~364):
  VehicleFormBody(
    formKey: context.read<VehicleFormCubit>().formKey,
    initialValue: _initialValues,
    onSave: _saveVehicle,
    onDelete: _confirmDelete,  // ← eliminar esta línea
  )
  // Después:
  VehicleFormBody(
    formKey: context.read<VehicleFormCubit>().formKey,
    initialValue: _initialValues,
    onSave: _saveVehicle,
  )
  ```

**14d. `lib/features/vehicles/presentation/form/vehicle_form_page.dart` (modificación CONFIRMADA)**

- Eliminar el `BlocProvider<VehicleDeleteCubit>` del `MultiBlocProvider` (líneas 29-31 en el archivo actual):
  ```dart
  // Eliminar este provider:
  BlocProvider(
    create: (context) => getIt<VehicleDeleteCubit>()..reset(),
  ),
  ```
- Eliminar el import de `vehicle_delete_cubit.dart` (línea 7 en el archivo actual).
- Justificación: tras eliminar el punto de entrada del form, el cubit no tiene consumidores en ese árbol. El cubit sigue instanciándose en `GarageOptionsBottomSheet.show` via `getIt` — el provider en el form era independiente.

### Paso 7: Verificación final

15. Ejecutar:
    ```bash
    grep -rn 'deleteVehicle\|DeleteVehicleUseCase' lib/ \
      --include='*.dart' | grep -v '\.g\.dart\|\.freezed\.dart'
    ```
    El resultado debe ser **cero hits** en código compilable.

16. Ejecutar `dart analyze` y confirmar cero errores.

17. Ejecutar `flutter test` y confirmar que todos los tests pasan en verde, incluyendo los nuevos.

---

## Archivos a crear/modificar (rutas reales)

| Archivo | Acción | Qué cambia |
|---------|--------|-----------|
| `lib/l10n/app_es.arb` | Modificar | Añadir 5 claves nuevas: `vehicle_permanentDeleteTitle`, `vehicle_permanentDeleteMessage` (placeholder `vehicleName`), `vehicle_permanentDeleteAction`, `vehicle_permanentDeleteSuccess`, `vehicle_permanentDeleteError` |
| `lib/l10n/app_localizations_es.dart` | Auto-generado | Regenerar con `flutter gen-l10n` |
| `lib/l10n/app_localizations.dart` | Auto-generado | Regenerar con `flutter gen-l10n` |
| `lib/features/vehicles/domain/repository/vehicle_repository.dart` | Modificar | Renombrar método `deleteVehicle` → `permanentlyDeleteVehicle` |
| `lib/features/vehicles/domain/usecases/delete_vehicle_usecase.dart` | Renombrar + modificar | Archivo → `permanently_delete_vehicle_usecase.dart`; clase → `PermanentlyDeleteVehicleUseCase`; delegar en `permanentlyDeleteVehicle`; eliminar parámetro `availableVehicles` |
| `lib/features/vehicles/data/repository/vehicle_repository_impl.dart` | Modificar | Renombrar `@override deleteVehicle` → `permanentlyDeleteVehicle`; llamar `_vehicleService.permanentlyDeleteVehicle` |
| `lib/features/vehicles/data/service/vehicle_service.dart` | Modificar | Reemplazar `deleteVehicle` (ruta `hard-delete`) por `permanentlyDeleteVehicle` con `@DELETE('${ApiRoutes.myVehicles}/{id}')` |
| `lib/features/vehicles/data/service/vehicle_service.g.dart` | Auto-generado | Regenerar tras modificar `vehicle_service.dart` |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart` | Modificar | Cambiar dep a `PermanentlyDeleteVehicleUseCase`; renombrar método; eliminar param `availableVehicles`; añadir guard anti doble-tap; llamar `fetchMyVehicles()` en éxito en lugar de `deleteVehicleLocally` |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_state.dart` | Sin cambios | Archivo separado con `part of 'vehicle_delete_cubit.dart'`; estados existentes cubren el flujo; no se modifica |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.freezed.dart` | Auto-generado | Regenerar con `build_runner` para sincronizar |
| `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` | Modificar | Reemplazar tile "Eliminar" sin condición por tile `if (vehicle.isArchived)` "Eliminar permanentemente"; llamar `permanentlyDeleteVehicle(id)` sin `availableVehicles`; snackbar de éxito migrado a `vehicle_permanentDeleteSuccess`; tiles "Editar"/"Agregar mantenimiento" en `if (!vehicle.isArchived)` si Fase 3 no lo hizo |
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_cta.dart` | Modificar | Eliminar parámetro `required final VoidCallback onDelete` y el bloque `if (state.isEditing) ...[ SizedBox, GestureDetector ]` completo (líneas ~11,15,29-53); la clave `vehicle_form_delete_vehicle` deja de tener consumidores |
| `lib/features/vehicles/presentation/form/vehicle_form_body.dart` | Modificar | Eliminar parámetro `required this.onDelete` (líneas 17/23); cambiar `VehicleFormCta(onSave: onSave, onDelete: onDelete)` → `VehicleFormCta(onSave: onSave)` (línea 54) |
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_view.dart` | Modificar | Eliminar `_confirmDelete` (líneas 101-122); eliminar `_deleteListener` (líneas 304-329, incluyendo el `context.goAndClearStack` ya no necesario); eliminar `BlocListener<VehicleDeleteCubit>` del `MultiBlocListener`; eliminar import de `VehicleDeleteCubit`; eliminar param `onDelete` al llamar `VehicleFormBody` |
| `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | Modificar (CONFIRMADO) | Eliminar `BlocProvider<VehicleDeleteCubit>` del `MultiBlocProvider` (líneas 29-31); eliminar import de `vehicle_delete_cubit` (línea 7); el cubit ya no tiene consumidores en este árbol |
| `lib/core/di/injection.config.dart` | Auto-generado | Regenerar con `build_runner`; registrará `PermanentlyDeleteVehicleUseCase` en lugar de `DeleteVehicleUseCase` |
| `test/features/vehicles/presentation/delete/vehicle_permanent_delete_dialog_test.dart` | Crear | Widget tests para el diálogo destructivo, el guard anti doble-tap y el flujo de cancelar |

---

## Contratos / API rideglory-api

### Endpoint consumido

```
DELETE /api/vehicles/my/{vehicleId}
Auth:    Firebase ID token (Bearer)
Params:  vehicleId (UUID, en URL)
Body:    ninguno
Success: 200 { message: 'Vehicle deleted successfully', status: 200 }
Errors:
  404 — vehicle not found
  403 — vehicle does not belong to authenticated user
  502 — falla al soft-delete de mantenimientos (maintenances-ms timeout)
```

Flutter no inspecciona el body del response (solo el status HTTP 200). Tras 200, `VehicleDeleteCubit` emite `success` y `VehicleCubit.fetchMyVehicles()` hace el re-fetch completo.

### Ruta Retrofit

```dart
@DELETE('${ApiRoutes.myVehicles}/{id}')
Future<void> permanentlyDeleteVehicle(@Path('id') String id);
```

`ApiRoutes.myVehicles` ya vale `'/vehicles/my'` (confirmado en `lib/core/http/api_routes.dart`). No se necesita añadir ninguna constante nueva.

---

## Cambios de datos / migraciones

Ninguno. El campo `isDeleted` y la migración SQL son responsabilidad de Fase 1 (backend). Flutter no accede ni serializa `isDeleted`.

---

## Criterios de aceptación

1. **Visibilidad contextual:** La opción "Eliminar permanentemente" aparece en `GarageOptionsBottomSheet` únicamente cuando `vehicle.isArchived == true`. Los vehículos activos no ven esta opción. El formulario de edición no tiene botón de eliminar.
2. **Diálogo destructivo:** El `ConfirmationDialog` usa `confirmType: DialogActionType.danger` (activa `AppModalVariant.destructive` — icono y CTA en `colorScheme.error`, texto `onError`). El título es `vehicle_permanentDeleteTitle`, el cuerpo contiene el nombre del vehículo via `vehicle_permanentDeleteMessage(vehicle.name)`, el CTA dice `vehicle_permanentDeleteAction`.
3. **Flujo de confirmación:** Al confirmar, se llama `deleteCubit.permanentlyDeleteVehicle(vehicle.id!)` sin pasar `availableVehicles`. Al cancelar, no se llama ningún método del cubit ni del repositorio.
4. **Anti doble-tap (guard en cubit):** Si `permanentlyDeleteVehicle` es invocado mientras el cubit ya está en `VehicleDeleteState.loading()`, el método retorna inmediatamente sin emitir ni llamar al use case. El Test B aserta este comportamiento directamente en el cubit: dos llamadas consecutivas → el use case se invoca exactamente una vez.
5. **Re-fetch tras éxito:** Tras recibir `VehicleDeleteState.success`, el cubit llama `await _vehicleCubit.fetchMyVehicles()` (re-fetch completo). El vehículo eliminado desaparece de la sección "Archivados" en la misma sesión.
6. **Snackbar de éxito:** Se muestra un `SnackBar` con el texto de `vehicle_permanentDeleteSuccess` y `backgroundColor: AppColors.success`. La clave `vehicle_vehicleDeleted` deja de tener consumidores tras esta fase.
7. **Snackbar de error:** Si el cubit emite `VehicleDeleteState.error`, se muestra un `SnackBar` con el mensaje de error y `backgroundColor: colorScheme.error`.
8. **Contrato Retrofit:** `VehicleService.permanentlyDeleteVehicle` apunta a `DELETE /vehicles/my/{id}`. No existe ninguna referencia a la ruta `hard-delete` en el código Flutter compilable tras esta fase.
9. **Renombrado completo:** El grep del Paso 7 devuelve cero hits de `deleteVehicle` ni `DeleteVehicleUseCase` en código compilable (excluyendo `.g.dart` y `.freezed.dart`). `dart analyze` pasa sin errores.
10. **Tests en verde:** `flutter test` pasa sin errores, incluyendo los nuevos widget tests.
11. **Strings l10n:** Ninguna string visible del usuario está hardcodeada. Todas usan `context.l10n.<clave>`.
12. **Form limpio:** `VehicleFormPage` no registra `BlocProvider<VehicleDeleteCubit>`. `VehicleFormBody` y `VehicleFormCta` no declaran `onDelete`. El form compila sin errores.

---

## Pruebas

### Widget tests (obligatorios — deben existir antes de cerrar la fase)

Archivo: `test/features/vehicles/presentation/delete/vehicle_permanent_delete_dialog_test.dart`

**Test A — nombre del vehículo visible en el diálogo:**
- Construir un `VehicleModel` archivado con `name: 'Honda CB500F'`.
- Abrir el `ConfirmationDialog` directamente (o mediante el `GarageOptionsBottomSheet` con el vehículo archivado mockeado) y verificar que el texto `'Honda CB500F'` aparece en el widget tree del diálogo de confirmación.

**Test B — guard anti doble-tap en el cubit:**
- Instanciar `VehicleDeleteCubit` con mocks (use case y `VehicleCubit` mockeados).
- Hacer que el use case no resuelva inmediatamente (completer no completado) para mantener el cubit en `loading`.
- Llamar `permanentlyDeleteVehicle('id-1')` una primera vez — el cubit emite `loading`.
- Llamar `permanentlyDeleteVehicle('id-1')` una segunda vez inmediatamente.
- Verificar con `verifyOnce` (mockito) que el use case fue invocado **exactamente una vez** — la segunda llamada fue ignorada por el guard.

**Test C — cancelar no dispara eliminación:**
- Montar el `GarageOptionsBottomSheet` con un vehículo archivado mockeado y un `VehicleDeleteCubit` mock.
- Pulsar el tile "Eliminar permanentemente" para abrir el `ConfirmationDialog`.
- Pulsar el botón "Cancelar" del diálogo.
- Verificar con `verifyNever` que `deleteCubit.permanentlyDeleteVehicle` **no fue invocado**.

### Unitarios

- Si existe un unit test para `DeleteVehicleUseCase`, renombrarlo a `PermanentlyDeleteVehicleUseCase`, actualizar la clase e importes, y verificar que el assertion del repositorio llama `permanentlyDeleteVehicle`.

### Integración / end-to-end

- Los tests de integración existentes en `integration_test/` que tocan el flujo de eliminación de vehículo deben actualizarse: la opción "Eliminar permanentemente" solo aparece en archivados; el formulario de edición ya no tiene botón de eliminar.

---

## Riesgos y mitigaciones

| # | Riesgo | Prob. | Impacto | Mitigación |
|---|--------|-------|---------|-----------|
| R-1 | **Endpoint no desplegado:** Fase 4 arranca antes de que Fase 1 esté en el entorno de prueba. El `@DELETE` devuelve 404 o error de conexión. | Media | Alto | Gate de entrada explícito (Paso 0, ítem 1). No iniciar implementación Flutter hasta confirmar el endpoint. |
| R-2 | **Referencia residual a `deleteVehicle`:** Algún archivo importa `DeleteVehicleUseCase` o llama `repository.deleteVehicle` y no fue actualizado, causando error de compilación. | Baja | Medio | Pre-flight grep en Paso 0 enumera todos los hits. `dart analyze` en cero errores es CA-9. Grep de verificación en Paso 7. |
| R-3 | **Compilación rota si `vehicle_form_cta.dart` no se actualiza:** `VehicleFormBody` y `VehicleFormCta` declaran `onDelete` como `required`; olvidar actualizar `VehicleFormCta` deja la compilación rota aunque `VehicleFormBody` ya no pase el param. | Media | Alto | El Paso 6 lista la cadena explícitamente: actualizar `VehicleFormCta` → `VehicleFormBody` → `VehicleFormView` → `VehicleFormPage` en ese orden. `dart analyze` detecta el error antes de `flutter test`. |
| R-4 | **`VehicleFormPage` con `BlocProvider<VehicleDeleteCubit>` sin limpiar:** Si no se elimina el provider, el cubit se instancia innecesariamente en cada apertura del form, introduciendo estado fantasma. | Baja | Bajo | El Paso 6d es explícito sobre la eliminación de este provider. CA-12 verifica la ausencia del provider. |
| R-5 | **Re-fetch redundante tras éxito:** `fetchMyVehicles()` lanza `ResultState.loading()` brevemente, causando un flash de skeleton en el garaje. | Baja | Bajo | Comportamiento aceptable — es el patrón establecido en el proyecto para sincronizar con el backend. |
| R-6 | **Opción "Eliminar permanentemente" visible en activos por condición mal colocada.** | Baja | Medio | La condición `if (vehicle.isArchived)` debe envolver exactamente el tile destructivo. Test A verifica la visibilidad contextual. |
| R-7 | **`parentContext.mounted` false tras await de `ConfirmationDialog.show`.** | Baja | Bajo | Guard `if (confirm != true || !parentContext.mounted) return;` ya presente en el proyecto — replicar el patrón existente del mismo archivo. |

---

## Dependencias (fases prerequisito y por qué)

| Fase | Título | Por qué es prerequisito |
|------|--------|------------------------|
| **Fase 1** | Backend: soft-delete e integridad de datos | El endpoint `DELETE /api/vehicles/my/:vehicleId` debe existir y responder. Sin él, el `@DELETE` Retrofit devuelve 404 o error de conexión. El gate de entrada del Paso 0 lo verifica explícitamente antes de tocar código. |
| **Fase 3** | Flutter: archivar y restaurar vehículos | La opción "Eliminar permanentemente" vive en el menú de archivados. Sin Fase 3 no existe la bifurcación de menú (`if (vehicle.isArchived)`) ni la sección "Archivados", y la opción no tiene punto de entrada visible. `GarageOptionsBottomSheet` debe tener la estructura de menú bifurcado ya establecida. |

---

## Ejecución recomendada (nivel rg-exec: normal)

**Por qué normal:** Feature acotada que depende de un nuevo endpoint de Fase 1. Incluye renombrado de interfaz de dominio (3 archivos + use case + cubit) y eliminación del punto de entrada del form (cadena de 4 archivos). Riesgo medio controlado por el gate de entrada de despliegue. `ConfirmationDialog` ya soporta `DialogActionType.danger` — no hay trabajo de shared widgets nuevo. Un arquitecto + QA + 2 rondas de auditor cubren el riesgo.

**Agentes sugeridos para rg-exec normal:**
- **Implementador (Sonnet):** Ejecuta los 7 pasos ordenados: pre-flight → l10n → dominio → data → cubit → UI garage → UI form (cadena 4 archivos) → tests.
- **Arquitecto (en revisión):** Verifica que el renombrado es completo (grep del Paso 7 en cero), que la ruta Retrofit apunta al endpoint correcto, que la bifurcación de menú es mutuamente excluyente, y que el form no tiene punto de entrada de eliminación (cadena completa: `VehicleFormCta`, `VehicleFormBody`, `VehicleFormView`, `VehicleFormPage`).
- **QA (en revisión):** Confirma que los tres widget tests cubren los criterios CA-2, CA-3 y CA-4. Verifica que `dart analyze` y `flutter test` pasan en verde. Confirma que `vehicle_vehicleDeleted` y `vehicle_form_delete_vehicle` no tienen consumidores activos tras la fase.
- **Auditor Opus (2 rondas):** Verifica conformidad con Clean Architecture (dominio sin Flutter, data sin `BuildContext`, presentación sin DTOs), cumplimiento de coding standards (l10n, un widget por archivo, no métodos que retornan widgets), y que el gate de entrada del Paso 0 está verificado.

**Comando de arranque sugerido:**
```
/rg-exec docs/plans/archive-vehicle-soft-delete/phases/phase-04-flutter-eliminacion-permanente-desde-archivados.md --mode normal
```

---

## Claves l10n

### Claves nuevas requeridas en esta fase

Añadir en `lib/l10n/app_es.arb` antes de cualquier implementación:

```json
"vehicle_permanentDeleteTitle": "Eliminar vehículo permanentemente",
"vehicle_permanentDeleteMessage": "Esta acción es irreversible. El vehículo «{vehicleName}» y su historial serán eliminados definitivamente.",
"@vehicle_permanentDeleteMessage": {
  "placeholders": {
    "vehicleName": {
      "type": "String"
    }
  }
},
"vehicle_permanentDeleteAction": "Eliminar permanentemente",
"vehicle_permanentDeleteSuccess": "Vehículo eliminado permanentemente",
"vehicle_permanentDeleteError": "No se pudo eliminar el vehículo"
```

### Claves existentes que se reutilizan sin cambios

- `cancel` → "Cancelar" (global)

### Claves existentes que esta fase ya no consume (verificar con grep)

- `vehicle_vehicleDeleted` (ARB línea 345) → actualmente en `garage_options_bottom_sheet.dart` línea 56. Esta fase migra ese uso a `vehicle_permanentDeleteSuccess`. Verificar con `grep -rn 'vehicle_vehicleDeleted' lib/` post-Fase 4; si no quedan consumidores, marcar como candidata a deprecar en un cleanup posterior (fuera del scope).
- `vehicle_deleteVehicle` (ARB línea 332) → actualmente en `vehicle_form_view.dart` línea 107 y `garage_options_bottom_sheet.dart` línea 165. Al eliminar el punto de entrada del form y reemplazar el tile del garaje, puede quedar sin consumidores. Verificar con `grep -rn 'vehicle_deleteVehicle' lib/` post-Fase 4.
- `vehicle_deleteVehicleConfirmContent` (ARB línea 337) → usado en `vehicle_form_view.dart` y `garage_options_bottom_sheet.dart`. Al eliminar ambos usos, puede quedar sin consumidores. Verificar post-Fase 4.
- `vehicle_form_delete_vehicle` (ARB línea 643) → usado exclusivamente en `vehicle_form_cta.dart`. Al eliminar el bloque `if (state.isEditing)` del CTA, deja de tener consumidores. Verificar con `grep -rn 'vehicle_form_delete_vehicle' lib/` post-Fase 4.
- `deletedSuccessfully` (ARB línea 35) → usado en `vehicle_form_view._deleteListener` línea 314. Al eliminar `_deleteListener`, puede quedar sin consumidores en el contexto de vehículos. Verificar que no se usa en otros features antes de considerar deprecar.

**No crear duplicados** de ninguna clave existente.
