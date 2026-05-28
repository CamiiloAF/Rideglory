# Tech Lead review — DTO inheritance standard refactor

**Date:** 2026-05-28
**Status:** ready_for_human_review

---

## Verdict

**ready_for_human_review**

All automated checks pass. 0 blockers. 0 majors. 3 minors (none require code changes before merge). 8 manual probes must be run by the human before the commit lands on main. One pre-existing dirty file (`api_base_url_resolver.dart`) must be reverted before a release build.

---

## Files reviewed

From `git diff --stat` (17 modified files, nothing untracked in lib/):

| # | File | In architect change map? |
|---|------|--------------------------|
| 1 | `.cursor/rules/rideglory-coding-standards.mdc` | Yes |
| 2 | `CLAUDE.md` | Yes |
| 3 | `docs/iter-7-scope.md` | No — out of scope (annotation added to a planning checklist item) |
| 4 | `lib/core/http/api_base_url_resolver.dart` | No — pre-existing dirty file, not touched by this iteration |
| 5 | `lib/core/services/user_storage_service.dart` | Yes (caller of `UserDto.fromModel`) |
| 6 | `lib/features/event_registration/data/dto/event_registration_dto.dart` | Yes |
| 7 | `lib/features/event_registration/data/dto/vehicle_summary_dto.dart` | Yes |
| 8 | `lib/features/event_registration/data/repository/event_registration_repository_impl.dart` | Yes |
| 9 | `lib/features/home/data/dto/home_dto.dart` | Yes |
| 10 | `lib/features/maintenance/data/dto/create_maintenance_response_dto.dart` | Yes |
| 11 | `lib/features/maintenance/data/dto/maintenance_dto.dart` | Yes |
| 12 | `lib/features/maintenance/data/repository/maintenance_repository_impl.dart` | Yes |
| 13 | `lib/features/soat/data/dto/soat_dto.dart` | Yes |
| 14 | `lib/features/soat/data/repository/soat_repository_impl.dart` | Yes |
| 15 | `lib/features/users/data/dto/user_dto.dart` | Yes |
| 16 | `lib/features/vehicles/data/dto/vehicle_dto.dart` | Yes |
| 17 | `lib/features/vehicles/data/repository/vehicle_repository_impl.dart` | Yes |

Files 3 and 4 are the only ones outside the architect's change map.

- **`docs/iter-7-scope.md`** — a one-line annotation (`R//: Si es necesario un nuevo frame en pencil.`) added to a planning checklist question. Harmless; not in scope but not harmful. No code impact.
- **`lib/core/http/api_base_url_resolver.dart`** — pre-existing developer toggle (`shouldUseLocalApi = true`). Confirmed NOT touched by this iteration's agents. Must be reverted to `remoteBaseUrl.isEmpty` before merging to main / cutting a release build.

---

## Findings

| File:line | Severity | Issue | Required fix |
|-----------|----------|-------|--------------|
| `docs/iter-7-scope.md` | nit | Modified outside architect change map — one-line planning annotation unrelated to this PRD | No code fix required; human may want to commit this separately or revert |
| `lib/core/http/api_base_url_resolver.dart` | **major** (release blocker, not a code-quality issue) | Pre-existing toggle forces `shouldUseLocalApi = true` — would route all production traffic to localhost | Must revert to `remoteBaseUrl.isEmpty` before merging to main. Not introduced by this iteration. |
| `lib/features/maintenance/data/repository/maintenance_repository_impl.dart:89` | minor | `response.summary.toModel()` — `MaintenanceListSummaryDto` is a documented Pattern A exception (composite wrapper, no domain model). Correctly left as-is. | No fix required; documented exception. Noted for awareness. |
| `lib/features/maintenance/data/repository/maintenance_repository_impl.dart` (Decision 2) | minor | `_buildCreateBody` still hand-constructs `Map<String, dynamic>` with `nextKmInterval` and `mode` — deviates from `feedback_dto_toJson.md` memory rule | Captured as follow-up tech-debt per architect Decision 2. No fix required for this iteration. |
| `lib/features/event_registration/data/dto/event_registration_dto.dart` | nit | `prefer_null_aware_operators` analyzer info on the `vehicleSummary` null check in the extension body (pre-existing, not introduced) | No fix required; pre-existing info-level only. |

**Blockers: 0. Majors: 0 (the `api_base_url_resolver.dart` change is pre-existing and a human-action item, not a code defect in this iteration). Minors: 2. Nits: 2.**

---

## Security findings

| Finding | Severity | Status |
|---------|----------|--------|
| No secrets added | N/A | Pass |
| No PII added to logs | N/A | Pass |
| No SQL concatenation | N/A — pure Dart | Pass |
| No XSS sinks | N/A — mobile app | Pass |
| Firebase Auth token flow untouched | Pass | Pass |
| `api_base_url_resolver.dart` toggle active | Info | Pre-existing; would only affect localhost routing, not auth or data security. Must revert before release. |

No security concerns introduced by this refactor.

---

## Architecture adherence

| Rule | Status | Notes |
|------|--------|-------|
| Domain layer: no Flutter imports, no HTTP, no I/O | Pass | All domain model files untouched |
| Data layer: no widgets, no BuildContext | Pass | All changes in `data/dto/` and `data/repository/` only |
| Presentation layer: no direct HTTP, no DTO types exposed | Pass | No presentation files changed |
| Dependencies flow inward (presentation→domain←data) | Pass | DTOs now extend models; domain never imports data |
| Pattern B applied to all eligible DTOs | Pass | 6 DTOs migrated; all callers cleaned |
| Documented exceptions remain Pattern A | Pass | `HomeDto`, `CreateMaintenanceResponseDto`, `VehicleMaintenancesListResponseDto`, `CreateUserDto`, `NotificationDto`, `vehicles/soat_dto.dart` — all correctly left in Pattern A |
| `@JsonKey(name: 'createdAt'/'updatedAt')` preserves wire format | Pass | Confirmed in `maintenance_dto.g.dart` spot-check by QA |
| `birthDate` override preserved in `EventRegistrationDto.toJson()` | Pass | Verbatim preservation confirmed |
| `SoatDto.expiryDate` non-nullable + comment | Pass | Contract assumption documented in code comment |
| `_VehicleSummaryConverter` correctly wires deserialization | Pass | `fromJson` returns `VehicleSummaryDto.fromJson(json)` — correct subtype; `toJson` calls `model.toJson()` via `VehicleSummaryModelExtension` (imported) |
| `MaintenanceModelExtension.toJson()` correctly passes `createdDate`/`updatedDate` (not `createdAt`/`updatedAt`) | Pass | Extension passes the model field names; `@JsonKey` on the DTO constructor remaps them to the wire names |
| `UserModelExtension.toJson()` import path correct | Pass | `user_storage_service.dart` imports `user_dto.dart`, which defines the extension |
| `_buildCreateBody` left as-is (Decision 2) | Pass | Intentional; captured as follow-up |
| `vehicles/soat_dto.dart` correctly deferred | Pass | `vehicle_repository_impl.dart` lines 113/123 still call `.toModel()` on this DTO — expected, documented |
| Standards docs updated | Pass | `.cursor/rules/rideglory-coding-standards.mdc` §DTO Pattern B added; `CLAUDE.md` data layer description updated |

---

## Test adequacy

| AC | Result | Notes |
|----|--------|-------|
| AC-1 VehicleDto.toModel() removed | Pass | Grep + code inspection |
| AC-2 UserDto.fromModel() removed + extension added | Pass | Code inspection |
| AC-3 MaintenanceDto extends model, @JsonKey, extension | Pass | Wire-format spot-check on .g.dart |
| AC-4 maintenance_repository_impl.dart clean | Pass | Grep + code inspection |
| AC-5 create_maintenance_response_dto.dart cast | Pass | Code inspection |
| AC-6 VehicleSummaryDto extends model, extension | Pass | Code inspection |
| AC-7 EventRegistrationDto extends model, birthDate preserved | Pass | Code inspection + .g.dart check |
| AC-8 event_registration_repository_impl.dart clean | Pass | Grep (zero hits) |
| AC-9 soat/SoatDto extends model, extension preserved | Pass | Code inspection |
| AC-10 soat_repository_impl.dart direct assignment | Pass | Code inspection |
| AC-11 dart analyze zero new violations | Pass | 0 errors/warnings; 45 pre-existing info |
| AC-12 flutter test 100% | Pass | 119/119, exit code 0 |
| AC-13 coding standards updated | Pass | Line 199 confirmed by QA |
| AC-14 CLAUDE.md updated | Pass | Lines 86 and 126 confirmed by QA |
| AC-15 no orphaned .g.dart files | Pass | build_runner: 16 outputs, no conflicts |

**Assessment:** Test coverage is structurally sound. Automated tests confirm zero regressions. The gap acknowledged by Architect and QA — no serialization roundtrip unit tests — is a follow-up item, not a blocker for this refactor iteration.

---

## Regression risk summary

| Area | Result |
|------|--------|
| VehicleDto.toModel() removal callers | Pass — grep zero hits in vehicles/ and home/ |
| MaintenanceDto migration call sites | Pass — only expected `MaintenanceListSummaryDto.toModel()` exception remains |
| EventRegistrationDto call site cleanup | Pass — zero hits |
| soat/SoatDto call site cleanup | Pass — zero hits |
| UserDto.fromModel removal | Pass — zero hits |
| Code generation (build_runner) | Pass — 16 outputs, no conflicts |
| dart analyze | Pass — 0 errors/warnings |
| flutter test | Pass — 119/119 |
| vehicles/soat_dto.dart deferred exception | Expected — documented |
| api_base_url_resolver.dart toggle | **needs_human_action** — must revert before merge to main |

**Overall: needs_human_verify** — all automated checks pass, but 8 manual probes are required to confirm zero runtime regressions in the migrated flows.

---

## Manual probes the human must run before commit

Run on simulator or physical device. None of these can be automated without launching the app.

| # | Flow | What to verify | Failure mode |
|---|------|---------------|--------------|
| MP-1 | Create a maintenance record for a vehicle | New entry appears in list; no crash on create | `MaintenanceDto` wire-format regression via `maintenance.toJson()` |
| MP-2 | Edit an existing maintenance record and save | Changes persist; no crash on update | `MaintenanceModelExtension.toJson()` regression |
| MP-3 | Register for an event with a vehicle selected | Registration saved; vehicle summary displays correctly in confirmation | `_VehicleSummaryConverter` + nested DTO deserialization |
| MP-4 | Open the "My registrations" list | All rows render without crash | Repository `.toModel()` removal on list endpoints |
| MP-5 | Open a vehicle that has a SOAT | SOAT detail screen loads; `expiryDate` shown correctly | `soat/SoatDto.expiryDate` required (non-nullable) type |
| MP-6 | Open a vehicle that has NO SOAT | No crash; graceful empty/not-found state | `soat_repository_impl.dart` 404 → `Right(null)` path |
| MP-7 | Open the Home screen | Main vehicle and upcoming events render; no crash | `home_dto.dart` direct `mainVehicle` assignment |
| MP-8 | Log out and log back in | User profile data (name, email, etc.) persists correctly | `UserModelExtension.toJson()` used by `UserStorageService.saveUser()` |

---

## Limitations / known edge cases the human should be aware of

1. **`api_base_url_resolver.dart` local toggle active.** The working tree has `shouldUseLocalApi = true` (forces local API). This was a pre-existing dirty file stashed as `pre-custom-iter-prd-dto-inheritance-standard`. The iteration agents did not touch it. **Before committing, revert this line to `final shouldUseLocalApi = remoteBaseUrl.isEmpty;`** or the production app will try to reach `localhost`.

2. **`vehicles/data/dto/soat_dto.dart` deferred.** This DTO remains Pattern A. `vehicle_repository_impl.dart` lines 113 and 123 still call `.toModel()` on it. This is expected. The deferred migration requires unifying the two `SoatModel` classes across features (`soat/` vs `vehicles/`) first.

3. **`notifications/data/dto/notification_dto.dart` deferred.** `toModel()` contains business logic (notification type switch, title/body construction). Requires mapper extraction before the DTO can extend the model.

4. **`_buildCreateBody` in `maintenance_repository_impl.dart`.** Intentionally left as a hand-constructed `Map<String, dynamic>` (Decision 2) because it includes `nextKmInterval` and mode strings that don't exist on `MaintenanceModel`. A dedicated `CreateMaintenanceRequestDto` should be created in a follow-up iteration to fully comply with the `feedback_dto_toJson.md` memory rule.

5. **No serialization roundtrip unit tests.** `flutter test` passes but there are no assertions that `dto.toJson()` key sets are unchanged before and after migration. The `.g.dart` spot-checks by QA are a strong mitigation, but a dedicated `test/features/*/data/dto/` test suite is recommended for the next pass.

6. **`docs/iter-7-scope.md` modified.** An annotation was added to a planning checklist outside this PRD's scope. Not harmful. Human may want to stage this separately from the DTO refactor commit.

---

## Recommended commit message

```
refactor: migrate all eligible DTOs to Pattern B (XDto extends XModel)

Removes toModel()/fromModel()/toDto() from VehicleDto, UserDto,
MaintenanceDto, VehicleSummaryDto, EventRegistrationDto, and soat/SoatDto.
Adds XModelExtension.toJson() extensions. Updates CLAUDE.md and
rideglory-coding-standards.mdc with the canonical Pattern B standard and
documented exceptions list. dart analyze: 0 errors. flutter test: 119/119.

Note: revert api_base_url_resolver.dart local toggle before merging.
```

---

## Change log

- 2026-05-28: Initial tech lead review — verdict `ready_for_human_review`. 0 blockers, 0 majors, 2 minors, 2 nits.
