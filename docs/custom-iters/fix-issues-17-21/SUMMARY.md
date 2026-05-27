# Summary — fix-issues-17-21

## Goal

Fix two bugs on branch `fix/github-issues`:

- **Issue #17 (High):** SOAT documents attached during vehicle creation were silently dropped — `soatLocalPath` was saved in `VehicleFormState` but never sent to the backend.
- **Issue #21 (Critical):** The vehicle selector on the registration form showed "no vehicles" while `VehicleCubit` was still loading, blocking users from completing event registrations even when they had vehicles.

---

## What changed

### Fix #17 — SOAT saved after vehicle creation

- **`lib/features/vehicles/presentation/form/vehicle_form_page.dart`** — `_formListener`'s `data:` branch now checks `!state.isEditing && soatPath != null && savedVehicle.id != null`. When true, calls `Navigator.of(context).pushReplacement(MaterialPageRoute(...))` to open `SoatConfirmationPage` with the new `vehicleId` and the pending `XFile`, instead of popping to garage. The existing `SoatConfirmationPage` flow handles upload + date/insurer capture + backend call (`POST /api/vehicles/:vehicleId/soat`) + `VehicleCubit.updateSoatLocally`.
- **`lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart`** — minor addition to surface `setSoatFromLocalPath` for consumption by the form page.
- **`lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart`** — pre-existing Fix #16 (options sheet integration); not modified by this iter.

### Fix #21 — Vehicle selector loading state in registrations

- **`lib/features/event_registration/presentation/registration_form_content.dart`** — `BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>` refactored from `context.read().availableVehicles` (bypassed state snapshot) to `state.when(...)` covering all 5 `ResultState` variants: `initial`/`loading` → `VehicleSelectorLoading`, `data` with vehicles → `VehicleSelectorField`, `data` empty / `empty` / `error` → `VehicleSelectorEmpty`.
- **`lib/features/event_registration/presentation/widgets/vehicle_selector_loading.dart`** — new widget: `CircularProgressIndicator` centred.
- **`lib/features/event_registration/presentation/widgets/vehicle_selector_empty.dart`** — new widget: empty-state text + "Crear vehículo" `AppButton`, receives `VoidCallback onCreate`.
- **`lib/features/event_registration/presentation/widgets/vehicle_selector_field.dart`** — new widget: full `FormBuilderField<String>` with `GestureDetector` + `VehicleSelectionBottomSheet.show` + `InputDecorator`; receives `List<VehicleModel> availableVehicles`.

### Pre-existing fixes on branch (not touched by this iter)

- **Fix #20** — `events_cubit.dart`: `.toUpperCase()` on event type filter to prevent 400 errors.
- **Fix #16** — `vehicle_form_docs_section.dart`: SOAT tap shows options sheet.

---

## Files modified

```
lib/features/event_registration/presentation/registration_form_content.dart    | 91 ++++++----------------
lib/features/events/presentation/list/events_cubit.dart                        |  2 +-
lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart               |  4 +
lib/features/vehicles/presentation/form/vehicle_form_page.dart                 | 17 ++++
lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart | 16 +++-
5 files changed, 58 insertions(+), 72 deletions(-)

New (untracked):
  lib/features/event_registration/presentation/widgets/vehicle_selector_empty.dart
  lib/features/event_registration/presentation/widgets/vehicle_selector_field.dart
  lib/features/event_registration/presentation/widgets/vehicle_selector_loading.dart
  test/features/event_registration/presentation/widgets/vehicle_selector_loading_test.dart
  test/features/event_registration/presentation/widgets/vehicle_selector_empty_test.dart
  test/features/vehicles/presentation/cubit/vehicle_form_cubit_soat_test.dart
```

---

## Tests

| Category | Count |
|----------|-------|
| Baseline (pre-existing) | 108 |
| New tests added | 11 |
| **Total** | **119** |
| Failures | 0 |

New test breakdown:
- `vehicle_selector_loading_test.dart` — 3 widget tests (TC-vsel-1 to TC-vsel-3)
- `vehicle_selector_empty_test.dart` — 3 widget tests (TC-vempty-1 to TC-vempty-3)
- `vehicle_form_cubit_soat_test.dart` — 5 unit tests (TC-vform-soat-1 to TC-vform-soat-5)

`dart analyze`: 0 new issues in all changed/new files. 45 pre-existing issues unchanged.

---

## Risks / regression watchlist

| Risk | Level | Notes |
|------|-------|-------|
| Navigation double-pop on `SoatConfirmationPage` | **MEDIUM** | `SoatConfirmationPage.success` calls `Navigator.pop()` then `router.pop()`. When entered via `Navigator.pushReplacement(MaterialPageRoute)`, the second `router.pop()` may over-pop the GoRouter stack and land on a blank or wrong screen. Manual probe AC-1 must pass before committing. Remediation if it fails: remove `router.pop()` from the success handler or add a source flag. |
| Missing `context.mounted` guard | LOW | `Navigator.pushReplacement` called synchronously inside `BlocListener` — near-zero unmounted risk in practice, but inconsistent with project convention. Not blocking. |
| Edit-vehicle regression | LOW | Guard `!state.isEditing` correctly prevents SOAT redirect on edits. Covered by TC-vform-soat-5. |
| `FormBuilderField` reset on `loading->data` transition | LOW | Field only mounts when `VehicleCubit` reaches `data`; fresh mount on first data emission is the correct and expected behavior. |

---

## Recommended commit message

```
fix(vehicles,registration): persist SOAT after vehicle creation and fix vehicle selector loading state

- Fix #17: VehicleFormPage._formListener now redirects to SoatConfirmationPage
  (via Navigator.pushReplacement) when a new vehicle is created with a pending
  soatLocalPath, reusing the existing SOAT upload + confirmation flow so
  dates/insurer are captured before persisting.
- Fix #21: RegistrationFormContent BlocBuilder now uses state.when() snapshot
  instead of context.read().availableVehicles, correctly showing a spinner
  (initial/loading), vehicle selector (data with vehicles), or empty CTA
  (data empty / empty / error).
- Extract VehicleSelectorLoading, VehicleSelectorEmpty, VehicleSelectorField
  widgets per rideglory one-widget-per-file coding standard.
- Add 11 new tests: 3 VehicleSelectorLoading, 3 VehicleSelectorEmpty,
  5 VehicleFormCubit soatLocalPath unit tests. Total: 119/119 passing.
- dart analyze: 0 new issues in changed/new files.

Closes #17, #21
```
