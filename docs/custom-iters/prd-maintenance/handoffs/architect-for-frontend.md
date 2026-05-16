> Slim handoff for /custom-iter prd-maintenance. Full detail in docs/custom-iters/prd-maintenance/handoffs/architect.md (read only if ambiguous).

## Feature path
`lib/features/maintenance/` and `lib/features/vehicles/presentation/garage/`

## New / updated domain model

### `MaintenanceMode` enum (in `maintenance_model.dart`)
```dart
enum MaintenanceMode { completed, scheduled }
```

### `MaintenanceStatus` enum (in `maintenance_model.dart`)
```dart
enum MaintenanceStatus { overdue, next, upToDate }
// Only applies to mode==scheduled; completed records never have a status badge.
```

### `MaintenanceModel` updated fields
```dart
// REPLACE: isScheduled:bool, date:DateTime (required)
// WITH:
final MaintenanceMode mode;
final DateTime? serviceDate;        // only for mode==completed
final int? odometerAtService;       // only for mode==completed; maps DTO 'maintanceMileage' for completed
final String? workshop;             // new
final int? nextOdometer;            // absolute km for next service
final DateTime? nextDate;           // was nextMaintenanceDate — keep same DTO key

// ADD static method:
static MaintenanceStatus? calculateStatus(MaintenanceModel m, int currentVehicleMileage) {
  if (m.mode == MaintenanceMode.completed) return null;
  const kUmbralKm = 500;
  const kUmbralDays = 30;
  final now = DateTime.now();
  final overdueByKm = m.nextOdometer != null && currentVehicleMileage > m.nextOdometer!;
  final overdueByDate = m.nextDate != null && now.isAfter(m.nextDate!);
  if (overdueByKm || overdueByDate) return MaintenanceStatus.overdue;
  final nextByKm = m.nextOdometer != null && (m.nextOdometer! - currentVehicleMileage) <= kUmbralKm;
  final nextByDate = m.nextDate != null && m.nextDate!.difference(now).inDays <= kUmbralDays;
  if (nextByKm || nextByDate) return MaintenanceStatus.next;
  return MaintenanceStatus.upToDate;
}
```

## DTO changes

### `MaintenanceDto` — field mapping
| DTO JSON key | Old Dart field | New Dart field | Notes |
|---|---|---|---|
| `mode` | (none) | `mode: MaintenanceMode` | new |
| `date` | `date` | keep (used as `serviceDate` for completed) | keep for compat |
| `serviceDate` | (none) | `serviceDate: DateTime?` | new |
| `maintanceMileage` | `maintanceMileage: int` | `odometerAtService: int?` | renamed; nullable now |
| `workshop` | (none) | `workshop: String?` | new |
| `nextMaintenanceMileage` | `nextMaintenanceMileage: int?` | `nextOdometer: int?` | renamed |
| `nextMaintenanceDate` | `nextMaintenanceDate: DateTime?` | `nextDate: DateTime?` | renamed |
| `isScheduled` | `isScheduled: bool` | keep reading for old records compat | keep reading, derive mode |

### New DTO: `CreateMaintenanceResponseDto`
```dart
// lib/features/maintenance/data/dto/create_maintenance_response_dto.dart
@JsonSerializable(converters: apiJsonDateTimeConverters)
class CreateMaintenanceResponseDto {
  final List<MaintenanceDto> created;
  // fromJson / toJson
}
```

## Repository/Use case signature changes

```dart
// maintenance_repository.dart
Future<Either<DomainException, List<MaintenanceModel>>> addMaintenance(MaintenanceModel m);

// add_maintenance_use_case.dart
Future<Either<DomainException, List<MaintenanceModel>>> call(MaintenanceModel m);
```

## Form cubit changes

- `buildMaintenanceToSave()`: populate new fields (`mode`, `serviceDate`, `odometerAtService`, `workshop`, `nextOdometer` as relative interval for sending — backend computes absolute).
- On save success, `MaintenanceFormCubit` receives `List<MaintenanceModel>` and calls `MaintenancesCubit.addMaintenancesLocally(list)`.
- New method needed on `MaintenancesCubit`: `addMaintenancesLocally(List<MaintenanceModel>)`.

## MaintenancesCubit — status + grouping

- Status calc: call `MaintenanceModel.calculateStatus(m, vehicle.currentMileage)` for each scheduled record.
- Emission ordering: overdue first → next → upToDate → completed (by serviceDate desc).
- Sections: the cubit emits `ResultState<List<MaintenanceModel>>` — the list is ordered such that list widgets can group by status. Alternatively, the cubit may expose a `groupedMaintenances` getter for the widget to read sections.

## VehicleMaintenancesCubit changes

Add two getters:
```dart
MaintenanceModel? get lastCompleted {
  return state.whenOrNull(
    data: (list) => list.where((m) => m.mode == MaintenanceMode.completed).firstOrNull,
  );
}

MaintenanceModel? get nextScheduled {
  // Most urgent scheduled record
  return state.whenOrNull(
    data: (list) {
      final scheduled = list.where((m) => m.mode == MaintenanceMode.scheduled).toList();
      if (scheduled.isEmpty) return null;
      // Sort by urgency: overdue first, then next, then upToDate
      // (requires vehicle mileage — pass via cubit or calculate based on date only for widget)
      return scheduled.first; // sorted by urgency in fetchMaintenances
    },
  );
}
```

## Garage widget

`VehicleMaintenanceHistorySection`: Pass `vehicle` to cubit. In `_MaintenanceCards`:
- Left card uses `cubit.lastCompleted`
- Right card uses `cubit.nextScheduled`
- Each card tap → `context.pushNamed(AppRoutes.maintenanceDetail, extra: record)`

## l10n keys to add (app_es.arb)

```json
"maintenance_modeCompleted": "Realizado",
"maintenance_modeScheduled": "Programado",
"maintenance_statusOverdue": "Vencido",
"maintenance_statusNext": "Próximo",
"maintenance_statusUpToDate": "Al día",
"maintenance_workshop": "Taller / Mecánico",
"maintenance_odometerAtService": "Odómetro al servicio",
"maintenance_serviceDate": "Fecha del servicio",
"maintenance_nextKmIn": "Próximos km en",
"maintenance_nextDate": "Fecha programada",
"maintenance_nextOdometer": "Próximo odómetro",
"maintenance_scheduledSectionTitle": "PRÓXIMAMENTE",
"maintenance_overdueSectionTitle": "ATRASADO",
"maintenance_upToDateSectionTitle": "AL DÍA",
"maintenance_validationNextFieldRequired": "Agrega al menos un criterio para el próximo servicio (km o fecha).",
"maintenance_validationNextDateMustBeFuture": "La fecha del próximo servicio debe ser futura",
"maintenance_validationServiceDateRequired": "La fecha del servicio es requerida",
"maintenance_validationOdometerRequired": "El odómetro es requerido",
"maintenance_noNextService": "Sin próximo servicio",
"maintenance_noServicesRegistered": "Sin servicios registrados"
```

## Run `dart run build_runner build --delete-conflicting-outputs` after editing any DTO.

> Full detail: docs/custom-iters/prd-maintenance/handoffs/architect.md
