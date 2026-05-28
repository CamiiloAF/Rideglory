# QA handoff — DTO inheritance standard refactor

**Agent:** QA  
**Date:** 2026-05-28  
**PRD:** prd-dto-inheritance-standard  
**Status:** done

---

## Test catalog

| AC | Description | Tests | Type | Result |
|----|-------------|-------|------|--------|
| AC-1 | `VehicleDto.toModel()` deleted; `home_dto.dart` updated; `vehicle_repository_impl.dart` line 27 no longer calls `.toModel()` | grep guardrail: zero hits in vehicles/home | Static grep | PASS |
| AC-2 | `UserDto.fromModel()` deleted; `UserModelExtension.toJson()` exists | Code inspection `user_dto.dart` | Code review | PASS |
| AC-3 | `MaintenanceDto` extends `MaintenanceModel`; `@JsonKey(name: 'createdAt'/'updatedAt')` applied; `fromModel()`/`toModel()` deleted; `MaintenanceModelExtension.toJson()` present | Code inspection `maintenance_dto.dart` + `maintenance_dto.g.dart` | Code review + wire-format check | PASS |
| AC-4 | `maintenance_repository_impl.dart` no longer calls `.map((dto) => dto.toModel())` or `MaintenanceDto.fromModel()` | grep guardrail on maintenance/ (only `summary.toModel()` exception remains) | Static grep | PASS (exception expected) |
| AC-5 | `create_maintenance_response_dto.dart` uses `List<MaintenanceModel>.from(created)` | Code inspection | Code review | PASS |
| AC-6 | `VehicleSummaryDto` extends `VehicleSummaryModel`; `toModel()` deleted; `VehicleSummaryModelExtension.toJson()` present | Code inspection `vehicle_summary_dto.dart` | Code review | PASS |
| AC-7 | `EventRegistrationDto` extends `EventRegistrationModel`; `toModel()` and `toDto()` deleted; `EventRegistrationModelExtension.toJson()` present; `birthDate` override preserved; `vehicleSummary` typed as `VehicleSummaryModel?` | Code inspection `event_registration_dto.dart` | Code review | PASS |
| AC-8 | `event_registration_repository_impl.dart` no longer calls `.toModel()` or `.toDto().toJson()` | grep guardrail on event_registration/ | Static grep | PASS |
| AC-9 | `soat/SoatDto` extends `soat/SoatModel`; `toModel()` deleted; `SoatModelToRequest.toRequestJson()` preserved; `soat_repository_impl.dart` clean | Code inspection `soat/soat_dto.dart` + grep | Code review + grep | PASS |
| AC-10 | `soat_repository_impl.dart` uses direct DTO assignment | Code inspection — no `toModel()` hits | Static grep | PASS |
| AC-11 | `dart analyze` passes with zero new violations | `dart analyze`: 0 errors, 0 warnings, 45 info (all pre-existing) | Static analysis | PASS |
| AC-12 | `flutter test` passes 100% | Exit code 0; 119 tests pass, 0 fail | Automated tests | PASS |
| AC-13 | `rideglory-coding-standards.mdc` updated with Pattern B section | Section "DTOs — Patrón obligatorio (Patrón B)" present at line 199 | Code review | PASS |
| AC-14 | `CLAUDE.md` updated to reflect Pattern B | Line 86 updated; line 126 updated | Code review | PASS |
| AC-15 | Each migrated DTO has a single `.g.dart`; no orphaned files | build_runner: 16 outputs; all `.g.dart` found via find | Build output | PASS |

---

## Regression matrix

| Guardrail | Mechanism | Result |
|-----------|-----------|--------|
| `VehicleDto.toModel()` removal — home_dto.dart + vehicle_repository_impl.dart | `grep -rn "\.toModel()" lib/features/vehicles/ lib/features/home/` | PASS — only hits are `vehicles/soat_dto.dart` (deferred, expected) and `vehicle_repository_impl.dart` lines 113/123 (SOAT methods using deferred dto) |
| `MaintenanceDto` migration — repository call sites | `grep -rn "MaintenanceDto\.fromModel\|\.toModel()" lib/features/maintenance/` | PASS — only hit is `vehicle_maintenances_list_response_dto.dart:23 MaintenanceListSummaryDto.toModel()`, which is the documented composite-wrapper exception |
| `EventRegistrationDto` — call site cleanup | `grep -rn "\.toDto()\|\.toModel()" lib/features/event_registration/` | PASS — zero hits |
| `soat/SoatDto` — call site cleanup | `grep -rn "\.toModel()" lib/features/soat/` | PASS — zero hits |
| `UserDto.fromModel` removal | `grep -rn "UserDto\.fromModel" lib/features/users/` | PASS — zero hits |
| Code generation clean | `dart run build_runner build --delete-conflicting-outputs` | PASS (per Frontend handoff: 16 outputs, no conflicts) |
| `dart analyze` | `dart analyze` — zero errors | PASS — 0 errors, 0 warnings |
| Existing tests not broken | `flutter test` exit code 0 | PASS — 119 pass, 0 fail |
| `VehicleDto.toModel()` grep note | `vehicles/soat_dto.dart` still has `.toModel()` — this is the DEFERRED DTO (explicitly out of scope per PRD §8 and architect notes) | EXPECTED — not a failure |
| `vehicle_repository_impl.dart` lines 113/123 | These call `dto.toModel()` on `vehicles/SoatDto` (the deferred Pattern A dto). Will be cleaned when that DTO is migrated. | EXPECTED — not a failure |

---

## Test execution

```bash
# Static analysis
dart analyze
# Result: 45 issues found. Exit code 2 (issues present).
# Breakdown: 0 errors, 0 warnings, 45 info-level only.
# All 45 are pre-existing (36 deprecated_member_use in integration_test/,
# 1 dead_code + 1 prefer_const_declarations in api_base_url_resolver.dart pre-existing dirty file,
# 1 prefer_null_aware_operators in event_registration_dto.dart,
# 6 prefer_const_constructors in test files).
# Zero new violations introduced by this iteration.

# Unit + widget tests
flutter test
# Exit code: 0
# Tests: 119 passed, 0 failed (142 total events; 23 are hidden framework tests)
# Test files: 21 files across authentication, event_registration, events, maintenance,
#             notifications, profile, soat, users, vehicles, shared/widgets
```

---

## Wire-format spot-checks

| DTO file | Check | Expected | Actual (from .g.dart) | Result |
|----------|-------|----------|----------------------|--------|
| `maintenance_dto.g.dart` | `_$MaintenanceDtoFromJson` reads `createdAt` key → `createdDate` field | `json['createdAt']` | `createdDate: NullableApiDateTimeConverter().fromJson(json['createdAt'])` | PASS |
| `maintenance_dto.g.dart` | `_$MaintenanceDtoFromJson` reads `updatedAt` key → `updatedDate` field | `json['updatedAt']` | `updatedDate: NullableApiDateTimeConverter().fromJson(json['updatedAt'])` | PASS |
| `maintenance_dto.g.dart` | `_$MaintenanceDtoToJson` writes key `createdAt` (not `createdDate`) | `'createdAt': ...` | `'createdAt': NullableApiDateTimeConverter().toJson(instance.createdDate)` | PASS |
| `maintenance_dto.g.dart` | `_$MaintenanceDtoToJson` writes key `updatedAt` (not `updatedDate`) | `'updatedAt': ...` | `'updatedAt': NullableApiDateTimeConverter().toJson(instance.updatedDate)` | PASS |
| `event_registration_dto.g.dart` | `vehicleSummary` deserialized via `_VehicleSummaryConverter.fromJson` (returns `VehicleSummaryDto`) | `_VehicleSummaryConverter().fromJson(...)` | `const _VehicleSummaryConverter().fromJson(json['vehicleSummary'] as Map<String, dynamic>?)` | PASS |
| `event_registration_dto.dart` | `birthDate` override in `toJson()` calls `apiEncodeRequiredDateTime` | Custom override preserved | `json['birthDate'] = apiEncodeRequiredDateTime(birthDate)` verbatim | PASS |
| `soat_dto.g.dart` (soat feature) | `expiryDate` read as required `DateTime` via `DateTime.parse` | `DateTime.parse(json['expiryDate'])` | `expiryDate: DateTime.parse(json['expiryDate'] as String)` | PASS |
| `soat_dto.g.dart` (soat feature) | No `?? DateTime.now()` fallback | absent | Not present | PASS |
| `vehicle_summary_dto.g.dart` | Fields `id`, `brand`, `model`, `licensePlate`, `vin` with correct nullability | `id` required; rest nullable | `id: json['id'] as String; brand/model/licensePlate/vin as String?` | PASS |
| `user_dto.g.dart` | Key set unchanged from pre-refactor (only `fromModel()` removed; codegen unchanged) | Same key set | All original keys present: id, fullName, email, identificationNumber, birthDate, phone, residenceCity, eps, medicalInsurance, bloodType, emergencyContactName, emergencyContactPhone, isDeleted, createdAt, updatedAt | PASS |
| `vehicle_dto.g.dart` | Key set unchanged (only redundant `toModel()` removed) | Same key set | All original keys present; no new/missing keys | PASS |

All 6 architect-specified wire-format checks: **PASS**.

---

## Bugs found

None. The refactor is a zero-behavior-change migration. All static and dynamic checks pass. The only observations are:

1. **Observation (not a bug):** `vehicles/soat_dto.dart` still has `toModel()` — this is the deferred DTO per PRD §8. `vehicle_repository_impl.dart` lines 113 and 123 still call `.toModel()` on this deferred DTO. Both are expected and documented.
2. **Observation (not a bug):** `vehicle_maintenances_list_response_dto.dart` line 23 has `MaintenanceListSummaryDto.toModel()` — this is the documented composite-wrapper exception per architect notes.
3. **Out-of-scope dirty file:** `api_base_url_resolver.dart` has a developer toggle forcing local API (`final shouldUseLocalApi = true`). This was pre-existing before the iteration and was NOT touched by the frontend agent. **Human must decide whether to revert to `remoteBaseUrl.isEmpty` before merging to main.**

---

## Manual probes for human

The following require launching the app on simulator/device. They cannot be covered by automated tests in this codebase:

| # | Flow | What to verify | Risk if broken |
|---|------|---------------|----------------|
| MP-1 | **Maintenance create** — create a maintenance record for a vehicle | List reloads and shows the new entry; `_buildCreateBody` + `maintenance.toJson()` produce correct payload | `MaintenanceDto` wire-format regression |
| MP-2 | **Maintenance update** — edit an existing maintenance record, save | Changes persist in list; `maintenance.toJson()` extension produces correct update payload | `MaintenanceModelExtension.toJson()` regression |
| MP-3 | **Event registration create** — register for an event with a vehicle selected | Registration saved; `vehicleSummary` field round-trips correctly | `_VehicleSummaryConverter` + nested DTO deserialization |
| MP-4 | **My registrations list** — open registrations list | All rows render without crash | Repository drop-`.toModel()` change |
| MP-5 | **SOAT load** — open a vehicle that has a SOAT | SOAT detail screen loads; `expiryDate` non-nullable path works | `soat/SoatDto.expiryDate` required type |
| MP-6 | **SOAT load (no SOAT vehicle)** — open a vehicle without a SOAT | 404 handled gracefully (no crash); null returned by repository | `soat_repository_impl.dart` 404→Right(null) path |
| MP-7 | **Home screen** — open app, verify main vehicle and upcoming events render | No crash; `home_dto.toHomeData()` direct assignment works | `home_dto.dart` change |
| MP-8 | **User profile persistence** — log out and log back in | Profile data (name, etc.) persists; `UserStorageService.saveUser()` uses `user.toJson()` via new extension | `UserModelExtension.toJson()` used by storage |

---

## How to verify

```bash
# 1. Static analysis (zero errors required)
dart analyze

# 2. Full test suite (100% pass required)
flutter test

# 3. Grep guardrails (each must return zero results, except documented exceptions)
grep -rn "\.toModel()" lib/features/home/
# Expected: zero results

grep -rn "MaintenanceDto\.fromModel\|\.toModel()" lib/features/maintenance/data/repository/
# Expected: zero results

grep -rn "\.toDto()\|\.toModel()" lib/features/event_registration/data/repository/
# Expected: zero results

grep -rn "UserDto\.fromModel" lib/features/users/
# Expected: zero results

# Note: grep on lib/features/vehicles/ will show hits on soat_dto.dart and
# vehicle_repository_impl.dart (SOAT methods) — these reference the DEFERRED
# vehicles/soat_dto.dart and are EXPECTED exceptions.
```

---

## Sign-off

**CONDITIONAL GREEN**

All automated checks pass:
- `dart analyze`: 0 errors, 0 warnings (45 pre-existing info-level issues)
- `flutter test`: 119 pass, 0 fail
- All grep guardrails clean (exceptions are all documented and expected)
- All 11 wire-format spot-checks pass
- Both documentation files updated (coding standards + CLAUDE.md)

Condition: **Human must run manual probes MP-1 through MP-8** before merging to confirm zero runtime regressions in the migrated flows. These probes cannot be automated without launching the app.

Additional action required: **Decide fate of `api_base_url_resolver.dart` dirty file** (local API toggle active — must be reverted to `remoteBaseUrl.isEmpty` before release build).

No bugs found. No blocking issues. Ready for Tech Lead review.
