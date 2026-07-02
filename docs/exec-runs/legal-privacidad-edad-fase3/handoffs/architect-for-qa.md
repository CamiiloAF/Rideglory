> Slim handoff — read this before handoffs/architect.md

# QA — legal-privacidad-edad-fase3

Flutter-only phase (domain/data models + DTOs), no UI screens, no Patrol e2e needed — all criteria are unit-testable.

## Commands
```
dart run build_runner build --delete-conflicting-outputs
dart analyze
flutter test test/features/event_registration/data/dto/event_registration_dto_test.dart
flutter test test/features/events/data/dto/event_dto_test.dart
flutter test test/features/users/data/dto/user_dto_test.dart
flutter test test/features/event_registration test/features/events test/features/users   # regression
```

## Acceptance criteria traceability (PRD §5, 10 total)

| # | Criterion | Covered by |
|---|-----------|-----------|
| 1 | `EventRegistrationModel` defaults: `shareMedicalInfo=false`, `allowOrganizerContact=false`, `riskAcceptedAt=null`, `riskAcceptanceVersion=null` when only required fields set | `event_registration_dto_test.dart` (model-level test) |
| 2 | `bloodType` is `BloodType?`; `fromJson` tolerant to `'__NOT_SHARED__'` → `null`, `'••••'` → `null`, `'A_POSITIVE'` → `BloodType.aPositive` | `event_registration_dto_test.dart` |
| 3 | `EventRegistrationModelExtension.toJson()` includes the 4 new fields with correct values | `event_registration_dto_test.dart` |
| 4 | `EventDto.fromJson()` deserializes `organizerAcceptedResponsibilityAt`/`sosTriggeredAt` from ISO-8601 strings, no exception | `event_dto_test.dart` |
| 5 | `UserDto.fromJson()` deserializes `medicalConsentAcceptedAt` with field present and absent, correct `DateTime?` both times | `user_dto_test.dart` |
| 6 | `RegistrationFormFields.shareMedicalInfo == 'shareMedicalInfo'`, `.allowOrganizerContact == 'allowOrganizerContact'` | quick assertion in `event_registration_dto_test.dart` or a small constants test — either is acceptable |
| 7 | `dart analyze` → 0 errors | CI/manual command above |
| 8 | `dart run build_runner build --delete-conflicting-outputs` completes without conflicts; 3 `.g.dart` files updated | CI/manual command above — check `git status` shows the 3 `.g.dart` files modified |
| 9 | No production code accesses `registration.bloodType` as non-nullable `BloodType` — `grep -rn '\.bloodType\b' lib/` shows only `?.`/null-checked usages; `registration_detail_page.dart:128` uses `?.label ?? ''` | manual grep + code review |
| 10 | `_buildRiderProfile` assigns `reg.bloodType` (`BloodType?`) to `RiderProfileModel.bloodType` (`BloodType?`) without a type error | implied by AC#7 (`dart analyze` passing) — no dedicated test needed |

## Regression watch
- Any existing test constructing `EventRegistrationModel`/`EventRegistrationDto` with a `bloodType:` argument should keep compiling and passing (nullability relaxed, not removed).
- `RegistrationFormCubit` tests (`test/features/event_registration/presentation/cubit/*`) — confirm none assert `formData[...] as BloodType` behavior in a way broken by the `BloodType?` cast change.
- `EventDetailCubit`/`EventModel` tests — the 2 new nullable fields must not change any existing getter behavior (`isFree`, `meetingPoint`, `destination`, `isMultiBrand`, `isMultiDay`).
- `UserModel` — confirm no other code assumed `UserModel` had no `copyWith` (unlikely, but check for compile-time ambiguity if a `copyWith` extension existed elsewhere — none found in the current codebase scan).

> Full detail: handoffs/architect.md
