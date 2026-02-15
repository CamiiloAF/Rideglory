import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

part 'vehicle_state.dart';

@injectable
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

  void setCurrentVehicle(VehicleModel vehicle) {
    emit(VehicleLoaded(vehicle));
  }

  void updateMileage(int newMileage) {
    final vehicle = currentVehicle;
    if (vehicle != null) {
      emit(VehicleLoaded(vehicle.copyWith(currentMileage: newMileage)));
    }
  }

  void updateCurrentVehicle(VehicleModel vehicle) {
    emit(VehicleLoaded(vehicle));
  }

  void clearCurrentVehicle() {
    emit(const VehicleEmpty());
  }
}
