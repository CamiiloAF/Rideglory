> Slim handoff — read this before handoffs/architect.md

# Architect → QA — waiver-inscripcion-registro

**Backend stand-down:** no `rideglory-api` changes in this phase — Fases 1-2 of `legal-privacidad-edad` already delivered and tested `UNDERAGE_RIDER` (422). Do not add backend test scope.

## Commands

```bash
flutter test
flutter test test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart
flutter test test/features/event_registration/presentation/wizard/steps/registration_waiver_step_test.dart
flutter test test/features/event_registration/presentation/wizard/steps/registration_medical_step_test.dart
dart analyze
flutter gen-l10n
```

## Acceptance criteria traceability (PRD §5, 15 total)

| # | Criterion | Where to verify |
|---|-----------|------------------|
| 1 | 5-step wizard visible | `RegistrationWizardSteps.fieldsByStep.length == 5`; `registration_wizard_controller_test.dart` / `registration_step_indicator_test.dart` still pass unmodified; manual: `RegistrationStepIndicator` shows 5 dots |
| 2 | Privacy switches with subtitles | `registration_medical_step_test.dart` — exactly 2 `AppSwitchTile`, both `subtitle != null` |
| 3 | Correct defaults (create=false, edit=preloaded) | `registration_form_cubit_preload_test.dart` (existing) should still cover edit-mode preload since `_preloadFromExistingRegistration` already patches these — confirm it wasn't broken; new cubit test for create-mode default `false` |
| 4 | Waiver as last step, correct content, no nav bar | `registration_waiver_step_test.dart` widget test + manual |
| 5 | Cancel goes back to step 4 (vehicle), doesn't close page | `registration_waiver_step_test.dart` — `onBack` callback invoked, not `context.pop()` |
| 6 | Local age validation, no backend call | `registration_form_cubit_age_validation_test.dart` — age<18 via `birthDateOverrideForTesting` |
| 7 | `UNDERAGE_RIDER` backend error mapped to l10n | `registration_waiver_step_test.dart` — error containing `UNDERAGE_RIDER` shows `registration_underageTitle`/`Message`, not raw message |
| 8 | Missing `birthDate` → profile action | `registration_form_cubit_age_validation_test.dart` (cubit emits) + `registration_waiver_step_test.dart` (button + navigation) |
| 9 | `riskAcceptedAt`/`riskAcceptanceVersion` in payload | `registration_form_cubit_age_validation_test.dart` — assert on built `EventRegistrationModel` via `buildRegistrationOverride` seam or direct `_buildRegistration` exercise |
| 10 | `shareMedicalInfo`/`allowOrganizerContact` in payload | Same test as #9 |
| 11 | Vehicle-brand validation preserved (CTA → `onSubmit`, not direct cubit call) | `registration_waiver_step_test.dart` — verify `onSubmit` callback wiring, not a new direct cubit call path |
| 12 | Analytics `registrationStepAdvanced` step_index=4/step_name='waiver' when advancing from vehicle step | Extend `registration_form_cubit_analytics_test.dart` pattern or new test asserting `_stepNameFor(4) == 'waiver'` |
| 13 | `event.ownerName` null handled, no crash | `registration_waiver_step_test.dart` — pump with `ownerName: null`, expect no `Text` for owner name and no exception |
| 14 | No hardcoded strings, no dead ARB keys | Manual grep of new files for string literals in UI; confirm `registration_goToProfile` is actually wired to a button (not dead) |
| 15 | `dart analyze` clean | CI command above |

## Regression watch-list (not new acceptance criteria, but must not break)

- `registration_wizard_controller_test.dart` and `registration_step_indicator_test.dart` — should pass unmodified (they read `stepCount` generically, no hardcoded `4`).
- `registration_form_cubit_preload_test.dart` — edit-mode preload of the two booleans was already implemented pre-phase; confirm no regression.
- `registration_form_cubit_analytics_test.dart` — existing step-advance/back analytics tests must still pass; new step index 4 is additive.
- Full registration flow (create + edit) end-to-end — wizard now has 5 steps instead of 4; any Patrol/manual script assuming 4 steps needs updating.

## Known frailty (documented risk, not a bug)

`error.message.contains('UNDERAGE_RIDER')` is a string-contains check against the backend's literal error message — brittle if the backend ever changes wording, but acceptable given no real users yet (per project memory). Flag it in review, don't block on it.

> Full detail: handoffs/architect.md
