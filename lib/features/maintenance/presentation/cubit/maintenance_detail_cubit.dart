import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../core/services/notifications/maintenance_notification_scheduler.dart';
import '../../domain/maintenance.dart';
import '../../domain/maintenance_reminder.dart';
import '../../domain/register_maintenance_params.dart';
import '../../domain/usecases/delete_maintenance_use_case.dart';
import '../../domain/usecases/get_maintenances_use_case.dart';
import '../../domain/usecases/get_vehicles_use_case.dart';
import '../../domain/usecases/update_maintenance_use_case.dart';
import 'maintenance_detail_state.dart';

/// Detalle de un mantenimiento: carga el historial completo para derivar
/// "anteriores en esta moto", maneja el borrado (cancela el recordatorio
/// local) y permite cambiar solo el intervalo del recordatorio sin pasar
/// por el asistente completo.
@injectable
class MaintenanceDetailCubit extends Cubit<MaintenanceDetailState> {
  MaintenanceDetailCubit(
    this._getMaintenances,
    this._getVehicles,
    this._deleteMaintenance,
    this._updateMaintenance,
    this._notifications,
  ) : super(
        MaintenanceDetailState(
          maintenance: Maintenance(
            id: '',
            vehicleId: '',
            vehicleDisplayName: '',
            type: '',
            serviceDate: DateTime(1970),
            odometer: 0,
          ),
        ),
      );

  final GetMaintenancesUseCase _getMaintenances;
  final GetVehiclesUseCase _getVehicles;
  final DeleteMaintenanceUseCase _deleteMaintenance;
  final UpdateMaintenanceUseCase _updateMaintenance;
  final MaintenanceNotificationScheduler _notifications;

  Future<void> start(Maintenance maintenance) async {
    emit(
      MaintenanceDetailState(
        maintenance: maintenance,
        allMaintenances: const ResultState.loading(),
      ),
    );
    final maintenancesFuture = _getMaintenances();
    final vehiclesFuture = _getVehicles();

    (await maintenancesFuture).fold(
      (error) => emit(
        state.copyWith(allMaintenances: ResultState.error(error: error)),
      ),
      (all) =>
          emit(state.copyWith(allMaintenances: ResultState.data(data: all))),
    );
    (await vehiclesFuture).fold((error) {}, (vehicles) {
      final matches = vehicles
          .where((option) => option.id == maintenance.vehicleId)
          .toList();
      if (matches.isNotEmpty) emit(state.copyWith(vehicle: matches.first));
    });
  }

  void toggleShowAllPrevious() {
    emit(state.copyWith(showAllPrevious: !state.showAllPrevious));
  }

  Future<void> updateReminder(MaintenanceReminder reminder) async {
    emit(state.copyWith(reminderUpdate: const ResultState.loading()));
    final maintenance = state.maintenance;
    final params = RegisterMaintenanceParams(
      vehicleId: maintenance.vehicleId,
      type: maintenance.type,
      serviceDate: maintenance.serviceDate,
      odometer: maintenance.odometer,
      cost: maintenance.cost,
      workshop: maintenance.workshop,
      notes: maintenance.notes,
      reminder: reminder,
    );
    final result = await _updateMaintenance(maintenance.id, params);
    result.fold(
      (error) =>
          emit(state.copyWith(reminderUpdate: ResultState.error(error: error))),
      (updated) => emit(
        state.copyWith(
          maintenance: updated,
          reminderUpdate: const ResultState.data(data: unit),
        ),
      ),
    );
  }

  Future<void> delete() async {
    emit(state.copyWith(deletion: const ResultState.loading()));
    final result = await _deleteMaintenance(state.maintenance.id);
    await result.fold(
      (error) async =>
          emit(state.copyWith(deletion: ResultState.error(error: error))),
      (_) async {
        await _notifications.cancel(state.maintenance.id);
        emit(state.copyWith(deletion: const ResultState.data(data: unit)));
      },
    );
  }
}
