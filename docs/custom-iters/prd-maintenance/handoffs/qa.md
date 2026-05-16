# QA Handoff — prd-maintenance

## Test run results

### dart analyze
**Status: PASS** — 0 errors. 2 pre-existing deprecation warnings in `route_map_preview.dart` (MapBox API, unrelated).

### flutter test
**Status: PASS (with pre-existing failures)**
- 34 tests passed
- 3 pre-existing failures in `events_filter_cubit_test.dart` (references `EventType.onRoad` which was removed in a prior iteration — completely unrelated to this run)
- No maintenance-related test failures

## AC Traceability

| AC | Description | Verification | Status |
|----|-------------|-------------|--------|
| AC-1 | `MaintenanceModel` new fields | Code review: `maintenance_model.dart` — mode, serviceDate, odometerAtService, workshop, cost, notes, nextDate, nextOdometer | PASS |
| AC-2 | Status calc: overdue/next/upToDate | `MaintenanceModel.calculateStatus()` implemented with km+date thresholds (500km, 30d) | PASS (code) |
| AC-3 | Auto-creation of scheduled from completed | Backend `maintenances.service.ts` auto-creates 2nd SCHEDULED record; Flutter form page pops `List<MaintenanceModel>` | PASS (code) |
| AC-4 | nextKmInterval → nextOdometer | Backend computes `nextOdometer = odometerAtService + nextKmInterval`; Flutter form sends `nextKmInterval` | PASS (code) |
| AC-5 | List grouping: 3 sections | `MaintenancesCubit` sorts by rank: overdue(0)→next(1)→upToDate(2)→completed(3) | PASS (code) |
| AC-6 | Filter status only affects scheduled | `MaintenancesCubit.applyFilter()` — completed records pass through on `all` and `upToDate` only | PASS (code) |
| AC-7 | Garage widget: two independent cards | `VehicleMaintenancesCubit.lastCompleted` + `nextScheduled` getters; `_ServiceCard.last/next` use independent records | PASS (code) |
| AC-8 | Detail screen: correct fields per mode | `MaintenanceDetailHeader` uses `serviceDate`; `MaintenanceNextServiceCard` uses `nextDate`/`nextOdometer` | PASS (code) |
| AC-9 | Form validation per PRD | `MaintenanceFormContent` validates serviceDate+odometer for completed mode | PASS (code) |
| AC-10 | All strings in l10n | 14 new keys added to `app_es.arb`; `flutter gen-l10n` ran successfully | PASS |
| AC-11 | dart analyze passes | 0 errors | PASS |

## Regression guardrails verified

| Guardrail | Status |
|-----------|--------|
| MaintenanceDto legacy field fallback | `toModel()` uses new fields with fallback to `date`/`maintanceMileage`/`isScheduled` for old API records |
| Delete flow unchanged | `deleteMaintenanceLocally(String)` still works |
| VehicleMaintenancesCubit.addMaintenanceLocally | Sort updated to use `serviceDate ?? createdDate` |
| Filter "Todos" shows both modes | `MaintenanceStatusFilter.all` passes all records |
| Status calc null safety | Returns `upToDate` when no date/km set on scheduled record |

## Manual test checklist (for human)

1. Create `completed` maintenance with next fields → two records appear in list (1 completed + 1 scheduled)
2. Create `scheduled` maintenance (no service date) → appears in PRÓXIMAMENTE or ATRASADO section
3. Garage widget: left card = last completed date/km, right card = next scheduled date/km (different records)
4. Status filter "Atrasado" → only overdue scheduled records visible; completed records hidden
5. Open detail of a completed record → no NEXT SERVICE card shown (unless it has nextDate/nextOdometer)
6. Open detail of scheduled record → NEXT SERVICE card shows date and/or km
7. Old records (pre-migration) display correctly via legacy field fallback in DTO

## Pre-existing issues (not introduced by this run)

- `EventType.onRoad` test failures in `events_filter_cubit_test.dart` — 3 tests
- MapBox deprecation warnings in `route_map_preview.dart` — 2 infos

## Backend manual steps required before testing end-to-end

1. Run `cd /Users/cami/Developer/Personal/rideglory-api/maintenances-ms && npx prisma migrate dev --name maintenance_mode_workshop_fields`
2. Run `npx prisma generate` to update the Prisma client
3. Restart the maintenances-ms service
