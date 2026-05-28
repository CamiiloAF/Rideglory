> Slim handoff for /custom-iter-fast prd-dto-inheritance-standard. Full detail in architect.md (read only if ambiguous).

# QA handoff — DTO inheritance refactor

## Verification scope

Pure data-layer refactor. No UI, no API contract, no behavior changes. Verify (a) code-generation succeeds, (b) static analysis clean, (c) test suite green, (d) all `.toModel()`/`.toDto()`/`fromModel` call sites eliminated from the migrated features, (e) JSON wire format unchanged.

## Static checks

1. **Build runner ran cleanly:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   Should complete with no errors, no orphaned `.g.dart` files.

2. **Analyzer:**
   ```bash
   dart analyze
   ```
   → zero NEW errors/warnings vs `main` baseline.

3. **Tests:**
   ```bash
   flutter test
   ```
   → 100% pass.

## Grep guardrails (each MUST return zero results)

```bash
grep -rn "\.toModel()" lib/features/vehicles/ lib/features/home/
grep -rn "MaintenanceDto\.fromModel\|\.toModel()" lib/features/maintenance/
grep -rn "\.toDto()\|\.toModel()" lib/features/event_registration/
grep -rn "\.toModel()" lib/features/soat/
grep -rn "UserDto\.fromModel" lib/features/users/
```

Acceptable exceptions (Pattern A wrappers, NOT migrated this iteration):
- `lib/features/vehicles/data/dto/soat_dto.dart` (deferred).
- `lib/features/notifications/data/dto/notification_dto.dart` (deferred).
- `lib/features/maintenance/data/dto/vehicle_maintenances_list_response_dto.dart` (`MaintenanceListSummaryDto.toModel()` — composite wrapper exception).

If any of these show in grep, that is expected — note them but don't fail QA.

## Wire-format spot checks

Open the regenerated `.g.dart` files and confirm:

1. **`maintenance_dto.g.dart`** — `_$MaintenanceDtoToJson` writes keys `createdAt`, `updatedAt` (NOT `createdDate`/`updatedDate`). Same on `_$MaintenanceDtoFromJson` reads.
2. **`event_registration_dto.g.dart`** — the nested `vehicleSummary` is built via `VehicleSummaryDto.fromJson(...)`, not `VehicleSummaryModel(...)` directly. The class-level `toJson()` override still sets `birthDate` via `apiEncodeRequiredDateTime`.
3. **`soat_dto.g.dart`** — `expiryDate` is read as required `DateTime`, not nullable. No `?? DateTime.now()` fallback exists anywhere.
4. **`vehicle_summary_dto.g.dart`** — fields `id`, `brand`, `model`, `licensePlate`, `vin` present with same nullability as today.
5. **`user_dto.g.dart`** — unchanged key set vs `main` (only `fromModel()` removed; codegen output identical).
6. **`vehicle_dto.g.dart`** — unchanged key set vs `main` (only redundant `toModel()` removed).

## Functional smoke tests (manual, recommended)

1. **Maintenance create flow:** create a maintenance record for a vehicle → verify list reload shows it. Confirms `_buildCreateBody` + new `dto` direct-return wiring works.
2. **Maintenance update flow:** edit an existing maintenance → save → verify changes persist. Confirms `maintenance.toJson()` extension produces correct payload.
3. **Event registration create:** register for an event with a vehicle → confirm `vehicleSummary` round-trips correctly. Confirms nested DTO deserialization (Decision 1).
4. **My registrations list:** open list → verify all rows render. Confirms repository drop-`.toModel()` change does not break presentation.
5. **SOAT load + save:** open a vehicle with SOAT → verify display → edit + save. Confirms `expiryDate` non-nullable path works end-to-end.
6. **Home screen:** open home → verify main vehicle and upcoming events render. Confirms `home_dto.toHomeData()` direct assignment works.

## Documentation checks

1. **`.cursor/rules/rideglory-coding-standards.mdc`** — contains a new section on DTO Pattern B with the exceptions list (composite wrappers, request-only DTOs, business-logic-bearing DTOs).
2. **`CLAUDE.md`** — Architecture section describes Pattern B as the sole DTO standard.

## Follow-up tech-debt to log (NOT a blocker)

1. **`_buildCreateBody` in `maintenance_repository_impl.dart`** still hand-builds a JSON map (violates the `DTO.toJson()` memory rule). Should become a `CreateMaintenanceRequestDto` in a future iteration.
2. **DTO roundtrip unit tests** not added — gap in coverage. Recommend a small fixture suite in a follow-up.
3. **`vehicles/soat_dto.dart` and `notification_dto.dart`** remain Pattern A — deferred per PRD §8.

## Pass/fail call

- PASS if all greps clean, build_runner + analyzer + tests green, all 6 wire-format spot checks confirmed, all 6 functional smoke tests OK, both docs updated.
- FAIL if any grep returns an unexpected hit, build_runner errors, analyzer regresses, any test broken, or wire-format keys diverge from `main`.
