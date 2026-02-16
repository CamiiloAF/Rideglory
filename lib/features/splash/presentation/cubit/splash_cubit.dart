import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/core/services/vehicle_preferences_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';

part 'splash_state.dart';
part 'splash_cubit.freezed.dart';

@injectable
class SplashCubit extends Cubit<SplashState> {
  final AuthService _authService;
  final GetVehiclesUseCase _getVehiclesUseCase;
  final VehiclePreferencesService _vehiclePreferencesService;

  SplashCubit(
    this._authService,
    this._getVehiclesUseCase,
    this._vehiclePreferencesService,
  ) : super(SplashInitial());

  Future<void> initialize() async {
    emit(SplashLoading());

    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      // Check if user is authenticated
      final user = _authService.currentUser;

      if (user == null) {
        // User not logged in, navigate to login
        emit(SplashNavigateToLogin());
        return;
      }

      // User is authenticated, load vehicles
      final vehiclesResult = await _getVehiclesUseCase();

      vehiclesResult.fold(
        (error) {
          // Error loading vehicles, still navigate but let app handle empty state
          emit(SplashNavigateToLogin());
        },
        (vehicles) async {
          if (vehicles.isEmpty) {
            // No vehicles, navigate to onboarding
            emit(SplashNavigateToOnboarding());
          } else {
            emit(SplashFetchSelectedVehicle(vehicles));
          }
        },
      );
    } catch (e) {
      emit(SplashError('Failed to initialize: ${e.toString()}'));
    }
  }

  Future<void> fetchSelectedVehicle(List<VehicleModel> vehicles) async {
    late VehicleModel selectedVehicle;
    try {
      final selectedVehicleId = await _vehiclePreferencesService
          .getSelectedVehicleId();
      selectedVehicle = vehicles.firstWhere(
        (vehicle) => vehicle.id == selectedVehicleId,
        orElse: () => throw Exception('Selected vehicle not found'),
      );
    } catch (e) {
      selectedVehicle = vehicles.first;

      await _vehiclePreferencesService.saveSelectedVehicleId(
        selectedVehicle.id!,
      );
    } finally {
      emit(SplashFetchSelectedVehicleSuccess(selectedVehicle));
      emit(SplashNavigateToHome());
    }
  }
}
