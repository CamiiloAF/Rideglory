import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/maintenance.dart';
import '../../domain/maintenance_history_entry.dart';
import '../../domain/maintenance_history_grouping.dart';
import '../../domain/vehicle_option.dart';

part 'maintenance_detail_state.freezed.dart';

const _previewCount = 3;

/// Detalle de un mantenimiento: el registro en sí, sus anteriores del mismo
/// tipo/moto (derivados de la lista completa) y el estado de borrado.
@freezed
abstract class MaintenanceDetailState with _$MaintenanceDetailState {
  const factory MaintenanceDetailState({
    required Maintenance maintenance,
    @Default(ResultState<List<Maintenance>>.initial())
    ResultState<List<Maintenance>> allMaintenances,
    @Default(false) bool showAllPrevious,
    @Default(ResultState<Unit>.initial()) ResultState<Unit> deletion,
    VehicleOption? vehicle,
  }) = _MaintenanceDetailState;

  const MaintenanceDetailState._();

  List<MaintenanceHistoryEntry> get previousEntries =>
      allMaintenances.whenOrNull(
        data: (all) => MaintenanceHistoryGrouping.previousOf(maintenance, all),
      ) ??
      const [];

  List<MaintenanceHistoryEntry> get visiblePreviousEntries => showAllPrevious
      ? previousEntries
      : previousEntries.take(_previewCount).toList();

  bool get hasMorePrevious => previousEntries.length > _previewCount;

  int get hiddenPreviousCount => previousEntries.length - _previewCount;

  /// Promedio de duración (km) entre servicios del mismo tipo, sobre los
  /// tramos con dato conocido.
  int? get averageDurationKm {
    final durations = previousEntries
        .map((entry) => entry.durationKm)
        .whereType<int>()
        .toList();
    if (durations.isEmpty) return null;
    return durations.reduce((a, b) => a + b) ~/ durations.length;
  }

  bool get isDeleting => deletion is Loading<Unit>;
}
