# Review Checklist — fix-issues-17-21

## Phase chain

| Phase | Agent | Completed at |
|-------|-------|-------------|
| po | po | 2026-05-22T21:40:00Z |
| architect | architect | 2026-05-22T22:10:00Z |
| frontend | frontend | 2026-05-22T23:00:00Z |
| qa | qa | 2026-05-22T23:45:00Z |
| tech_lead | tech_lead | 2026-05-22T23:55:00Z |
| po_close | po | 2026-05-22T23:59:00Z |

---

## Automated gates (already passed)

- [x] `dart analyze`: 0 new issues in changed/new files (45 pre-existing, unchanged)
- [x] `flutter test`: 119/119 passing (108 baseline + 11 new)
- [x] One-widget-per-file: all 3 new widget files verified (`VehicleSelectorLoading`, `VehicleSelectorEmpty`, `VehicleSelectorField`)
- [x] No hardcoded strings: all user-visible text uses `context.l10n.*`
- [x] No Widget-returning methods: all UI in `build()` only
- [x] `ResultState.when()` all 5 branches covered in `BlocBuilder` refactor
- [x] HARD RULES: no commits made, no protected files touched

---

## Files changed

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
  test/features/event_registration/presentation/widgets/  (3 test files)
  test/features/vehicles/presentation/cubit/vehicle_form_cubit_soat_test.dart
```

---

## Manual probes (you must run these on device/simulator before committing)

### Fix #17 — SOAT saved after vehicle creation

- [ ] **[CRITICAL — AC-1/AC-2] Happy path with SOAT:**
  Garage → "Agregar vehículo" → fill all required fields → tap SOAT section → "Subir documento" → pick any gallery image → "Guardar".
  Expected: success SnackBar appears, app navigates to `SoatConfirmationPage` (does NOT pop to garage yet).
  Fill insurer, start date, expiry date → tap confirm.
  Expected: "SOAT guardado" SnackBar → app lands on garage → newly created vehicle shows SOAT badge (Vigente / Por vencer / Vencido), NOT "Sin SOAT".

- [ ] **[REQUIRED — AC-3] Create vehicle WITHOUT SOAT — no regression:**
  Create vehicle without attaching any document → "Guardar".
  Expected: pops directly back to garage with success SnackBar. No `SoatConfirmationPage` appears.

- [ ] **[REQUIRED — regression] Edit existing vehicle — no redirect triggered:**
  Edit an existing vehicle's name (with or without existing SOAT) → "Guardar".
  Expected: pops normally back to vehicle detail. SOAT badge unchanged. No `SoatConfirmationPage` appears.

- [ ] **[REQUIRED — AC-4] SOAT upload error — vehicle preserved:**
  Create vehicle + attach SOAT → "Guardar" → when `SoatConfirmationPage` opens, enable airplane mode → tap confirm.
  Expected: error SnackBar on confirmation page. Vehicle exists in garage after dismissing (no SOAT badge, but vehicle is not lost).

  > **Navigation double-pop watchpoint (Tech Lead finding #2):** On step "app lands on garage" above — if the screen is blank or shows the wrong screen, `SoatConfirmationPage.success` is double-popping via `Navigator.pop()` + `router.pop()`. Remediation: remove `router.pop()` from `SoatConfirmationPage`'s success handler, or add a source flag to skip the second pop when reached via `Navigator.pushReplacement`.

### Fix #21 — Vehicle selector in registrations

- [ ] **[REQUIRED — AC-5] Event with `allowedBrands = ['*']`:**
  Open registration form for an event that allows all brands.
  Expected: vehicle selector shows all non-archived user vehicles — NOT the empty state.

- [ ] **[REQUIRED — AC-6] Loading spinner:**
  Navigate to registration form before `VehicleCubit` finishes loading (deep link or very fast navigation from splash).
  Expected: `CircularProgressIndicator` visible in vehicle section while loading; dropdown appears once state becomes `data`.
  *(Hard to reproduce manually — widget test TC-vsel-1/2/3 is the primary coverage. Run if deep-link test is feasible.)*

- [ ] **[REQUIRED — AC-7] Real empty state (zero vehicles):**
  With an account that has no registered vehicles, open a registration form.
  Expected: "No tienes vehículos disponibles para esta inscripción." + "Crear vehículo" button visible.

### Regression checks (pre-existing fixes on same branch)

- [ ] **Fix #20 regression:** Open events list → filter by event type → verify events filter correctly without 400 error.

- [ ] **Fix #16 regression:** Create new vehicle → tap SOAT card → verify options sheet appears (not a direct file picker).

- [ ] **Brand-restricted event regression:**
  Attempt to register for an event with specific allowed brands using a vehicle of a non-allowed brand.
  Expected: brand validation error message shown, registration blocked.

---

## Optional follow-ups (not blocking this commit)

- `soat_confirmation_page.dart` contains multiple private widget classes (`_FormSectionHeader`, `_SoatFormFields`) — pre-existing one-widget-per-file violation from iter-2, out of scope here. Open a separate bug if desired.
- If the navigation double-pop probe fails: the remediation is to remove `router.pop()` from `SoatConfirmationPage.success` or add a `navigatedViaReplacement` boolean parameter. This would require a targeted follow-up fix before committing.

---

## Decision

- [ ] All probes passed → commit with recommended message below
- [ ] Issues found → `git restore .` to discard changes + delete workspace + re-run

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
