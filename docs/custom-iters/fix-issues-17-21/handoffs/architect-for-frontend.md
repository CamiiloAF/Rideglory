# Architect → Frontend (slim) — Fix Issues #17 & #21

> Slim handoff for /custom-iter fix-issues-17-21. Full detail in architect.md (read only if ambiguous).

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | modify | En `_formListener` data branch (L144–174), si es creación y `state.soatLocalPath != null`, empujar `SoatConfirmationPage` con el `savedVehicle` y el `XFile` en vez de hacer pop directo. | med |
| `lib/features/event_registration/presentation/registration_form_content.dart` | modify | Refactor `BlocBuilder` (L407–479): usar `state.when(...)` en vez de leer `availableVehicles` del cubit. | low |
| `lib/features/event_registration/presentation/widgets/vehicle_selector_loading.dart` | create | Widget para spinner del selector mientras `VehicleCubit` está en `initial`/`loading`. | low |
| `lib/features/event_registration/presentation/widgets/vehicle_selector_empty.dart` | create | Extracción del empty state actual (texto + `AppButton` CTA crear vehículo). | low |
| `lib/features/event_registration/presentation/widgets/vehicle_selector_field.dart` | create | Extracción del `FormBuilderField<String>` actual con `GestureDetector` + `VehicleSelectionBottomSheet`. | low |

No tocar: `VehicleFormCubit`, `VehicleFormState`, `SoatFormCubit`, `SoatConfirmationPage`, `VehicleCubit`, `VehicleRepository*`, `vehicle_form_docs_section.dart`. Quedan iguales.

## Fix #17 — exacto

En `vehicle_form_page.dart` `_formListener` branch `data:` (línea 146):

1. Mantener la actualización de `VehicleCubit` (`addVehicleLocally` / `applySavedVehicleEdit`).
2. Mantener el SnackBar de éxito.
3. **Antes** de `context.pop(savedVehicle)`, añadir:
   ```dart
   final soatPath = state.soatLocalPath;
   if (!state.isEditing && soatPath != null && savedVehicle.id != null) {
     context.pushReplacement(
       MaterialPageRoute<void>(
         builder: (_) => SoatConfirmationPage(
           vehicle: savedVehicle,
           documentImage: XFile(soatPath),
         ),
       ),
     );
     return;
   }
   ```
4. Si la rama no aplica, sigue el `context.pop(savedVehicle)` actual.

Imports a agregar:
- `package:image_picker/image_picker.dart` (XFile)
- `package:rideglory/features/vehicles/presentation/soat/soat_confirmation_page.dart`

`SoatConfirmationPage` en `success` ya hace `Navigator.pop()` + `router.pop()` y llama `VehicleCubit.updateSoatLocally` — no se duplica nada.

**Fallback si `pushReplacement` con `MaterialPageRoute` rompe con go_router:** hacer `context.pop(savedVehicle)` y dentro de `Future.microtask` abrir `SoatConfirmationPage` con `context.push(...)`. Validar manualmente.

**Por qué reutilizar `SoatConfirmationPage`:** `SoatModel` requiere `startDate`, `expiryDate`, `insurer` no-null. El usuario no los provee durante creación; debe completarlos. La página de confirmación ya tiene el formulario y la lógica de `SoatFormCubit.submit` que sube imagen + llama backend. No duplicar.

## Fix #21 — exacto

En `registration_form_content.dart` reemplazar el `BlocBuilder` (L407–479):

```dart
BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
  builder: (context, state) {
    return state.when(
      initial: () => const VehicleSelectorLoading(),
      loading: () => const VehicleSelectorLoading(),
      data: (vehicles) {
        final available =
            vehicles.where((v) => !v.isArchived).toList();
        if (available.isEmpty) {
          return VehicleSelectorEmpty(
            onCreate: () => _openCreateVehicle(context),
          );
        }
        return VehicleSelectorField(availableVehicles: available);
      },
      empty: () => VehicleSelectorEmpty(
        onCreate: () => _openCreateVehicle(context),
      ),
      error: (_) => VehicleSelectorEmpty(
        onCreate: () => _openCreateVehicle(context),
      ),
    );
  },
)
```

`VehicleSelectorLoading`: `Center(Padding(child: CircularProgressIndicator()))` con padding vertical consistente al resto del form.

`VehicleSelectorEmpty`: recibe `VoidCallback onCreate`. Contiene el texto `registration_vehicleEmptyStateTitle` + `AppButton(label: registration_createVehicleCta, style: AppButtonStyle.outlined, onPressed: onCreate)`.

`VehicleSelectorField`: recibe `List<VehicleModel> availableVehicles`. Contiene el `FormBuilderField<String>` actual con su validator, `GestureDetector`, `VehicleSelectionBottomSheet.show`, `InputDecorator`.

## Implementation order

1. **Fix #21**:
   1. Crear los 3 widgets nuevos en `lib/features/event_registration/presentation/widgets/`.
   2. Refactor del `BlocBuilder` en `registration_form_content.dart`.
   3. Verificar manualmente cada estado (initial, loading, data lleno, data vacío, empty).
2. **Fix #17**:
   1. Agregar imports en `vehicle_form_page.dart`.
   2. Modificar branch `data:` en `_formListener`.
   3. Verificar manualmente: con SOAT, sin SOAT, cancelando confirmación.
3. **Cierre**:
   1. `dart format` de archivos tocados.
   2. `dart analyze` — debe pasar 0/0.
   3. `flutter test` — debe seguir verde.

## Risks to watch

- Navegación `pushReplacement` + `go_router` + double-pop interno de `SoatConfirmationPage`: probar en simulador antes de cerrar.
- `FormBuilderField` del selector se desmonta/monta al cambiar de estado loading→data: aceptable, el valor inicial es `null` y se setea via `field.didChange`.
- Si Frontend ve que `VehicleCubit` queda en `initial` permanente al entrar directo a inscripción (deep link), no resolverlo aquí — abrir BUG aparte.
- No introducir métodos `Widget _build...()` ni meter múltiples widget classes en un archivo (rideglory-coding-standards: violación cero tolerancia).

## AC verification cheatsheet

- AC-1, AC-2: crear vehículo + SOAT → llenar fechas → guardar → ver badge en garage.
- AC-3: crear vehículo sin SOAT → mismo flujo, sin regresión.
- AC-4: crear vehículo + SOAT → en confirmación, forzar error de red → SnackBar de error, vehículo presente en garage.
- AC-5: inscribirse a evento con `allowedBrands = ['*']` → selector muestra vehículos.
- AC-6: navegar a inscripción cuando `VehicleCubit` está cargando → spinner visible.
- AC-7: usuario sin vehículos → empty state + CTA visible.
- AC-8: `dart analyze` 0/0.
