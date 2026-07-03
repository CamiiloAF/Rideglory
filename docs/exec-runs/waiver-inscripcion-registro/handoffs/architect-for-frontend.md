> Slim handoff — read this before handoffs/architect.md

# Architect → Frontend — waiver-inscripcion-registro

**No backend work in this phase.** All 5 flags: uiChanges=true, backendChanges=false, frontendChanges=true, dbChanges=false, needsDesign=false.

## IMPORTANT — already done, do NOT redo

Before starting, re-verify these (they were true as of this handoff, code moves fast):
- `RegistrationFormFields.shareMedicalInfo` and `.allowOrganizerContact` **already exist** in `lib/features/event_registration/constants/registration_form_fields.dart`. Only add the 5th empty list `<String>[]` to `RegistrationWizardSteps.fieldsByStep`.
- `EventRegistrationModel` already has `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion` (with `copyWith`).
- `EventRegistrationDto`/`EventRegistrationModelExtension.toJson()` already serialize all 4 legal fields — you don't touch the DTO.
- `RegistrationFormCubit._preloadFromExistingRegistration()` **already** patches `shareMedicalInfo`/`allowOrganizerContact` for edit mode — don't add it again.
- What's genuinely missing in the cubit: the age guard in `saveRegistration()`, `_calculateAge()`, the `birthDateOverrideForTesting` seam, and passing the 4 legal fields inside `_buildRegistration()`'s `EventRegistrationModel(...)` constructor call (today it doesn't pass them, so they always travel with default `false`/`null`).

## Files to touch (see architect.md Change map for full detail)

1. `lib/l10n/app_es.arb` — add 14 keys (`registration_privacySectionTitle`, `registration_shareMedicalInfoTitle/Subtitle`, `registration_allowContactTitle/Subtitle`, `registration_waiverTitle/Subtitle/BodyV0/CtaButton/CancelButton`, `registration_underageTitle/Message`, `registration_missingBirthDateMessage`, `registration_goToProfile`). Run `flutter gen-l10n` after.
2. `lib/core/services/analytics/analytics_params.dart` — add `static const String stepNameWaiver = 'waiver';`.
3. `lib/features/event_registration/constants/registration_form_fields.dart` — add `<String>[]` as 5th element of `fieldsByStep` (waiver has no FormBuilder fields).
4. `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart`:
   - Age guard at the **top of `saveRegistration()`**, before `_buildRegistration()` is called: read `birthDate` from `formKey.currentState!.value` (or `birthDateOverrideForTesting` if set) — if null, emit `DomainException(message: 'Debes ingresar tu fecha de nacimiento para continuar.')` and return; if `_calculateAge(birthDate) < 18`, emit `DomainException(message: 'Debes tener al menos 18 años para inscribirte en una rodada.')` and return.
   - `int _calculateAge(DateTime birthDate)` — year/month/day comparison (see architect.md full detail for exact snippet, matches backend's algorithm shape).
   - `@visibleForTesting DateTime? birthDateOverrideForTesting` — production code never sets it.
   - In `_buildRegistration()`'s final `EventRegistrationModel(...)`, add: `shareMedicalInfo: formData[RegistrationFormFields.shareMedicalInfo] as bool? ?? false`, `allowOrganizerContact: formData[RegistrationFormFields.allowOrganizerContact] as bool? ?? false`, `riskAcceptedAt: DateTime.now()`, `riskAcceptanceVersion: 'v0.1-2026-06'`.
5. `lib/features/event_registration/presentation/wizard/steps/registration_medical_step.dart` — append after `RegistrationBloodTypeSelector`: `AppSpacing.gapLg`, `ProfileFormSectionHeader(label: context.l10n.registration_privacySectionTitle)` (import from `lib/features/profile/presentation/widgets/profile_form_section_header.dart`), `AppSpacing.gapSm`, then 2 `AppSwitchTile` (`shareMedicalInfo`, `allowOrganizerContact`), both with **non-null `subtitle`** (WCAG requirement, non-negotiable), `initialValue: false`.
6. **New file** `lib/features/event_registration/presentation/wizard/steps/registration_waiver_step.dart` — `RegistrationWaiverStep` (single widget, single file). Constructor: `{required EventModel event, required VoidCallback onSubmit, required VoidCallback onBack}`. `BlocBuilder<RegistrationFormCubit, ResultState<EventRegistrationModel>>` wraps the whole `Column`. Contents in order: `RegistrationStepHeader(icon, title: registration_waiverTitle, subtitle: registration_waiverSubtitle)` (subtitle is `required` — do not touch that widget's constructor); conditional `Text(event.ownerName!)` only `if (event.ownerName != null)`; `ConstrainedBox(maxHeight: 280) + SingleChildScrollView` wrapping `Text(registration_waiverBodyV0)` — **never `Expanded`** (the `IndexedStack` lives inside an unbounded `SingleChildScrollView` in the parent, `Expanded` will throw); inline error block (see below); `AppButton` CTA (`onPressed: isLoading ? null : onSubmit`); `AppTextButton` Cancel (`onPressed: onBack`).
7. `lib/features/event_registration/presentation/registration_form_content.dart`:
   - Import the new step.
   - Add `RegistrationWaiverStep(event: widget.event, onSubmit: _submitRegistration, onBack: _onBack)` as the 5th child of the `IndexedStack` (index 4).
   - Add `AnalyticsParams.stepNameWaiver` at index 4 in `_stepNameFor()`.
   - Wrap the existing `BlocBuilder<RegistrationFormCubit, ...>` that renders `RegistrationWizardNavigationBar` with `if (!_wizard.isLastStep) BlocBuilder(...)`. Do **not** add a new param to `RegistrationWizardNavigationBar` itself.

## Error mapping in `RegistrationWaiverStep` (exact logic)

```dart
final errorOrNull = state.mapOrNull(error: (e) => e.error);
final isUnderage = errorOrNull != null && errorOrNull.message.contains('UNDERAGE_RIDER');
final isMissingBirthDate = errorOrNull != null && errorOrNull.message.contains('fecha de nacimiento');
```
- `isUnderage` → show `registration_underageTitle` (bold, error color) + `registration_underageMessage` (never the raw server message); no "Ir a mi perfil" button.
- `isMissingBirthDate` → show `errorOrNull.message` as-is + `AppTextButton(label: registration_goToProfile, onPressed: () => context.pushNamed(AppRoutes.editProfile))`. `AppRoutes.editProfile = '/profile/edit'` already exists and is named — confirmed.
- Any other error → show `errorOrNull.message` as-is, no title, no profile button.

Document in your handoff which exact strategy you used for the `isMissingBirthDate` substring match (raw string `.contains('fecha de nacimiento')` vs. a shared `@visibleForTesting` constant on the cubit — either is acceptable, pick one and say why).

## Hard guardrails (zero tolerance)

- Never call `context.pop()` or a cubit method directly from the waiver's Cancel button — only `onBack`.
- Never call `cubit.saveRegistration()` directly from the waiver's CTA — only `onSubmit` (preserves the vehicle-brand validation in `_submitRegistration()`).
- Never `Expanded` inside `RegistrationWaiverStep`.
- Never `Switch`/`SwitchListTile`/`FormBuilderSwitch`/`CupertinoSwitch` — only `AppSwitchTile`.
- No hardcoded UI strings — everything via `context.l10n`.
- Don't touch `app_router.dart`, `registration_wizard_controller.dart`, `registration_step_indicator.dart`, or `RegistrationWizardNavigationBar`'s own constructor.

## Tests to write (see architect.md for full detail)

- `test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart` — age<18 local reject, age=18 exact passes, missing birthDate local reject, legal fields present in built registration, backend `UNDERAGE_RIDER` passed through unchanged.
- `test/features/event_registration/presentation/wizard/steps/registration_waiver_step_test.dart` — render, nullable owner, loading state, 3 error branches, callback wiring.
- `test/features/event_registration/presentation/wizard/steps/registration_medical_step_test.dart` — exactly 2 `AppSwitchTile`, both with non-null subtitle.

> Full detail: handoffs/architect.md
