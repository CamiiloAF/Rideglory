import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/permissions/location_permission_handler.dart';
import 'package:rideglory/core/services/vehicle_preferences_service.dart';
import 'package:rideglory/features/splash/domain/use_cases/load_current_user_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

part 'splash_state.dart';
part 'splash_cubit.freezed.dart';

@injectable
class SplashCubit extends Cubit<SplashState> {
  final LoadCurrentUserUseCase _loadCurrentUserUseCase;
  final VehiclePreferencesService _vehiclePreferencesService;

  SplashCubit(this._loadCurrentUserUseCase, this._vehiclePreferencesService)
    : super(const SplashInitial());

  Future<void> initialize() async {
    emit(const SplashLoading());

    try {
      await LocationPermissionHandler.requestOnceOnFirstSplashOpen();
      await Future.delayed(const Duration(milliseconds: 1500));

      final currentUserResult = await _loadCurrentUserUseCase();
      currentUserResult.fold(
        (failure) => emit(SplashError(failure.message)),
        (user) => emit(
          user == null
              ? const SplashUnauthenticated()
              : const SplashAuthenticated(),
        ),
      );
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
