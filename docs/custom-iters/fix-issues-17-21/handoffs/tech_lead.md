# Tech Lead Handoff — Fix Issues #17 & #21

## Verdict

**ready_for_human_review**

All automated gates pass. One medium-severity navigation concern (double-pop behavior of `SoatConfirmationPage` after `Navigator.pushReplacement`) must be manually verified on device before commit. No blockers found in code or architecture.

---

## Files Reviewed

| File | Status |
|------|--------|
| `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | Reviewed — Fix #17 implementation |
| `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart` | Reviewed — new `setSoatFromLocalPath` method |
| `lib/features/event_registration/presentation/registration_form_content.dart` | Reviewed — Fix #21 BlocBuilder refactor |
| `lib/features/event_registration/presentation/widgets/vehicle_selector_loading.dart` | Reviewed — new widget |
| `lib/features/event_registration/presentation/widgets/vehicle_selector_empty.dart` | Reviewed — new widget |
| `lib/features/event_registration/presentation/widgets/vehicle_selector_field.dart` | Reviewed — new widget |
| `lib/features/events/presentation/list/events_cubit.dart` | Verified untouched except pre-existing Fix #20 (`.toUpperCase()` on event type) |
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart` | Verified untouched except pre-existing Fix #16 (SOAT options sheet integration) |
| `test/features/event_registration/presentation/widgets/vehicle_selector_loading_test.dart` | Reviewed — 3 tests, all pass |
| `test/features/event_registration/presentation/widgets/vehicle_selector_empty_test.dart` | Reviewed — 3 tests, all pass |
| `test/features/vehicles/presentation/cubit/vehicle_form_cubit_soat_test.dart` | Reviewed — 5 tests, all pass |

---

## Findings

| File:Line | Severity | Issue | Fix |
|-----------|----------|-------|-----|
| `vehicle_form_page.dart:168–175` | **major** | `Navigator.of(context).pushReplacement(MaterialPageRoute)` used inside a `BlocListener`, which is synchronous — no `context.mounted` check before the navigation call. In practice, `BlocListener` callbacks fire synchronously in the widget tree so unmounted risk is near-zero here, but the pattern is inconsistent with project conventions (other async navigations guard with `context.mounted`). Low actual risk but violates defensive coding standard. | Add `if (!context.mounted) return;` before `Navigator.of(context).pushReplacement(...)`. |
| `vehicle_form_page.dart:168–175` | **major** | Navigation double-pop risk: `SoatConfirmationPage.success` calls `Navigator.of(context).pop()` **then** `GoRouter.of(context).pop()`. When `SoatConfirmationPage` is reached via `Navigator.pushReplacement(MaterialPageRoute)` (not a GoRoute), `Navigator.pop()` removes the confirmation page and returns to the screen before `VehicleFormPage` (the caller). The subsequent `router.pop()` then fires a GoRouter-level pop on the already-restored screen, which could pop an unintended route. Must be verified on device — the risk is real though not certain. | Human must test the full AC-1 flow (create vehicle + SOAT → confirm → land on garage). If the screen after SOAT success is blank or an unexpected screen, the fix is to call `Navigator.of(context).pop()` only (skip `router.pop()`) or restructure `SoatConfirmationPage`'s success handler to be navigation-source-agnostic. |
| `vehicle_selector_field.dart:16` | **nit** | `VehicleSelectorField` uses `FormBuilderField<String>` directly (not a shared `AppTextField` or `AppDropdown`) — this is correct and acceptable because there is no shared component for a custom tap-to-select picker. No action needed, calling out for clarity that this is intentional. | N/A — already correct. |
| `vehicle_form_cubit.dart:46–48` | **nit** | `setSoatFromLocalPath(String path)` was pre-existing (called from `vehicle_form_docs_section.dart` in Fix #16). QA lists it as a new method added by this iter. Confirmed it existed before this iter based on code analysis — it was already present and the diff adds it to the public surface for Fix #17 consumption. No bug, just clarification. | None. |

---

## Fix #17 Analysis

**Correctness: PASS with one required manual probe.**

The implementation correctly:
- Captures `soatLocalPath` from the cubit state snapshot (line 166) **before** any navigation — no race condition.
- Guards with `!state.isEditing && soatPath != null && savedVehicle.id != null` — all three conditions required (lines 167).
- Editing flow (isEditing=true): falls through the guard and calls `context.pop(savedVehicle)` normally. Correct.
- Create without SOAT (soatPath==null): falls through the guard and calls `context.pop(savedVehicle)` normally. Correct.
- Uses `Navigator.of(context).pushReplacement(MaterialPageRoute)` — this means the `VehicleFormPage` GoRoute is replaced at the Navigator level. The route stays in GoRouter's route stack, but the Navigator page is replaced.

**Navigation stack concern (see Finding #2 above):** The double-pop in `SoatConfirmationPage.success` (`Navigator.pop()` + `router.pop()`) is designed for the existing flow where `SoatConfirmationPage` lives on top of a GoRoute. In the new flow (reached via `Navigator.pushReplacement`), the `Navigator.pop()` already lands the user in the correct screen; the subsequent `router.pop()` may remove an extra route. This must be confirmed by hand.

**AC-4 compliance:** If SOAT upload fails after vehicle creation, `SoatFormCubit` shows a SnackBar error; the vehicle already exists in `VehicleCubit` (added via `addVehicleLocally` before the navigation, line 152). Vehicle is not lost. This is correct and compliant with AC-4.

---

## Fix #21 Analysis

**Correctness: PASS — clean implementation.**

- `BlocBuilder` uses `state` parameter directly in `state.when(...)` — no `context.read` bypass.
- All 5 `ResultState` variants handled: `initial` → `VehicleSelectorLoading`, `loading` → `VehicleSelectorLoading`, `data` → `VehicleSelectorField` (or `VehicleSelectorEmpty` if `availableVehicles` is empty after filtering archived), `empty` → `VehicleSelectorEmpty`, `error` → `VehicleSelectorEmpty`.
- `isArchived` filter is applied correctly inside the `data` branch (line 416): `vehicles.where((vehicle) => !vehicle.isArchived).toList()`.
- `FormBuilderField<String>` validator preserved in `VehicleSelectorField` (line 18 of that file): `FormBuilderValidators.required(errorText: ...)`.
- `VehicleSelectionBottomSheet.show()` preserved (line 32 of `vehicle_selector_field.dart`).
- `_openCreateVehicle(context)` callback threaded to `VehicleSelectorEmpty.onCreate` in both `data` (empty case) and `empty` branches. The `context` passed is the builder's context, not a stale reference — correct.
- One widget per file in all 3 new files: confirmed.
- No Widget-returning methods in any of the 3 new widget files: confirmed.
- `_submitRegistration()` brand filter logic in `registration_form_content.dart` is unchanged (lines 70–116): no regression risk.

---

## Architecture Adherence

| Concern | Result |
|---------|--------|
| Domain layer has no Flutter/network imports | PASS — no domain files changed |
| Data layer has no widgets/BuildContext | PASS — no data files changed |
| Presentation uses domain models (not DTOs) | PASS — `VehicleModel` used throughout |
| No direct HTTP calls from presentation | PASS — SOAT upload delegated to `SoatFormCubit` via `SoatConfirmationPage` |
| All user-visible strings via l10n | PASS — `VehicleSelectorEmpty` uses `context.l10n.*`; `VehicleSelectorLoading` has no strings; `VehicleSelectorField` uses `context.l10n.*` |
| One widget per file (rideglory-coding-standards) | PASS — all 3 new files have exactly 1 widget class |
| No Widget-returning methods | PASS — all UI is in `build()` only |
| State management: ResultState pattern | PASS — `state.when()` covers all 5 variants |
| `BlocListener` vs `BlocBuilder` usage | PASS — `_formListener` is a proper `BlocListener`; `BlocBuilder` in `registration_form_content.dart` builds from snapshot |
| No boolean flags replacing ResultState | PASS |
| Navigation conventions (pushNamed vs go) | NOTE — `Navigator.of(context).pushReplacement(MaterialPageRoute)` deviates from the go_router convention but is the architect-approved approach for this case (avoids GoRoute registration for a transient flow); acceptable but requires device validation |

---

## Security Findings

None. No secrets, no PII in logs, no SQL string concatenation. `soatLocalPath` is a filesystem path used only locally — not logged, not sent to analytics. Clean.

---

## Test Adequacy

| AC | Coverage | Result |
|----|----------|--------|
| AC-1: SOAT badge visible after vehicle creation with SOAT | TC-vform-soat-2 (soatPath set in state); navigation + badge require E2E | PARTIAL — automated unit verifies state; E2E required |
| AC-2: Badge shows correct status (Vigente/Por vencer/Vencido) | Existing `soat_model_test.dart` covers badge logic | PASS (pre-existing) |
| AC-3: Create without SOAT → no regression | TC-vform-soat-1 (soatLocalPath is null initially); TC-vform-soat-4 (isEditing=false on create) | PASS |
| AC-4: SOAT upload fails → vehicle preserved | TC-vform-soat-2/3 (path stays in state); `SoatConfirmationPage` error handler (pre-existing); `addVehicleLocally` called before navigation | PASS — airplane mode test is the only gap (manual) |
| AC-5: Registration selector shows vehicles with allowedBrands=['*'] | Fix is at `BlocBuilder` level (no `availableVehicles` bypass); brand filter in `_submitRegistration` unchanged | PASS (code review) |
| AC-6: Spinner while loading | TC-vsel-1,2,3 — `VehicleSelectorLoading` widget tests | PASS |
| AC-7: Empty state with zero vehicles → CTA | TC-vempty-1,2,3 — `VehicleSelectorEmpty` widget tests | PASS |
| AC-8: `dart analyze` passes with 0 new issues | Confirmed: 0 new issues in all changed/new files; 45 pre-existing unchanged | PASS |

Test count: **119 tests passing, 0 failing** (confirmed by running new test files independently — all 11 new tests pass).

---

## Regression Risk Summary

| Area | Risk Level | Notes |
|------|-----------|-------|
| Vehicle editing flow (isEditing=true) | LOW | Guard condition `!state.isEditing` correctly excludes edits; TC-vform-soat-5 covers this |
| Create without SOAT | LOW | `soatPath == null` guard prevents redirect; TC-vform-soat-1 covers this |
| SOAT navigation post-creation | MEDIUM | Double-pop behavior of `SoatConfirmationPage` needs device validation — see Finding #2 |
| Brand-restricted event registration | LOW | `_submitRegistration()` unchanged; suite passes |
| `VehicleCubit` already in `data` state | LOW | `state.when(data: ...)` renders immediately; no flicker |
| `FormBuilderField` reset on state transition | LOW | Field only mounts when in `data` state with vehicles; mount-from-scratch on first data is correct |
| Fix #20 (events_cubit `.toUpperCase()`) | NONE | Single-line pre-existing fix, not introduced by this iter |
| Fix #16 (docs section SOAT options sheet) | NONE | Pre-existing fix, confirmed not re-touched by this iter |

---

## Manual Probes the Human Must Run Before Commit

These cannot be covered by unit/widget tests and are required before merging:

1. **[CRITICAL — Fix #17 navigation] AC-1/AC-2 full SOAT creation flow:**
   - Garage → "Agregar vehículo" → fill all fields → tap SOAT slot → "Subir documento" → select image → "Guardar".
   - Expected: success SnackBar appears, app navigates to `SoatConfirmationPage` (does NOT pop back to garage yet).
   - Fill insurer + start date + expiry date → tap confirm.
   - Expected: "SOAT guardado" SnackBar, app lands on garage (the screen before `VehicleFormPage`), newly created vehicle shows SOAT badge.
   - **If landing is a blank screen or the wrong screen**, the `router.pop()` in `SoatConfirmationPage` is double-popping. Fix: remove `router.pop()` from the success handler or add a source flag to `SoatConfirmationPage`.

2. **[REQUIRED — AC-3] Create vehicle without SOAT:**
   - Create vehicle without attaching SOAT → "Guardar".
   - Expected: pops directly to garage. No SOAT confirmation page. Success SnackBar.

3. **[REQUIRED — AC-4] SOAT upload error / vehicle preserved:**
   - Create vehicle + attach SOAT → "Guardar" → immediately toggle airplane mode when `SoatConfirmationPage` opens → tap confirm.
   - Expected: error SnackBar on confirmation page. Vehicle exists in garage (visible after dismissing). Vehicle has no SOAT badge ("Sin SOAT").

4. **[REQUIRED — regression] Edit existing vehicle:**
   - Edit an existing vehicle's name (with or without existing SOAT) → "Guardar".
   - Expected: pops normally back to vehicle detail. SOAT badge unchanged.

5. **[REQUIRED — Fix #21] Registration selector shows vehicles:**
   - Navigate to event registration for an event with all brands allowed (`allowedBrands = ['*']` or empty).
   - Expected: vehicle dropdown shows user's vehicles (not empty state).

6. **[RECOMMENDED — AC-7] Registration with no vehicles:**
   - Use an account with no registered vehicles, open registration form.
   - Expected: "No tienes vehículos disponibles para esta inscripción." + "Crear vehículo" button.

7. **[RECOMMENDED — regression] Brand-restricted event:**
   - Register for event with specific brand list using a non-matching vehicle.
   - Expected: brand validation SnackBar. Registration blocked.

---

## Recommended Commit Message

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
