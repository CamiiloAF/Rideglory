import 'package:bloc/bloc.dart';
import 'package:rideglory/core/domain/models/vehicle_model.dart';

part 'vehicle_state.dart';

class VehicleCubit extends Cubit<VehicleState> {
  VehicleCubit() : super(const VehicleInitial());

  VehicleModel? get currentVehicle {
    final currentState = state;
    if (currentState is VehicleLoaded) {
      return currentState.vehicle;
    }
    return null;
  }

  int? get currentMileage => currentVehicle?.currentMileage;

  void setVehicle(VehicleModel vehicle) {
    emit(VehicleLoaded(vehicle));
  }

  void updateMileage(int newMileage) {
    final vehicle = currentVehicle;
    if (vehicle != null) {
      emit(VehicleLoaded(vehicle.copyWith(currentMileage: newMileage)));
    }
  }

  void updateVehicle(VehicleModel vehicle) {
    emit(VehicleLoaded(vehicle));
  }

  void clearVehicle() {
    emit(const VehicleEmpty());
  }
}
