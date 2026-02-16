import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/vehicle_preferences_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

part 'vehicle_state.dart';

@injectable
class VehicleCubit extends Cubit<VehicleState> {
  final VehiclePreferencesService _preferencesService;

  VehicleCubit(this._preferencesService) : super(const VehicleInitial());

  VehicleModel? get currentVehicle {
    final currentState = state;
    if (currentState is VehicleLoaded) {
      return currentState.vehicle;
    }
    return null;
  }

  int? get currentMileage => currentVehicle?.currentMileage;

  Future<void> setCurrentVehicle(VehicleModel vehicle) async {
    emit(VehicleLoaded(vehicle));
    if (vehicle.id != null) {
      await _preferencesService.saveSelectedVehicleId(vehicle.id!);
    }
  }

  /// Load saved vehicle from a list of vehicles
  Future<void> loadSavedVehicle(List<VehicleModel> vehicles) async {
    if (vehicles.isEmpty) {
      emit(const VehicleEmpty());
      return;
    }

    final savedVehicleId = await _preferencesService.getSelectedVehicleId();

    if (savedVehicleId != null) {
      // Try to find the saved vehicle in the list
      final savedVehicle = vehicles.firstWhere(
        (v) => v.id == savedVehicleId,
        orElse: () => vehicles.first,
      );
      await setCurrentVehicle(savedVehicle);
    } else {
      // No saved vehicle, select the first one
      await setCurrentVehicle(vehicles.first);
    }
  }

  void updateMileage(int newMileage) {
    final vehicle = currentVehicle;
    if (vehicle != null) {
      emit(VehicleLoaded(vehicle.copyWith(currentMileage: newMileage)));
    }
  }

  Future<void> updateCurrentVehicle(VehicleModel vehicle) async {
    emit(VehicleLoaded(vehicle));
    if (vehicle.id != null) {
      await _preferencesService.saveSelectedVehicleId(vehicle.id!);
    }
  }

  Future<void> clearCurrentVehicle() async {
    emit(const VehicleEmpty());
    await _preferencesService.clearSelectedVehicleId();
  }
}
