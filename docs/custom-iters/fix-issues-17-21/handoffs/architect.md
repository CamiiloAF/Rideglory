# Architect Handoff — Fix Issues #17 & #21

## Goal acknowledgement

Persistir el documento SOAT capturado durante la creación de un vehículo nuevo reutilizando el flujo existente de `SoatConfirmationPage` con el `vehicleId` recién creado (Issue #17), y hacer que el `BlocBuilder` del selector de vehículo en el formulario de inscripción reaccione a los estados `initial`/`loading`/`empty`/`data` del `VehicleCubit` para no mostrar el estado vacío mientras los vehículos cargan (Issue #21). Sin cambios de backend, sin cambios de schema, sin cambios visuales más allá del spinner.

---

## Change map

| File | Action | One-line reason | Risk |
|------|--------|------------------|------|
| `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | modify | En `_formListener`, tras `data:` en flujo de creación, si `state.soatLocalPath != null` empujar `SoatConfirmationPage(vehicle: savedVehicle, documentImage: XFile(state.soatLocalPath!))` antes de hacer `context.pop(savedVehicle)`. | med |
| `lib/features/event_registration/presentation/registration_form_content.dart` | modify | Refactor del `BlocBuilder` del selector (L407–478): usar el snapshot `state` en lugar de `context.read<...>().availableVehicles`, y renderizar spinner cuando `state is Initial<...>` o `state is Loading<...>`. | low |

No otros archivos necesitan tocarse. `VehicleFormCubit`, `VehicleFormState`, `vehicle_form_docs_section.dart`, `soat_form_cubit.dart`, `soat_confirmation_page.dart`, `vehicle_repository_impl.dart` y `vehicle_cubit.dart` quedan **intactos**.

---

## Fix #17 — implementation detail

### Análisis del flujo actual

1. `VehicleFormDocsSection._onSoatTap` (L105–123): para vehículos sin `id`, abre `VehicleSoatOptionsSheet`. Si el usuario elige subir imagen, llama `cubit.setSoatFromLocalPath(result.image.path)` → la ruta queda en `VehicleFormState.soatLocalPath`.
2. `VehicleFormPage._saveVehicle` (L107–118): valida el form y llama `cubit.saveVehicle(vehicleToSave, localImagePath: imageCubit.selectedLocalImagePath)`. **No usa `soatLocalPath` para nada.**
3. `VehicleFormCubit.saveVehicle` (L65–87): en flujo de creación, sube la imagen de portada a Firebase, llama `AddVehicleUseCase` → backend retorna `VehicleModel` con `id`. Emite `ResultState.data(savedVehicle)`. **No interactúa con SOAT.**
4. `VehicleFormPage._formListener` (L144–174): en `data:` muestra SnackBar y hace `context.pop(savedVehicle)`. Pierde la oportunidad de persistir el SOAT.

El `SoatModel` que el backend espera (`upsertSoat` payload, ver `vehicle_repository_impl.dart` L100–116) requiere `startDate`, `expiryDate`, `insurer` no-null. Durante la creación del vehículo el usuario **solo seleccionó una imagen**, no llenó esos campos. Por eso **no podemos** llamar `SoatFormCubit.submit` ni `VehicleRepository.upsertSoat` directamente con los datos disponibles.

### Solución elegida: reutilizar el flujo existente de `SoatConfirmationPage`

`SoatConfirmationPage(vehicle, documentImage)` (`lib/features/vehicles/presentation/soat/soat_confirmation_page.dart`) ya:
- Recibe un `XFile? documentImage` y un `VehicleModel vehicle` (con `id` no-null requerido).
- Renderiza preview de la imagen + formulario de aseguradora/fechas.
- Al hacer `SoatConfirmCtaBar` → `SoatFormCubit.submit(vehicleId, documentImage: ...)`, sube a Firebase Storage y llama `POST /api/vehicles/:vehicleId/soat`.
- En `success` actualiza `VehicleCubit.updateSoatLocally(vehicleId, expiryDate)` y hace `Navigator.of(context).pop(); router.pop();` (dos pops).

Es exactamente el flujo que necesitamos post-creación. El usuario verá el formulario de SOAT con la imagen ya cargada y completará dates/insurer; al confirmar, el SOAT queda persistido contra el `vehicleId` nuevo.

### Cambio exacto en `vehicle_form_page.dart`

Ubicación: `_formListener`, branch `data:` (líneas 144–174).

Pseudo-código del cambio:

```dart
void _formListener(BuildContext context, VehicleFormState state) {
  state.vehicleResult.whenOrNull(
    data: (savedVehicle) {
      if (state.isEditing) {
        context.read<VehicleCubit>().applySavedVehicleEdit(savedVehicle);
      } else {
        context.read<VehicleCubit>().addVehicleLocally(savedVehicle);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.isEditing
                ? context.l10n.updatedSuccessfully
                : context.l10n.savedSuccessfully,
          ),
          backgroundColor: AppColors.success,
        ),
      );

      // Issue #17: si es creación y hay SOAT pendiente, redirigir al flujo
      // existente de confirmación SOAT con el vehicleId nuevo.
      final soatPath = state.soatLocalPath;
      if (!state.isEditing && soatPath != null && savedVehicle.id != null) {
        // Replace current form route with SoatConfirmationPage so back/pop
        // returns to garage, no stale form intermediate.
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

      context.pop(savedVehicle);
    },
    error: (error) { /* unchanged */ },
  );
}
```

**Notas para Frontend:**
- Importar `package:image_picker/image_picker.dart` para `XFile`, y `package:rideglory/features/vehicles/presentation/soat/soat_confirmation_page.dart`.
- `pushReplacement` con `MaterialPageRoute` evita anidar `SoatConfirmationPage` encima del form (el form ya hizo su trabajo). `SoatConfirmationPage` en `success` ya hace dos pops; con `pushReplacement` el primer pop saca la confirmación, el segundo regresa a garage. Verificar comportamiento de navegación con `go_router` — si `pushReplacement` no compone bien, usar `context.pop(savedVehicle)` + `context.push(...)` en su lugar.
- **Alternativa más segura:** usar `Navigator.of(context).pushReplacement(MaterialPageRoute(...))` directamente para evitar mezclar `go_router` con la navegación interna de `SoatConfirmationPage` (que usa `Navigator.of(context).pop()` + `GoRouter.of(context).pop()`). Frontend debe validar manualmente que tras el confirm el usuario aterriza en garage, no en pantalla blanca.
- AC-4 (error handling del SOAT): si `upsertSoat` falla dentro de `SoatConfirmationPage`, el `SoatFormCubit` emite `error` y se muestra SnackBar; el vehículo **ya existe** porque la creación ya completó. El usuario puede reintentar o salir; el vehículo queda sin SOAT pero no se pierde. Esto satisface AC-4 sin código adicional.

### Por qué NO orquestar SOAT dentro del cubit

PO sugirió centralizar la llamada SOAT en `VehicleFormCubit`. Rechazado porque:
1. Requeriría que el usuario llene insurer/dates en la pantalla del form de vehículo (cambio de UI no contemplado en PRD), o
2. Persistir un SOAT con valores placeholder (viola contrato del backend).

La única forma de obtener dates+insurer **sin cambios de diseño** es reutilizar `SoatConfirmationPage`, que ya está construido para ello. Por lo tanto, la orquestación queda en la página, no en el cubit.

---

## Fix #21 — implementation detail

Ubicación: `lib/features/event_registration/presentation/registration_form_content.dart`, `BlocBuilder` en líneas 407–479.

### Bug

```dart
BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
  builder: (context, _) {  // ← state ignorado
    final availableVehicles = context
        .read<VehicleCubit>()
        .availableVehicles  // ← lee _vehicles (vacío durante loading)
        .where((vehicle) => !vehicle.isArchived)
        .toList();
    if (availableVehicles.isEmpty) {
      return /* empty state with CTA */;
    }
    return /* selector */;
  },
)
```

Cuando `VehicleCubit` está en `ResultState.loading()` o `ResultState.initial()`, `availableVehicles` retorna `[]` → cae al empty state aunque el usuario sí tenga vehículos.

### Fix

Usar el snapshot del state vía pattern matching de `ResultState`:

```dart
BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
  builder: (context, state) {
    return state.when(
      initial: () => const _VehicleSelectorLoading(),
      loading: () => const _VehicleSelectorLoading(),
      data: (vehicles) {
        final availableVehicles =
            vehicles.where((vehicle) => !vehicle.isArchived).toList();
        if (availableVehicles.isEmpty) {
          return _VehicleSelectorEmpty(
            onCreate: () => _openCreateVehicle(context),
          );
        }
        return _VehicleSelectorField(availableVehicles: availableVehicles);
      },
      empty: () => _VehicleSelectorEmpty(
        onCreate: () => _openCreateVehicle(context),
      ),
      error: (_) => _VehicleSelectorEmpty(
        onCreate: () => _openCreateVehicle(context),
      ),
    );
  },
)
```

**Constraints del proyecto (rideglory-coding-standards):**
- Un widget por archivo. Frontend debe extraer las tres ramas a clases-widget propias (un archivo cada una) bajo `lib/features/event_registration/presentation/widgets/`:
  - `vehicle_selector_loading.dart` — `CircularProgressIndicator` centrado con padding consistente (puede usar `Center` + `Padding` con tokens de `AppSpacing`).
  - `vehicle_selector_empty.dart` — el bloque actual con texto + `AppButton` CTA.
  - `vehicle_selector_field.dart` — el `FormBuilderField<String>` actual con `GestureDetector` + `InputDecorator` + `VehicleSelectionBottomSheet.show`.
- Prohibidos métodos `Widget _build...()` que retornen widgets — confirmado en CLAUDE.md.
- Localización: el spinner no necesita string nuevo (visual puro); reutilizar strings existentes para empty.

### Por qué no llamar `fetchMyVehicles` desde `RegistrationFormContent`

PO preguntó si conviene disparar `fetchMyVehicles()` al montar el form si el cubit está en `initial`. **Decisión arquitectónica: no** en este fix. `VehicleCubit` es `@singleton` y se carga en el flujo de splash/home (verificar trace de llamadas a `fetchMyVehicles()` durante el bootstrapping); si llega en `initial` aquí es síntoma de timing de navegación, no de cargar vehículos. El spinner es suficiente garantía visual y la carga la hace quien la haya disparado originalmente. Si Frontend descubre que `VehicleCubit` puede quedar en `initial` permanentemente al entrar directo a inscripción (deep link), abrir un BUG aparte — fuera de alcance.

---

## Data model impact

Ninguno. No hay cambios en modelos, DTOs, ni en el contrato del backend. `SoatModel`, `VehicleModel`, `VehicleFormState` quedan iguales.

---

## Contract impact

Ninguno. Reutilizamos endpoints existentes:
- `POST /api/vehicles` (creación) — sin cambios.
- `POST /api/vehicles/:vehicleId/soat` — sin cambios, llamado desde `SoatConfirmationPage` reutilizado.

---

## Risk register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| `pushReplacement` con `MaterialPageRoute` no compone correctamente con `go_router` y el doble `pop()` de `SoatConfirmationPage` rompe la navegación de vuelta a garage | med | high | Frontend prueba manualmente el flujo completo en simulador iOS y Android antes de cerrar el ticket. Si rompe, usar `Navigator.of(context, rootNavigator: false).pushReplacement(...)` y validar con `WidgetsBinding.addPostFrameCallback`. |
| Usuario cancela el `SoatConfirmationPage` (back button) → vehículo creado sin SOAT, sin SnackBar | med | low | Comportamiento aceptable per AC-3 (sin SOAT funciona) + AC-4 (vehículo no se pierde). El vehículo existe en garage; usuario puede agregar SOAT después tocando el slot. |
| Refactor del `BlocBuilder` introduce regresión en validación del `FormBuilderField` cuando el state cambia de `loading` a `data` (puede resetear `field.value`) | low | med | Verificar con widget test que el `FormBuilderField` solo se monta cuando hay vehículos; al cambiar de empty → data el campo se monta desde cero, lo cual es deseable. |
| `_openCreateVehicle` se llama desde dos lugares ahora (loading→empty, empty real), pero `context` puede no ser válido en el branch de error si el cubit emitió desde un evento async | low | low | Pasar `context` directo del builder; no almacenar referencias. |
| Importar `image_picker` en `vehicle_form_page.dart` agrega dependencia transitiva | low | low | `image_picker` ya está en pubspec, importado por otros archivos del feature. |

---

## Regression test surface

| Surface | Cobertura existente | Acción requerida |
|---------|--------------------|-------------------|
| `VehicleFormCubit.saveVehicle` (creación + edición) | `test/features/vehicles/presentation/cubit/vehicle_form_cubit_test.dart` (verificar existencia) | Extender solo si Frontend toca el cubit — en este fix **no se toca**, así que no se requieren cambios. |
| `VehicleFormPage._formListener` flujo de creación con SOAT | No hay test directo | QA: smoke test manual (crear vehículo con SOAT, sin SOAT, con SOAT + cancelar confirmación). |
| `RegistrationFormContent` selector de vehículo | Verificar `test/features/event_registration/...` | Agregar/extender widget test que monte el componente con `VehicleCubit` en cada estado (`Initial`, `Loading`, `Empty`, `Data` con/ sin vehículos) y verifique el widget renderizado. |
| `SoatConfirmationPage` (flujo reutilizado) | No tocar — ya validado en iter-2 | Sin cambios. |
| `dart analyze` | Baseline 0/0 | Correr al finalizar; comparar contra baseline. |

---

## Implementation order

Para Frontend, ejecutar en este orden estricto:

1. **Fix #21 primero** (menor riesgo, aislado):
   1. Crear `lib/features/event_registration/presentation/widgets/vehicle_selector_loading.dart` con `CircularProgressIndicator` centrado.
   2. Extraer el empty state actual a `vehicle_selector_empty.dart` (parametriza `onCreate`).
   3. Extraer el `FormBuilderField` actual a `vehicle_selector_field.dart` (recibe `List<VehicleModel> availableVehicles`).
   4. Refactor del `BlocBuilder` en `registration_form_content.dart` para usar `state.when(...)`.
   5. Verificar con `flutter run` que los tres estados renderizan correctamente (forzar cada uno con DevTools/breakpoints).
2. **Fix #17**:
   1. Importar `image_picker` y `SoatConfirmationPage` en `vehicle_form_page.dart`.
   2. Modificar `_formListener` branch `data:` para empujar `SoatConfirmationPage` cuando `!isEditing && soatLocalPath != null`.
   3. Probar manualmente: crear vehículo con SOAT → completar fechas/aseguradora en confirmación → verificar badge en garage.
   4. Probar manualmente: crear vehículo sin SOAT → flujo idéntico al anterior (sin regresión).
   5. Probar manualmente: crear vehículo con SOAT + cancelar la confirmación → vehículo en garage sin SOAT.
3. **Lint + tests**:
   1. `dart format lib/features/vehicles/presentation/form/vehicle_form_page.dart lib/features/event_registration/presentation/`
   2. `dart analyze`
   3. `flutter test test/features/event_registration/` (si aplica)

---

## Out of scope

- Tech review document upload post-creación (mismo bug latente, no reportado).
- Cambios al `SoatConfirmationPage` o `SoatFormCubit`.
- Refactor del `VehicleCubit` para garantizar carga eager antes de inscripción.
- Skip de fechas/insurer en el flujo de creación (requeriría cambio de schema en backend).
- Cambios visuales en el spinner del selector (usar widget estándar centrado).
- Cambios de strings ARB.

---

## Notes for orchestrator

- Rama activa: `fix/github-issues`. Los fixes #16 y #20 ya están aplicados — Frontend no debe tocar archivos no listados en el change map.
- No se requiere `dart run build_runner build` salvo que Frontend acepte la opción de cambiar `VehicleFormState` (no recomendado — no la cambien).
- QA debe verificar AC-1 a AC-8 contra dispositivo real o simulador, no solo widget tests.
- Si Frontend encuentra que `context.pushReplacement` con `MaterialPageRoute` no funciona con `go_router`, fallback documentado: `context.pop(savedVehicle)` seguido de un `Future.microtask` que abra `SoatConfirmationPage` con `context.push(...)`. Validar con QA antes de mergear.
