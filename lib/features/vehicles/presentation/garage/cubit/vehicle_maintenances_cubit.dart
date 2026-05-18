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

  /// The most recent completed maintenance record for the vehicle.
  MaintenanceModel? get lastCompleted => state.whenOrNull(
    data: (list) {
      final completed = list
          .where((m) => m.mode == MaintenanceMode.completed)
          .toList();
      if (completed.isEmpty) return null;
      completed.sort((a, b) {
        final dateA = a.serviceDate ?? a.createdDate ?? DateTime(0);
        final dateB = b.serviceDate ?? b.createdDate ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
      return completed.first;
    },
  );

  /// The most urgent scheduled maintenance record for the vehicle.
  MaintenanceModel? get nextScheduled => state.whenOrNull(
    data: (list) {
      final scheduled = list
          .where((m) => m.mode == MaintenanceMode.scheduled)
          .toList();
      if (scheduled.isEmpty) return null;
      // Sort by urgency: earliest nextDate or smallest nextOdometer
      scheduled.sort((a, b) {
        if (a.nextDate != null && b.nextDate != null) {
          return a.nextDate!.compareTo(b.nextDate!);
        }
        if (a.nextDate != null) return -1;
        if (b.nextDate != null) return 1;
        return 0;
      });
      return scheduled.first;
    },
  );

  Future<void> fetchMaintenances(String vehicleId) async {
    emit(const ResultState.loading());
    final result = await _getMaintenancesByVehicleIdUseCase.execute(vehicleId);

    if (isClosed) return;
    result.fold((error) => emit(ResultState.error(error: error)), (page) {
      final maintenances = [...page.items];
      maintenances.sort((a, b) {
        final dateA = a.serviceDate ?? a.createdDate ?? DateTime(0);
        final dateB = b.serviceDate ?? b.createdDate ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
      if (maintenances.isEmpty) {
        emit(const ResultState.empty());
      } else {
        emit(ResultState.data(data: maintenances));
      }
    });
  }

  /// Inserts the new maintenance locally when possible.
  /// Falls back to API reload if we cannot safely mutate current state.
  void addMaintenanceLocally(
    MaintenanceModel maintenance, {
    required String vehicleId,
  }) {
    state.when(
      initial: () => fetchMaintenances(vehicleId),
      loading: () => fetchMaintenances(vehicleId),
      error: (_) => fetchMaintenances(vehicleId),
      empty: () => emit(ResultState.data(data: [maintenance])),
      data: (maintenances) {
        final exists = maintenances.any((m) => m.id == maintenance.id);
        if (exists) {
          updateMaintenanceLocally(maintenance);
          return;
        }
        final updatedList = [...maintenances, maintenance]
          ..sort((a, b) {
            final dateA = a.serviceDate ?? a.createdDate ?? DateTime(0);
            final dateB = b.serviceDate ?? b.createdDate ?? DateTime(0);
            return dateB.compareTo(dateA);
          });
        emit(ResultState.data(data: updatedList));
      },
    );
  }

  void updateMaintenanceLocally(MaintenanceModel updatedMaintenance) {
    state.whenOrNull(
      data: (maintenances) {
        final updatedList = maintenances
            .map((m) => m.id == updatedMaintenance.id ? updatedMaintenance : m)
            .toList();

        // Re-sort just in case date changed
        updatedList.sort((a, b) {
          final dateA = a.serviceDate ?? a.createdDate ?? DateTime(0);
          final dateB = b.serviceDate ?? b.createdDate ?? DateTime(0);
          return dateB.compareTo(dateA);
        });

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
