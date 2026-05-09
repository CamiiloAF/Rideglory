import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';

// TODO REVISAR Y MEJORAR ESTO
@singleton
class VehicleCubit extends Cubit<ResultState<List<VehicleModel>>> {
  VehicleCubit(
    this._getMyVehiclesUseCase,
    this._setMainVehicleUseCase,
  ) : super(const ResultState.initial());

  final GetMyVehiclesUseCase _getMyVehiclesUseCase;
  final SetMainVehicleUseCase _setMainVehicleUseCase;

  /// List of all available vehicles for the current user
  List<VehicleModel> _availableVehicles = [];

  VehicleModel? get currentVehicle {
    final currentState = state;
    if (currentState is Data<List<VehicleModel>>) {
      return currentState.data.first;
    }
    return null;
  }

  int? get currentMileage => currentVehicle?.currentMileage;
  List<VehicleModel> get availableVehicles => _availableVehicles;

  Future<void> fetchMyVehicles() async {
    emit(const ResultState.loading());
    final result = await _getMyVehiclesUseCase();
    await result.fold(
      (error) async => emit(ResultState.error(error: error)),
      (vehicles) async => loadSavedVehicle(vehicles),
    );
  }

  Future<void> setCurrentVehicle(VehicleModel vehicle) async {
    emit(ResultState.data(data: [vehicle]));
  }

  Future<void> loadSavedVehicle(List<VehicleModel> vehicles) async {
    _availableVehicles = vehicles;

    if (vehicles.isEmpty) {
      emit(const ResultState.empty());
      return;
    }

    VehicleModel? vehicleToSelect;
    for (final v in vehicles) {
      if (v.isMainVehicle) {
        vehicleToSelect = v;
        break;
      }
    }
    vehicleToSelect ??= vehicles.first;

    await setCurrentVehicle(vehicleToSelect);
  }

  void updateMileage(int newMileage) {
    final vehicle = currentVehicle;
    if (vehicle != null) {
      emit(
        ResultState.data(data: [vehicle.copyWith(currentMileage: newMileage)]),
      );
    }
  }

  /// Updates the current vehicle if the edited vehicle ID matches the current one
  void updateCurrentVehicleIfMatch(
    VehicleModel updatedVehicle, {
    bool shouldUpdateMainVehicle = false,
  }) {
    final current = currentVehicle;
    final isEditingCurrent = current != null && current.id == updatedVehicle.id;

    if (shouldUpdateMainVehicle) {
      if (!_availableVehicles.contains(updatedVehicle)) {
        _availableVehicles.add(updatedVehicle);
      }

      setMainVehicle(updatedVehicle.id!);
    }

    _availableVehicles = _availableVehicles.map((v) {
      return v.id == updatedVehicle.id ? updatedVehicle : v;
    }).toList();

    if (isEditingCurrent) {
      emit(ResultState.data(data: [updatedVehicle]));
    } else if (current != null) {
      emit(ResultState.data(data: [current]));
    } else if (_availableVehicles.isNotEmpty) {
      emit(ResultState.data(data: [_availableVehicles.first]));
    }
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
        (updated) {
          _availableVehicles = _availableVehicles
              .map(
                (v) => v.copyWith(isMainVehicle: v.id == updated.id),
              )
              .toList();
          setCurrentVehicle(
            updated.copyWith(isMainVehicle: true),
          );
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
    } else {
      final current = currentVehicle ?? vehicle;
      emit(ResultState.data(data: [current]));
    }
  }

  /// Remove a vehicle from the available vehicles list without refetching
  Future<void> deleteVehicleLocally(String vehicleId) async {
    final wasCurrentVehicle = currentVehicle?.id == vehicleId;

    _availableVehicles = _availableVehicles
        .where((v) => v.id != vehicleId)
        .toList();

    if (wasCurrentVehicle) {
      if (_availableVehicles.isEmpty) {
        await clearCurrentVehicle();
      } else {
        VehicleModel? next;
        for (final v in _availableVehicles) {
          if (v.isMainVehicle) {
            next = v;
            break;
          }
        }
        await setCurrentVehicle(next ?? _availableVehicles.first);
      }
    }
  }

  Future<void> clearCurrentVehicle() async {
    emit(const ResultState.empty());
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
