import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/vehicle_preferences_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_main_vehicle_id_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';

part 'vehicle_state.dart';

@singleton
class VehicleCubit extends Cubit<VehicleState> {
  final VehiclePreferencesService _preferencesService;
  final GetMainVehicleIdUseCase _getMainVehicleIdUseCase;
  final SetMainVehicleUseCase _setMainVehicleUseCase;

  /// List of all available vehicles for the current user
  List<VehicleModel> _availableVehicles = [];

  VehicleCubit(
    this._preferencesService,
    this._getMainVehicleIdUseCase,
    this._setMainVehicleUseCase,
  ) : super(const VehicleInitial());

  VehicleModel? get currentVehicle {
    final currentState = state;
    if (currentState is VehicleLoaded) {
      return currentState.vehicle;
    }
    return null;
  }

  int? get currentMileage => currentVehicle?.currentMileage;
  List<VehicleModel> get availableVehicles => _availableVehicles;

  Future<void> setCurrentVehicle(VehicleModel vehicle) async {
    emit(VehicleLoaded(vehicle));
    if (vehicle.id != null) {
      await _preferencesService.saveSelectedVehicleId(vehicle.id!);
    }
  }

  /// Load saved vehicle from a list of vehicles and store the list
  Future<void> loadSavedVehicle(List<VehicleModel> vehicles) async {
    _availableVehicles = vehicles;

    if (vehicles.isEmpty) {
      emit(const VehicleEmpty());
      return;
    }

    // Try to get the main vehicle ID from the use case
    final mainVehicleIdResult = await _getMainVehicleIdUseCase();

    VehicleModel? vehicleToSelect;

    // First, try to find the main vehicle by ID from the use case
    mainVehicleIdResult.fold(
      (error) {
        // Silently handle error
        if (kDebugMode) {
          print('Error getting main vehicle: ${error.message}');
        }
      },
      (mainVehicleId) {
        if (mainVehicleId != null) {
          vehicleToSelect = vehicles.firstWhereOrNull(
            (v) => v.id == mainVehicleId,
          );
        }
      },
    );

    // Fall back to the first vehicle
    vehicleToSelect ??= vehicles.first;

    await setCurrentVehicle(vehicleToSelect!);
  }

  void updateMileage(int newMileage) {
    final vehicle = currentVehicle;
    if (vehicle != null) {
      emit(VehicleLoaded(vehicle.copyWith(currentMileage: newMileage)));
    }
  }

  /// Updates the current vehicle if the edited vehicle ID matches the current one
  void updateCurrentVehicleIfMatch(
    VehicleModel updatedVehicle, {
    bool shouldUpdateMainVehicle = false,
  }) {
    final current = currentVehicle;
    if (current != null && current.id == updatedVehicle.id) {
      emit(VehicleLoaded(updatedVehicle));
    }

    if (shouldUpdateMainVehicle) {
      if (!_availableVehicles.contains(updatedVehicle)) {
        _availableVehicles.add(updatedVehicle);
      }

      setMainVehicle(updatedVehicle.id!);
    }

    // Also update in available vehicles
    _availableVehicles = _availableVehicles.map((v) {
      return v.id == updatedVehicle.id ? updatedVehicle : v;
    }).toList();
  }

  Future<void> setMainVehicle(String vehicleId) async {
    final mainVehicle = _availableVehicles.firstWhereOrNull(
      (v) => v.id == vehicleId,
    );

    if (mainVehicle != null) {
      final result = await _setMainVehicleUseCase(vehicleId);

      result.fold(
        (error) {
          if (kDebugMode) {
            print('Error setting main vehicle: ${error.message}');
          }
        },
        (_) {
          setCurrentVehicle(mainVehicle);
        },
      );
    }
  }

  /// Update the available vehicles list
  void updateAvailableVehicles(List<VehicleModel> vehicles) {
    _availableVehicles = vehicles;
  }

  void addVehicleLocally(VehicleModel vehicle) {
    _availableVehicles = [..._availableVehicles, vehicle];

    if (_availableVehicles.length == 1) {
      setCurrentVehicle(vehicle);
    }
  }

  /// Remove a vehicle from the available vehicles list without refetching
  Future<void> deleteVehicleLocally(String vehicleId) async {
    final wasCurrentVehicle = currentVehicle?.id == vehicleId;

    _availableVehicles = _availableVehicles
        .where((v) => v.id != vehicleId)
        .toList();

    // If the deleted vehicle was the current one, select another
    if (wasCurrentVehicle) {
      if (_availableVehicles.isEmpty) {
        await clearCurrentVehicle();
      } else {
        await setCurrentVehicle(_availableVehicles.first);
      }
    }
  }

  /// Clear the current vehicle and remove from preferences
  Future<void> clearCurrentVehicle() async {
    emit(const VehicleEmpty());
    await _preferencesService.clearSelectedVehicleId();
    _availableVehicles = [];
  }
}

extension _FirstWhereOrNullExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
