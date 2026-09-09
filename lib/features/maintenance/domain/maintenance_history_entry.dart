import 'package:freezed_annotation/freezed_annotation.dart';

import 'maintenance.dart';

part 'maintenance_history_entry.freezed.dart';

/// Un registro del historial junto con el kilometraje del registro anterior
/// del mismo tipo, en la misma moto (para el texto "Duró X km").
@freezed
abstract class MaintenanceHistoryEntry with _$MaintenanceHistoryEntry {
  const factory MaintenanceHistoryEntry({
    required Maintenance maintenance,
    int? previousOdometer,
  }) = _MaintenanceHistoryEntry;

  const MaintenanceHistoryEntry._();

  int? get durationKm => previousOdometer == null
      ? null
      : maintenance.odometer - previousOdometer!;
}

/// Un mes del historial ("AGOSTO 2026") con sus registros, más recientes
/// primero.
@freezed
abstract class MaintenanceHistoryGroup with _$MaintenanceHistoryGroup {
  const factory MaintenanceHistoryGroup({
    required String monthLabel,
    required List<MaintenanceHistoryEntry> entries,
  }) = _MaintenanceHistoryGroup;
}
