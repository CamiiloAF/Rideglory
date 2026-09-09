import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/maintenance_agenda_item.dart';
import '../../domain/usecases/get_maintenances_use_case.dart';
import '../../domain/usecases/get_vehicles_use_case.dart';
import 'maintenance_state.dart';

/// Pantalla principal: agenda + historial de todas las motos, filtrable
/// por una en concreto. Motos y mantenimientos son dos resultados
/// independientes en `MaintenanceState`.
@injectable
class MaintenanceCubit extends Cubit<MaintenanceState> {
  MaintenanceCubit(this._getVehicles, this._getMaintenances)
    : super(const MaintenanceState());

  final GetVehiclesUseCase _getVehicles;
  final GetMaintenancesUseCase _getMaintenances;

  Future<void> load() async {
    emit(
      state.copyWith(
        vehicles: const ResultState.loading(),
        maintenances: const ResultState.loading(),
      ),
    );
    await Future.wait([_loadVehicles(), _loadMaintenances()]);
  }

  Future<void> _loadVehicles() async {
    final result = await _getVehicles();
    result.fold(
      (error) =>
          emit(state.copyWith(vehicles: ResultState.error(error: error))),
      (vehicles) =>
          emit(state.copyWith(vehicles: ResultState.data(data: vehicles))),
    );
  }

  Future<void> _loadMaintenances() async {
    final result = await _getMaintenances();
    result.fold(
      (error) =>
          emit(state.copyWith(maintenances: ResultState.error(error: error))),
      (maintenances) => emit(
        state.copyWith(maintenances: ResultState.data(data: maintenances)),
      ),
    );
  }

  void selectVehicle(String? vehicleId) {
    emit(state.copyWith(selectedVehicleId: vehicleId));
  }

  void filterByStatus(MaintenanceUrgency? status) {
    emit(state.copyWith(statusFilter: status));
  }
}
