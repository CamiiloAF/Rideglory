import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/maintenance.dart';
import '../../domain/maintenance_agenda_calculator.dart';
import '../../domain/maintenance_agenda_item.dart';
import '../../domain/maintenance_history_entry.dart';
import '../../domain/maintenance_history_grouping.dart';
import '../../domain/vehicle_option.dart';

part 'maintenance_state.freezed.dart';

/// Dos resultados independientes (motos e historial), cada uno con su
/// propio `ResultState`: el filtro por moto y las vistas derivadas
/// (agenda, historial agrupado) se calculan sobre ambos, no son un tercer
/// resultado async.
@freezed
abstract class MaintenanceState with _$MaintenanceState {
  const factory MaintenanceState({
    @Default(ResultState<List<VehicleOption>>.initial())
    ResultState<List<VehicleOption>> vehicles,
    @Default(ResultState<List<Maintenance>>.initial())
    ResultState<List<Maintenance>> maintenances,
    String? selectedVehicleId,
    MaintenanceUrgency? statusFilter,
  }) = _MaintenanceState;

  const MaintenanceState._();

  List<VehicleOption> get vehicleList =>
      vehicles.whenOrNull(data: (data) => data) ?? const [];

  List<Maintenance> get maintenanceList =>
      maintenances.whenOrNull(data: (data) => data) ?? const [];

  bool get isLoading =>
      vehicles.maybeWhen(
        loading: () => true,
        initial: () => true,
        orElse: () => false,
      ) ||
      maintenances.maybeWhen(
        loading: () => true,
        initial: () => true,
        orElse: () => false,
      );

  bool get hasError =>
      vehicles.maybeWhen(error: (_) => true, orElse: () => false) ||
      maintenances.maybeWhen(error: (_) => true, orElse: () => false);

  List<Maintenance> get _filteredMaintenances => selectedVehicleId == null
      ? maintenanceList
      : maintenanceList
            .where((item) => item.vehicleId == selectedVehicleId)
            .toList();

  bool get isEmpty => !isLoading && !hasError && maintenanceList.isEmpty;

  List<MaintenanceAgendaItem> get agendaItems {
    final items = MaintenanceAgendaCalculator.compute(
      maintenances: _filteredMaintenances,
      vehicles: vehicleList,
      now: DateTime.now(),
    );
    if (statusFilter == null) return items;
    return items.where((item) => item.urgency == statusFilter).toList();
  }

  List<MaintenanceHistoryGroup> get historyGroups =>
      MaintenanceHistoryGrouping.build(_filteredMaintenances);
}
