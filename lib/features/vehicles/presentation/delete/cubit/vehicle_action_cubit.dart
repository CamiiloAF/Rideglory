import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/archive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/permanently_delete_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/unarchive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

part 'vehicle_action_cubit.freezed.dart';
part 'vehicle_action_state.dart';

@injectable
class VehicleActionCubit extends Cubit<VehicleActionState> {
  VehicleActionCubit(
    this._permanentlyDeleteVehicleUseCase,
    this._archiveVehicleUseCase,
    this._unarchiveVehicleUseCase,
    this._vehicleCubit,
    this._analytics,
  ) : super(const VehicleActionState.initial());

  final PermanentlyDeleteVehicleUseCase _permanentlyDeleteVehicleUseCase;
  final ArchiveVehicleUseCase _archiveVehicleUseCase;
  final UnarchiveVehicleUseCase _unarchiveVehicleUseCase;
  final VehicleCubit _vehicleCubit;
  final AnalyticsService _analytics;

  Future<void> permanentlyDeleteVehicle(String vehicleId) async {
    if (state is _Loading) return;

    emit(const VehicleActionState.loading());

    final result = await _permanentlyDeleteVehicleUseCase(vehicleId);

    result.fold(
      (error) => emit(VehicleActionState.error(message: error.message)),
      (_) {
        _analytics.logEvent(AnalyticsEvents.vehicleDeleted).ignore();
        emit(VehicleActionState.permanentDeleteSuccess(deletedId: vehicleId));
      },
    );
  }

  Future<void> archiveVehicle(VehicleModel vehicle) async {
    emit(const VehicleActionState.loading());

    final result = await _archiveVehicleUseCase(vehicle);

    result.fold(
      (error) => emit(VehicleActionState.error(message: error.message)),
      (_) {
        _vehicleCubit.archiveLocally(vehicle.id!);
        _analytics.logEvent(AnalyticsEvents.vehicleArchived).ignore();
        emit(VehicleActionState.archiveSuccess(archivedId: vehicle.id!));
      },
    );
  }

  Future<void> unarchiveVehicle(VehicleModel vehicle) async {
    emit(const VehicleActionState.loading());

    final result = await _unarchiveVehicleUseCase(vehicle);

    result.fold(
      (error) => emit(VehicleActionState.error(message: error.message)),
      (_) {
        _vehicleCubit.unarchiveLocally(vehicle.id!);
        _analytics.logEvent(AnalyticsEvents.vehicleUnarchived).ignore();
        emit(VehicleActionState.unarchiveSuccess(unarchivedId: vehicle.id!));
      },
    );
  }

  void reset() {
    emit(const VehicleActionState.initial());
  }
}
