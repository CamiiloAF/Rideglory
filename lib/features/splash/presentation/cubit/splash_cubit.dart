import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/core/services/vehicle_preferences_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

part 'splash_state.dart';
part 'splash_cubit.freezed.dart';

@injectable
class SplashCubit extends Cubit<SplashState> {
  final AuthService _authService;
  final VehiclePreferencesService _vehiclePreferencesService;

  SplashCubit(this._authService, this._vehiclePreferencesService)
    : super(const SplashInitial());

  Future<void> initialize() async {
    emit(const SplashLoading());

    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      // Check if user is authenticated
      final user = _authService.currentUser;

      if (user == null) {
        // User not logged in
        emit(const SplashUnauthenticated());
      } else {
        // User is authenticated
        emit(const SplashAuthenticated());
      }
    } catch (e) {
      emit(SplashError('Failed to initialize: ${e.toString()}'));
    }
  }

  Future<VehicleModel?> getSelectedVehicle(List<VehicleModel> vehicles) async {
    if (vehicles.isEmpty) {
      return null;
    }

    try {
      final selectedVehicleId = await _vehiclePreferencesService
          .getSelectedVehicleId();

      if (selectedVehicleId != null) {
        return vehicles.firstWhere(
          (vehicle) => vehicle.id == selectedVehicleId,
          orElse: () => vehicles.first,
        );
      }

      // No saved vehicle, return first one
      final firstVehicle = vehicles.first;
      if (firstVehicle.id != null) {
        await _vehiclePreferencesService.saveSelectedVehicleId(
          firstVehicle.id!,
        );
      }
      return firstVehicle;
    } catch (e) {
      return vehicles.first;
    }
  }
}
