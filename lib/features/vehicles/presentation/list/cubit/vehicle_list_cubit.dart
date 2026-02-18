import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

@injectable
class VehicleListCubit extends Cubit<ResultState<List<VehicleModel>>> {
  VehicleListCubit(
    this._getVehiclesUseCase,
    this._vehicleCubit,
  ) : super(const ResultState.initial());

  final GetVehiclesUseCase _getVehiclesUseCase;
  final VehicleCubit _vehicleCubit;

  Future<void> loadVehicles() async {
    emit(const ResultState.loading());
    final result = await _getVehiclesUseCase();

    result.fold((error) => emit(ResultState.error(error: error)), (vehicles) {
      if (vehicles.isEmpty) {
        emit(const ResultState.empty());
      } else {
        emit(ResultState.data(data: vehicles));
        _vehicleCubit.updateAvailableVehicles(vehicles);
      }
    });
  }

  void removeVehicleFromList(String vehicleId) {
    final currentState = state;
    if (currentState is Data<List<VehicleModel>>) {
      final updatedVehicles = currentState.data
          .where((vehicle) => vehicle.id != vehicleId)
          .toList();
      if (updatedVehicles.isEmpty) {
        emit(const ResultState.empty());
      } else {
        emit(ResultState.data(data: updatedVehicles));
        _vehicleCubit.updateAvailableVehicles(updatedVehicles);
      }
    }
  }
}
