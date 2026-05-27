# Frontend Handoff — Fix Issues #17 & #21

## Baseline test result

108 tests, all passing. No pre-existing failures.

## Files changed

| File | Action | Description |
|------|--------|-------------|
| `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | modified | Added `image_picker` and `SoatConfirmationPage` imports; modified `_formListener` data branch to push `SoatConfirmationPage` via `Navigator.pushReplacement` when `soatLocalPath != null` on new vehicle creation |
| `lib/features/event_registration/presentation/registration_form_content.dart` | modified | Removed unused `flutter_form_builder` import; added imports for 3 new vehicle selector widgets; refactored `BlocBuilder` to use `state.when()` with proper loading/empty/data/error state handling |

## New files created

| File | Description |
|------|-------------|
| `lib/features/event_registration/presentation/widgets/vehicle_selector_loading.dart` | Shows `CircularProgressIndicator` during `VehicleCubit` initial/loading states |
| `lib/features/event_registration/presentation/widgets/vehicle_selector_empty.dart` | Shows empty state text + "Crear vehículo" CTA button; receives `VoidCallback onCreate` |
| `lib/features/event_registration/presentation/widgets/vehicle_selector_field.dart` | Contains the full `FormBuilderField<String>` with `GestureDetector`, `VehicleSelectionBottomSheet.show`, `InputDecorator`; receives `List<VehicleModel> availableVehicles` |

## Final test result

108 tests passed, 0 failed — zero regressions from these changes.

## dart analyze result

0 new issues in modified/created files. 45 pre-existing issues (in `api_base_url_resolver.dart` and test files) — unchanged from baseline.

## Manual verification steps

### Fix #17 (SOAT saved after vehicle creation)

1. Open the app on a simulator or device.
2. Navigate to Garage → tap "Agregar vehículo".
3. Fill in all required vehicle fields.
4. Tap the SOAT section and choose "Subir documento" — select any image from the gallery.
5. Tap "Guardar" (save).
6. **Expected:** After the vehicle creation success SnackBar, the app navigates to the SOAT confirmation page (instead of popping back to garage).
7. Fill in the required SOAT fields (insurer, start date, expiry date) and save.
8. **Expected:** SOAT saved SnackBar appears; app returns to garage; the newly created vehicle shows a SOAT badge (Vigente / Por vencer / Vencido) — not "Sin SOAT".

**Regression — no SOAT:**
1. Create a vehicle without attaching a SOAT document.
2. **Expected:** After save, app pops directly back to garage with no SOAT confirmation page — same as before.

**Regression — editing:**
1. Edit an existing vehicle's name.
2. **Expected:** After save, app pops normally; SOAT is unchanged.

### Fix #21 (Vehicle selector loading state)

1. Navigate directly to an event registration form before `VehicleCubit` finishes loading (e.g., deep link or very fast navigation from splash).
2. **Expected:** Spinner (`CircularProgressIndicator`) is visible in the vehicle section while loading.
3. Once `VehicleCubit` emits `data`, the vehicle dropdown appears immediately.
4. For an event with `allowedBrands = ['*']`, confirm all user vehicles appear in the dropdown.
5. For a user with no vehicles, confirm the empty state + "Crear vehículo" button appears.

## Notes for QA

- **AC-4 (SOAT upload error):** To test, enable airplane mode after the vehicle is created (before saving SOAT). The vehicle must remain in garage and a SOAT error SnackBar must appear. The vehcile is not lost.
- **Navigation stack:** The implementation uses `Navigator.of(context).pushReplacement` + `MaterialPageRoute` (same pattern as `soat_upload_page.dart` → `SoatConfirmationPage`). On SOAT success, `SoatConfirmationPage` does `Navigator.of(context).pop()` + `router.pop()` — this returns cleanly to the screen before `VehicleFormPage`.
- `VehicleSelectorField` is a `StatelessWidget` that accesses `FormBuilderField` via the builder pattern — state is managed by `FormBuilder`, not the widget itself.

## Pre-existing failures

None. All 108 tests passed before and after these changes.
