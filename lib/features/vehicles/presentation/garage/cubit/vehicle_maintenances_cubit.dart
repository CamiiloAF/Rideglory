import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';

@injectable
class VehicleMaintenancesCubit
    extends Cubit<ResultState<List<MaintenanceModel>>> {
  VehicleMaintenancesCubit(this._getMaintenancesByVehicleIdUseCase)
    : super(const ResultState.initial());

  final GetMaintenancesByVehicleIdUseCase _getMaintenancesByVehicleIdUseCase;

  Future<void> fetchMaintenances(String vehicleId) async {
    emit(const ResultState.loading());
    final result = await _getMaintenancesByVehicleIdUseCase.execute(vehicleId);

    result.fold((error) => emit(ResultState.error(error: error)), (
      maintenances,
    ) {
      // Sort from newest to oldest date
      maintenances.sort((a, b) => b.date.compareTo(a.date));
      if (maintenances.isEmpty) {
        emit(const ResultState.empty());
      } else {
        emit(ResultState.data(data: maintenances));
      }
    });
  }

  void updateMaintenanceLocally(MaintenanceModel updatedMaintenance) {
    state.whenOrNull(
      data: (maintenances) {
        final updatedList = maintenances
            .map((m) => m.id == updatedMaintenance.id ? updatedMaintenance : m)
            .toList();

        // Re-sort just in case date changed
        updatedList.sort((a, b) => b.date.compareTo(a.date));

        emit(ResultState.data(data: updatedList));
      },
    );
  }

  void deleteMaintenanceLocally(String deletedId) {
    state.whenOrNull(
      data: (maintenances) {
        final updatedList = maintenances
            .where((m) => m.id != deletedId)
            .toList();

        if (updatedList.isEmpty) {
          emit(const ResultState.empty());
        } else {
          emit(ResultState.data(data: updatedList));
        }
      },
    );
  }
}
