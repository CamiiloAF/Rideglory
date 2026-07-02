> Slim handoff — read this before `handoffs/architect.md`

# Frontend — legal-privacidad-edad-fase3

**No backend work, no migrations, no UI screens.** Pure domain/data model + DTO extension in Flutter, plus 3 one-line fixes forced by a type change. Contracts already closed in Fase 1 — verified against `rideglory-api` (see `handoffs/architect.md` § Contratos), do not touch `rideglory-api`.

## Order (do not skip steps or reorder — later files depend on earlier ones compiling)

1. `lib/features/event_registration/domain/model/event_registration_model.dart`
2. `lib/features/event_registration/data/dto/event_registration_dto.dart`
3. `lib/features/events/domain/model/event_model.dart`
4. `lib/features/events/data/dto/event_dto.dart`
5. `lib/features/users/domain/model/user_model.dart`
6. `lib/features/users/data/dto/user_dto.dart`
7. `dart run build_runner build --delete-conflicting-outputs`
8. `lib/features/event_registration/constants/registration_form_fields.dart`
9. `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart`
10. `lib/features/event_registration/presentation/registration_detail_page.dart`
11. `dart analyze` (0 errors)
12. New tests (below)
13. `flutter test`

## 1 — `event_registration_model.dart`

Add 4 fields to `EventRegistrationModel`, all in the constructor + `copyWith`:
- `shareMedicalInfo` — `bool`, default `false` (`this.shareMedicalInfo = false`)
- `allowOrganizerContact` — `bool`, default `false`
- `riskAcceptedAt` — `DateTime?`
- `riskAcceptanceVersion` — `String?`

Change `bloodType` from `required this.bloodType` (type `BloodType`) to `final BloodType? bloodType;` (still `required this.bloodType` in the constructor — just nullable now, not optional-positional). Update `copyWith` param type to `BloodType?` (already was, since `copyWith` params are always nullable — just make sure the field assignment still uses `bloodType ?? this.bloodType`, unchanged pattern).

## 2 — `event_registration_dto.dart`

Add the 4 new fields to `EventRegistrationDto`'s constructor (mirror `EventRegistrationModel`, using `super.xxx`). Add `@_BloodTypeConverter()` **on the `bloodType` field itself** inside the constructor (field-level annotation), not on the class — the class already has `@_VehicleSummaryConverter()` at class level for a different field; do not remove or touch that one.

Define `_BloodTypeConverter` in the same file:
```dart
class _BloodTypeConverter implements JsonConverter<BloodType?, String?> {
  const _BloodTypeConverter();

  @override
  BloodType? fromJson(String? json) {
    if (json == null) return null;
    for (final value in BloodType.values) {
      // Match the exact @JsonValue string, never a derived/uppercased name.
      if (_jsonValueOf(value) == json) return value;
    }
    return null;
  }

  @override
  String? toJson(BloodType? value) => value == null ? null : _jsonValueOf(value);
}
```
`_jsonValueOf` needs the exact 8 `@JsonValue` strings from `event_registration_model.dart` (`A_POSITIVE`, `A_NEGATIVE`, `B_POSITIVE`, `B_NEGATIVE`, `AB_POSITIVE`, `AB_NEGATIVE`, `O_POSITIVE`, `O_NEGATIVE`) — hardcode a `switch` mapping `BloodType` → these strings (do not derive from `.name`). **Never** fall back to `bt.name.toUpperCase()` — that produces false positives (guardrail from PRD).

Update `EventRegistrationModelExtension.toJson()` to pass through the 4 new fields into the `EventRegistrationDto(...)` constructor call (this is the actual fix for C1 — silent drop of legal fields on write).

## 3 — `event_model.dart`

Add `organizerAcceptedResponsibilityAt` and `sosTriggeredAt`, both `DateTime?`, to `EventModel` (constructor + `copyWith`). No new getters needed.

## 4 — `event_dto.dart`

Add both fields to `EventDto`'s constructor as `super.xxx` — JSON key names already match 1:1 (`organizerAcceptedResponsibilityAt`, `sosTriggeredAt`), no `@JsonKey(name:)` needed (unlike `createdDate`/`updatedDate` which map to `createdAt`/`updatedAt` — don't copy that pattern here). Add both to `EventModelExtension.toJson()`. Both fields already fall under `converters: apiJsonDateTimeConverters` at the class level (nullable `DateTime`), no extra converter work needed.

## 5 — `user_model.dart`

Add `medicalConsentAcceptedAt` (`DateTime?`) to `UserModel` constructor. **`UserModel` has no `copyWith` today** — add one from scratch covering all 14 existing fields plus this new one (do not add a partial one). Standard pattern: nullable-param + `field ?? this.field` for every field, same as `EventRegistrationModel.copyWith` or `RiderProfileModel.copyWith` (both in this repo) for reference style.

## 6 — `user_dto.dart`

Add `medicalConsentAcceptedAt` to `UserDto`'s constructor as `super.medicalConsentAcceptedAt`. **No custom converter** — standard `json_serializable` handles it via the class-level `apiJsonDateTimeConverters`. Add it to `UserModelExtension.toJson()`.

## 8 — `registration_form_fields.dart`

Add 2 constants only:
```dart
static const String shareMedicalInfo = 'shareMedicalInfo';
static const String allowOrganizerContact = 'allowOrganizerContact';
```
Do **not** add these to `RegistrationWizardSteps.fieldsByStep` — that's wizard UI validation, out of scope (Fases 4/5/6).

## 9 — `registration_form_cubit.dart`

Two changes only:
- `_preloadFromExistingRegistration`: add to the `patchValue` map (unconditionally, no `if != null` guard — both are non-nullable bools with defaults):
```dart
RegistrationFormFields.shareMedicalInfo: existingRegistration.shareMedicalInfo,
RegistrationFormFields.allowOrganizerContact: existingRegistration.allowOrganizerContact,
```
- `_buildRegistration`: change `bloodType: formData[RegistrationFormFields.bloodType] as BloodType,` → `bloodType: formData[RegistrationFormFields.bloodType] as BloodType?,`

Do **not** touch `_buildRiderProfile`, `preloadFromRiderProfile`, `_prefillFromAuthenticatedUser` — none of them need changes (RiderProfileModel.bloodType was already `BloodType?`; the new booleans/risk fields aren't part of RiderProfileModel/rider-profile preload flow this phase).

## 10 — `registration_detail_page.dart`

Line 128 only:
```dart
value: registration.bloodType.label,
```
→
```dart
value: registration.bloodType?.label ?? '',
```

## New tests

Follow the existing style in `test/features/tecnomecanica/data/dto/tecnomecanica_dto_test.dart` (Pattern B fromJson/toJson groups, `TC-xxx-NN` naming).

- `test/features/event_registration/data/dto/event_registration_dto_test.dart`:
  - AC#1: construct `EventRegistrationModel` with only required fields → assert `shareMedicalInfo == false`, `allowOrganizerContact == false`, `riskAcceptedAt == null`, `riskAcceptanceVersion == null`.
  - AC#2: `EventRegistrationDto.fromJson({'bloodType': '__NOT_SHARED__', ...})` → `bloodType == null`, no exception. Same with `'••••'` → `null`. Same with `'A_POSITIVE'` → `BloodType.aPositive`. Build a minimal valid JSON fixture with all other required fields present (see existing model's required fields).
  - AC#3: build model with `shareMedicalInfo: true, allowOrganizerContact: false, riskAcceptedAt: DateTime(2026, 6, 19), riskAcceptanceVersion: 'v0.1-2026-06'`, call `.toJson()` (the extension), assert the 4 keys are present with exact values.
- `test/features/events/data/dto/event_dto_test.dart`:
  - AC#4: `EventDto.fromJson()` with ISO-8601 strings for both new fields → correct non-null `DateTime?`, no exception. Also test both absent → both `null`.
- `test/features/users/data/dto/user_dto_test.dart`:
  - AC#5: `UserDto.fromJson()` with `medicalConsentAcceptedAt` present (ISO string) and absent → correct `DateTime?` in both cases, no exception.

## Guardrails (do not violate)

- Do not touch `registration_service.dart`, `event_registration_repository_impl.dart`, `rider_profile_repository_impl.dart`, `rider_profile_model.dart`, `edit_profile_page.dart` — none are in scope.
- Do not add `bloodTypeRaw` or any `String?` fallback field.
- Do not copy `_BloodTypeConverter` into `UserDto`/`UserModel`.
- `grep -rn '\.bloodType\b' lib/` after your changes — every result outside the model/DTO definition itself must use `?.` or an explicit null check (AC#9). The only non-null-safe call site today is `registration_detail_page.dart:128`, already covered in step 10.

## Verification before done

```
dart run build_runner build --delete-conflicting-outputs
dart analyze
flutter test test/features/event_registration/data/dto/event_registration_dto_test.dart test/features/events/data/dto/event_dto_test.dart test/features/users/data/dto/user_dto_test.dart
flutter test test/features/event_registration test/features/events test/features/users   # full-feature regression
```

> Full detail / contract verification against `rideglory-api`: `handoffs/architect.md`
