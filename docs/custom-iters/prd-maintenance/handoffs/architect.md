# Architect Handoff — prd-maintenance

**Date:** 2026-05-16  
**Status:** complete

---

## Goal acknowledgement

Implement full maintenance module business logic: `MaintenanceMode` enum, `MaintenanceStatus` km+date calculation, auto-creation of `scheduled` from `completed`, updated garage widget dual-card layout, and all required API contract changes in both Flutter and rideglory-api.

---

## Change map

| File | Action | One-line reason | Risk |
|------|--------|-----------------|------|
| `maintenances-ms/prisma/schema.prisma` | modify | Add `mode` enum + column, add `serviceDate`, `odometerAtService`, `workshop`; rename semantics | high — schema migration |
| `maintenances-ms/prisma/migrations/<new>` | create | Prisma migration SQL for new fields + data backfill | high |
| `rideglory-contracts/src/maintenances/enums/maintenance.enums.ts` | modify | Add `MaintenanceMode` enum | med |
| `rideglory-contracts/src/maintenances/dto/create-maintenance.dto.ts` | modify | Replace `isScheduled/date/maintanceMileage` with `mode/serviceDate/odometerAtService/workshop/nextKmInterval` | high — breaking change |
| `rideglory-contracts/src/maintenances/dto/update-maintenance.dto.ts` | no change | `PartialType(CreateMaintenanceDto)` auto-inherits new fields | low |
| `rideglory-contracts/src/maintenances/dto/find-maintenances-filter.dto.ts` | modify | Add `mode` filter param | low |
| `maintenances-ms/src/maintenances/maintenances.service.ts` | modify | `create()` now returns `{created:[]}` array; compute `odometerAtService + nextKmInterval = nextMaintenanceMileage`; auto-create scheduled record | high |
| `maintenances-ms/src/maintenances/maintenances.service.ts` | modify | `findByVehicleId` filter on `mode` field instead of `isScheduled` | med |
| `api-gateway/src/maintenances/maintenances.controller.ts` | modify | `POST` returns `{created:[]}` passthrough; `CreateAuthenticatedMaintenanceDto` updated | med |
| **Flutter:** `lib/features/maintenance/domain/model/maintenance_model.dart` | modify | New fields, `MaintenanceMode` enum, `MaintenanceStatus` enum with calc method | high |
| **Flutter:** `lib/features/maintenance/data/dto/maintenance_dto.dart` | modify | Mirror new model fields; `toModel()`/`fromModel()` updated | high |
| **Flutter:** `lib/features/maintenance/data/dto/vehicle_maintenances_list_response_dto.dart` | no change | Shape unchanged (`{items, summary}`) | none |
| **Flutter:** `lib/features/maintenance/data/dto/create_maintenance_response_dto.dart` | create | New DTO: `{created: List<MaintenanceDto>}` | low |
| **Flutter:** `lib/features/maintenance/data/service/maintenance_service.dart` | modify | `create()` returns `Future<CreateMaintenanceResponseDto>` | med |
| **Flutter:** `lib/features/maintenance/data/repository/maintenance_repository_impl.dart` | modify | `addMaintenance` returns `List<MaintenanceModel>` (1 or 2 records) | med |
| **Flutter:** `lib/features/maintenance/domain/repository/maintenance_repository.dart` | modify | `addMaintenance` signature returns `Either<DomainException, List<MaintenanceModel>>` | med |
| **Flutter:** `lib/features/maintenance/domain/use_cases/add_maintenance_use_case.dart` | modify | Returns `Either<DomainException, List<MaintenanceModel>>` | med |
| **Flutter:** `lib/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart` | modify | Updated `buildMaintenanceToSave`; handle `List<MaintenanceModel>` response; insert both locally | high |
| **Flutter:** `lib/features/maintenance/presentation/form/widgets/maintenance_form_view.dart` | modify | Wire `MaintenanceMode` toggle; updated field bindings | med |
| **Flutter:** `lib/features/maintenance/presentation/form/widgets/*.dart` | modify (several) | Field references to new model fields | med |
| **Flutter:** `lib/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart` | modify | Status calc with km thresholds; grouped emission ordering | high |
| **Flutter:** `lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_grouped_list_item.dart` | modify | Display text using new fields | med |
| **Flutter:** `lib/features/maintenance/presentation/detail/maintenance_detail_page.dart` | modify | Mode badge; new field display | med |
| **Flutter:** `lib/features/maintenance/presentation/detail/widgets/*.dart` | modify (several) | Field references to new model | med |
| **Flutter:** `lib/features/maintenance/presentation/widgets/maintenance_filters.dart` | modify | Rename filter enum values to match new status names | low |
| **Flutter:** `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart` | modify (check) | Update filter chip labels if status names changed | low |
| **Flutter:** `lib/features/vehicles/presentation/garage/cubit/vehicle_maintenances_cubit.dart` | modify | Expose `lastCompleted` and `nextScheduled` separately | med |
| **Flutter:** `lib/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart` | modify | Two independent cards with separate record sources | med |
| **Flutter:** `lib/l10n/app_es.arb` | modify | Add new l10n strings (workshop, mode badges, status labels, validation messages) | low |

---

## Data model impact

### Prisma schema delta

Current `Maintenance` model has:
- `date: DateTime` — conflates service date and scheduled date  
- `maintanceMileage: Int` (typo, NOT renamed in DB — only semantic rename in Flutter/API layer)  
- `isScheduled: Boolean @default(false)`
- No `workshop` field
- No `mode` enum

**New fields to ADD:**
```prisma
enum MaintenanceMode {
  COMPLETED
  SCHEDULED
}

model Maintenance {
  // ... existing fields ...
  mode        MaintenanceMode @default(COMPLETED)    // new
  serviceDate DateTime?                              // new — null for scheduled records
  workshop    String?                                // new
  // date — KEEP for backward compat; new records use serviceDate when mode==COMPLETED
  // maintanceMileage — KEEP column name (typo preserved); semantic rename in TS/Dart layer only
  // isScheduled — KEEP for backward compat query; derive mode from it in backfill migration
  nextOdometer Int?                                  // new — absolute computed value from nextKmInterval
}
```

**Migration plan:**
1. Add `MaintenanceMode` enum to Postgres.
2. Add `mode` column with default `COMPLETED`.
3. Add `serviceDate` nullable datetime column.
4. Add `workshop` nullable varchar column.
5. Add `nextOdometer` nullable integer column.
6. Backfill: `UPDATE "Maintenance" SET mode = CASE WHEN "isScheduled" = true THEN 'SCHEDULED' ELSE 'COMPLETED' END`.
7. Backfill: `UPDATE "Maintenance" SET "serviceDate" = date WHERE mode = 'COMPLETED'`.
8. Backfill: `UPDATE "Maintenance" SET "nextOdometer" = "nextMaintenanceMileage"` (already absolute in old records).
9. Keep `isScheduled`, `date`, `maintanceMileage` columns for now — remove in a future cleanup migration.

---

## Contract impact

### POST `/api/maintenances/vehicle/:vehicleId`

**Request body (new):**
```json
{
  "type": "OIL_CHANGE",
  "mode": "COMPLETED",
  "serviceDate": "2024-06-15",
  "odometerAtService": 10050,
  "cost": 85000,
  "workshop": "Moto Center Bogotá",
  "notes": "Aceite sintético...",
  "nextKmInterval": 3000,
  "nextDate": "2025-06-15"
}
```

**Response 201 (new shape):**
```json
{
  "created": [
    { ...maintenanceCompletado },
    { ...maintenanceProgramado }
  ]
}
```
- `created` array has 1 entry when `mode=SCHEDULED` or no next fields.
- `created` array has 2 entries when `mode=COMPLETED` AND (`nextKmInterval` OR `nextDate` provided).
- `nextOdometer` in response = `odometerAtService + nextKmInterval` (computed by backend).

**Breaking change:** Flutter's `MaintenanceService.create()` must change return type from `Future<MaintenanceDto>` to `Future<CreateMaintenanceResponseDto>`.

### GET `/api/maintenances/vehicle/:vehicleId`

**Query params added:** `mode=COMPLETED|SCHEDULED` (optional, for filter)  
**Response shape unchanged:** `{items: [...], summary: {...}}`  
Each item in `items` now includes: `mode`, `serviceDate`, `odometerAtService`, `workshop`, `nextOdometer`.

### PATCH and DELETE — unchanged shape, new fields optional in PATCH body.

---

## Env / config delta

None — no new env vars needed.

---

## Risk register

1. **Breaking API contract (high):** `POST` now returns `{created:[...]}` instead of single DTO. Flutter and backend must be deployed together. Mitigation: both changed in this same run; no intermediate state.
2. **Prisma migration with backfill (high):** Backfill is safe (reads `isScheduled`, writes `mode`). Risk: running migration on production with existing data. Mitigation: migration is additive (new columns with defaults + backfill); old columns kept.
3. **`maintanceMileage` typo preserved (med):** DB column name stays as-is. Only the Flutter model field is renamed to `odometerAtService`. DTO maps `maintanceMileage` ↔ `odometerAtService`. Risk: confusion. Mitigation: document in DTO comments.
4. **`AddMaintenanceUseCase` signature change (med):** Returns `List<MaintenanceModel>` now. All call sites (form cubit) must handle list. Risk: missed call sites. Mitigation: `dart analyze` will catch type errors.
5. **`VehicleMaintenancesCubit` state change (med):** Cubit state changes from `List<MaintenanceModel>` (sorted by date) to exposing `lastCompleted` and `nextScheduled` separately. `vehicle_maintenance_history_section.dart` depends on this. Risk: widget build error if not updated together. Mitigation: both changed in same Frontend phase.
6. **Status filter semantic change (low):** `MaintenanceStatusFilter.upcoming` renamed to `next`, `onTrack` to `upToDate`. Risk: any persisted filter state breaks. Mitigation: no persistence of filter state in current code.

---

## Regression test surface

| Existing code | Tests covering it | Sufficient? |
|---------------|------------------|-------------|
| `MaintenanceRepositoryImpl.getMaintenancesByVehicleId` | No dedicated unit test found | No — add test |
| `MaintenanceRepositoryImpl.addMaintenance` | No dedicated unit test found | No — add test |
| `MaintenancesCubit._applyClientFiltersAndEmit` | No test found | No — add test |
| `VehicleMaintenancesCubit.fetchMaintenances` | No test found | No — add test |
| `MaintenanceFormCubit.buildMaintenanceToSave` | No test found | No — add test |
| `MaintenanceDeleteCubit.deleteMaintenance` | No test found | No — add test |
| `dart analyze` | Implicitly by CI | Yes |
| `flutter test` | Implicitly by CI | Yes (once tests added) |

---

## Implementation order

**Backend (rideglory-api) — do first:**
1. `rideglory-contracts`: Add `MaintenanceMode` enum; update `CreateMaintenanceDto` with new fields.
2. `maintenances-ms/prisma/schema.prisma`: Add `MaintenanceMode` enum model + new fields.
3. Create Prisma migration file with backfill SQL.
4. `maintenances-ms/src/maintenances/maintenances.service.ts`: Update `create()` to compute `nextOdometer`, create second record, return `{created:[...]}`.
5. `api-gateway`: Update `CreateAuthenticatedMaintenanceDto` and `POST` response passthrough.

**Flutter — after backend:**
1. `maintenance_model.dart`: New enums + fields + `calculateStatus()` static method.
2. `maintenance_dto.dart`: Mirror new fields; `toModel()`/`fromModel()` updated; `maintanceMileage` ↔ `odometerAtService` mapping.
3. `create_maintenance_response_dto.dart`: New DTO for `{created:[...]}`.
4. `maintenance_service.dart`: Update `create()` return type.
5. `maintenance_repository.dart` + `maintenance_repository_impl.dart`: `addMaintenance` returns `List<MaintenanceModel>`.
6. `add_maintenance_use_case.dart`: Returns `List<MaintenanceModel>`.
7. `maintenance_form_cubit.dart`: Updated `buildMaintenanceToSave`; handle list response.
8. `maintenances_cubit.dart`: New status calc; grouped emission; `addMaintenanceLocally` handles list.
9. `maintenance_filters.dart`: Rename enum values.
10. `vehicle_maintenances_cubit.dart`: Expose `lastCompleted`/`nextScheduled`.
11. All widget files: update field references.
12. `app_es.arb`: Add all new strings.

---

## Out of scope

- FCM notifications (backend-only per PRD §11; not part of this run)
- Step 1 form page (`maintenance_type_selection.dart`) — already works correctly; PRD changes only affect Step 2
- Vehicle selector chip on list page — already implemented; no changes needed
- Any features listed in PRD §14

---

## Notes for orchestrator

1. **Design phase:** Skip (as PO recommended). PRD §2-§10 is the full spec. No Pencil changes needed.
2. **`needsDb: true`** — confirmed. Prisma migration required. Backend agent handles this.
3. **Key assumption made:** `maintanceMileage` DB column name preserved (typo kept). Only Flutter model field renamed. If human wants DB column rename too, backend agent needs an additional migration step.
4. **Garage widget cubit state change:** `VehicleMaintenancesCubit` state type stays `ResultState<List<MaintenanceModel>>` but we add two getters: `lastCompleted` and `nextScheduled` computed from the state data. The widget reads these getters, not `state.data.first`.
5. **`MaintenanceStatus` calculation location:** In the domain model as a static method `MaintenanceModel.calculateStatus(maintenance, currentMileage)`. This is a pure Dart calculation — no Flutter imports, acceptable in domain.
