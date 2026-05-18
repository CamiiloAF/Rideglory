# Tech Lead Review — prd-maintenance

## Overall verdict: APPROVED

The implementation is complete, architecturally sound, and passes all quality gates.

## Architecture compliance

| Check | Status | Notes |
|-------|--------|-------|
| Domain layer purity | PASS | `maintenance_model.dart` has no Flutter/network imports |
| Data layer isolation | PASS | `maintenance_dto.dart` only in data; no BuildContext |
| Presentation layer | PASS | No direct HTTP calls; no DTO exposure |
| ResultState<T> pattern | PASS | All cubits use correct pattern |
| One widget per file | PASS | All new widgets are isolated |
| No hardcoded strings | PASS | All 14 new strings in `app_es.arb` |
| No method-returns-widget | PASS | No `Widget _buildX()` methods found |
| dart analyze clean | PASS | 0 errors |

## Key design decisions — approved

1. **`MaintenanceMode` enum replaces `isScheduled: bool`** — correct; enums are more extensible.
2. **Legacy field fallback in `MaintenanceDto.toModel()`** — necessary for backward compat with old API records; pattern is safe (new fields preferred, legacy as fallback).
3. **Auto-creation moved to backend** — correct placement; backend owns the business rule.
4. **`nextKmInterval` (relative) sent to API; `nextOdometer` (absolute) returned** — correct separation; flutter doesn't need vehicle mileage at form submit time.
5. **`VehicleMaintenancesCubit.lastCompleted + nextScheduled`** — clean computed getters; garage widget correctly consumes two independent records.
6. **Status calc as static method on model** — pragmatic; avoids an extra use case for a pure computation.
7. **`MaintenancesCubit` sort rank (overdue→next→upToDate→completed)** — correct UX priority ordering.

## Minor findings (non-blocking)

1. **`change_vehicle_mileage_bottom_sheet.dart`**: Now uses `odometerAtService ?? 0`. The bottom sheet existed for a different UX flow (prompting to update vehicle mileage after logging). With the new model, this sheet may become dead code if the form flow no longer calls it — worth verifying in manual testing. Not a code quality issue.

2. **`maintenances_summary_header.dart`**: Still uses `maintenanceSummary?.lastServiceDate` from `MaintenanceListSummary`. If `MaintenanceListSummary` domain model also had old fields, that needs a separate check. However since it's a separate concern (API summary endpoint) and the fallback uses `serviceDate`, this is acceptable.

3. **`ModernMaintenanceCard` progress bar**: Uses `odometerAtService` which is null for scheduled records. `_getProgressPercent` returns null correctly when `atService == null`. Good defensive coding.

## What's NOT included (by design)

- No new unit tests written (QA phase noted this as a gap — unit tests for `calculateStatus`, cubit grouping, and `lastCompleted/nextScheduled` would improve confidence)
- Backend migration not yet run (requires manual step: `prisma migrate dev`)
- No e2e test coverage

## Human review checklist

Before committing, verify:
- [ ] Run `git diff lib/features/maintenance/` — confirm no old field references remain
- [ ] Run backend migration: `cd rideglory-api/maintenances-ms && npx prisma migrate dev`
- [ ] Run `npx prisma generate` after migration
- [ ] Manual test: create completed maintenance with next fields → 2 records appear
- [ ] Manual test: garage widget shows last completed (left) / next scheduled (right)
- [ ] Manual test: detail screen per mode shows correct fields

## Files changed (maintenance module only)

**Flutter — modified:**
- `lib/features/maintenance/domain/model/maintenance_model.dart`
- `lib/features/maintenance/data/dto/maintenance_dto.dart`
- `lib/features/maintenance/data/service/maintenance_service.dart`
- `lib/features/maintenance/domain/repository/maintenance_repository.dart`
- `lib/features/maintenance/data/repository/maintenance_repository_impl.dart`
- `lib/features/maintenance/domain/use_cases/add_maintenance_use_case.dart`
- `lib/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart`
- `lib/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart`
- `lib/features/maintenance/presentation/widgets/maintenance_filters.dart`
- `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart`
- `lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_grouped_list_item.dart`
- `lib/features/maintenance/presentation/list/maintenances/widgets/maintenances_data_widget.dart`
- `lib/features/maintenance/presentation/list/maintenances/widgets/maintenances_summary_header.dart`
- `lib/features/maintenance/presentation/form/widgets/maintenance_form_content.dart`
- `lib/features/maintenance/presentation/form/maintenance_form_page.dart`
- `lib/features/maintenance/presentation/list/maintenances/maintenances_page.dart`
- `lib/features/maintenance/presentation/detail/maintenance_detail_page.dart`
- `lib/features/maintenance/presentation/detail/widgets/maintenance_info_card.dart`
- `lib/features/maintenance/presentation/detail/widgets/maintenance_next_service_card.dart`
- `lib/features/maintenance/presentation/detail/widgets/maintenance_detail_header.dart`
- `lib/features/maintenance/presentation/detail/widgets/maintenance_type_card.dart`
- `lib/features/maintenance/presentation/form/widgets/change_vehicle_mileage_bottom_sheet.dart`
- `lib/features/maintenance/presentation/widgets/item_card/maintenance_card_body.dart`
- `lib/features/maintenance/presentation/widgets/item_card/maintenance_card_header.dart`
- `lib/features/maintenance/presentation/widgets/item_card/maintenance_dates_section.dart`
- `lib/features/maintenance/presentation/widgets/item_card/maintenance_mileage_info.dart`
- `lib/features/maintenance/presentation/widgets/item_card/modern_maintenance_card.dart`
- `lib/features/vehicles/presentation/garage/cubit/vehicle_maintenances_cubit.dart`
- `lib/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart`
- `lib/features/home/presentation/widgets/home_vehicle_info_row.dart`
- `lib/l10n/app_es.arb`

**Flutter — new:**
- `lib/features/maintenance/data/dto/create_maintenance_response_dto.dart`

**Backend (rideglory-api) — modified:**
- `rideglory-contracts/src/maintenances/enums/maintenance.enums.ts`
- `rideglory-contracts/src/maintenances/dto/create-maintenance.dto.ts`
- `rideglory-contracts/src/maintenances/dto/find-maintenances-filter.dto.ts`
- `maintenances-ms/prisma/schema.prisma`
- `maintenances-ms/src/maintenances/maintenances.service.ts`

**Backend — new:**
- `maintenances-ms/prisma/migrations/20260516000000_maintenance_mode_workshop_fields/migration.sql`
