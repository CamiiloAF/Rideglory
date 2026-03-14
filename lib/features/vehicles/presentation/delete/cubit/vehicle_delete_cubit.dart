import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/delete_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

part 'vehicle_delete_cubit.freezed.dart';
part 'vehicle_delete_state.dart';

@injectable
class VehicleDeleteCubit extends Cubit<VehicleDeleteState> {
  VehicleDeleteCubit(this._deleteVehicleUseCase, this._vehicleCubit)
    : super(const VehicleDeleteState.initial());

  final DeleteVehicleUseCase _deleteVehicleUseCase;
  final VehicleCubit _vehicleCubit;

  Future<void> deleteVehicle(
    String vehicleId, {
    required List<VehicleModel> availableVehicles,
  }) async {
    emit(const VehicleDeleteState.loading());

    final result = await _deleteVehicleUseCase(vehicleId);

    result.fold(
      (error) => emit(VehicleDeleteState.error(message: error.message)),
      (_) {
        _vehicleCubit.deleteVehicleLocally(vehicleId);
        emit(VehicleDeleteState.success(deletedId: vehicleId));
      },
    );
  }

  void reset() {
    emit(const VehicleDeleteState.initial());
  }
}
