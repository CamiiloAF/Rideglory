> Slim handoff for /custom-iter prd-maintenance. Full detail in docs/custom-iters/prd-maintenance/handoffs/architect.md (read only if ambiguous).

## Test commands

```bash
# Flutter — run from /Users/cami/Developer/Personal/Rideglory
dart analyze
flutter test

# Backend — run from /Users/cami/Developer/Personal/rideglory-api/maintenances-ms
npm test
```

## Acceptance criteria traceability

| AC | Description | Test target |
|----|-------------|-------------|
| AC-1 | `MaintenanceModel` has correct new fields | Unit: `maintenance_model_test.dart` |
| AC-2 | Status calc: overdue/next/upToDate by km + date | Unit: `maintenance_status_calculator_test.dart` |
| AC-3 | Auto-creation of scheduled from completed | Unit: `MaintenanceFormCubit` test; integration: `MaintenanceRepositoryImpl` test |
| AC-4 | Relative km conversion (nextKmInterval → nextOdometer) | Unit: form cubit + backend service test |
| AC-5 | List grouping: 3 sections | Unit: `MaintenancesCubit` test |
| AC-6 | Filter status only affects scheduled | Unit: `MaintenancesCubit` filter test |
| AC-7 | Garage widget: two independent cards | Widget test: `VehicleMaintenanceHistorySection` |
| AC-8 | Detail screen: correct fields per mode | Widget test: `MaintenanceDetailPage` |
| AC-9 | Form validation per PRD §7.6 | Widget test: `MaintenanceFormPage` |
| AC-10 | All strings in l10n | `dart analyze` (missing l10n usage caught by linter); manual review |
| AC-11 | `dart analyze` passes | `dart analyze` (0 errors required) |

## Regression guardrails

| Guardrail | Verification |
|-----------|-------------|
| Existing maintenances fetch | `MaintenanceRepositoryImpl.getMaintenancesByVehicleId` unit test |
| Delete works | `MaintenanceDeleteCubit` test; manual detail→delete |
| Update works | `MaintenanceRepositoryImpl.updateMaintenance` test |
| Form without next fields (optional) | `MaintenanceFormCubit.buildMaintenanceToSave` unit test — no crash |
| VehicleMaintenancesCubit separation | Unit: mixed list → `lastCompleted` + `nextScheduled` correct |
| Status calc edge cases | Unit: no date/no km → upToDate; km only overdue → overdue; date only → overdue |
| Filter "Todos" shows both modes | Cubit unit test |

## Critical paths to probe manually

1. Create a `completed` maintenance with next fields → two records appear in list immediately.
2. Create a `scheduled` maintenance → appears in PRÓXIMAMENTE or ATRASADO section.
3. Garage widget shows last completed (left) and next scheduled (right) as separate records.
4. Status filter "Atrasado" → only overdue scheduled records visible.

> Full detail: docs/custom-iters/prd-maintenance/handoffs/architect.md
