import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';

/// User vehicles plus UI selection (garage, dropdowns, home). When [state] is
/// [Data], `data` is always the full list; [currentVehicle] is the focused row
/// (explicit selection, else main vehicle, else first).
@singleton
class VehicleCubit extends Cubit<ResultState<List<VehicleModel>>> {
  VehicleCubit(
    this._getMyVehiclesUseCase,
    this._setMainVehicleUseCase,
    this._updateVehicleUseCase,
  ) : super(const ResultState.initial());

  final GetMyVehiclesUseCase _getMyVehiclesUseCase;
  final SetMainVehicleUseCase _setMainVehicleUseCase;
  final UpdateVehicleUseCase _updateVehicleUseCase;

  List<VehicleModel> _vehicles = [];
  String? _selectedVehicleId;

  List<VehicleModel> get availableVehicles =>
      List<VehicleModel>.unmodifiable(_vehicles);

  VehicleModel? get currentVehicle {
    if (_vehicles.isEmpty) return null;
    final id = _selectedVehicleId;
    if (id != null) {
      for (final v in _vehicles) {
        if (v.id == id) return v;
      }
    }
    return _mainVehicle(_vehicles) ?? _vehicles.first;
  }

  int? get currentMileage => currentVehicle?.currentMileage;

  Future<void> fetchMyVehicles() async {
    emit(const ResultState.loading());
    final result = await _getMyVehiclesUseCase();
    result.fold((error) => emit(ResultState.error(error: error)), (vehicles) {
      _vehicles = List<VehicleModel>.from(vehicles);
      _selectedVehicleId = _selectionIdDefault(_vehicles);
      _emitLoadedOrEmpty();
    });
  }

  void selectVehicle(VehicleModel vehicle) {
    final id = vehicle.id;
    if (id == null) return;
    _selectedVehicleId = id;
    _emitLoadedOrEmpty();
  }

  Future<void> updateMileage(int newMileage) async {
    final vehicle = currentVehicle;
    if (vehicle == null) return;
    final updated = vehicle.copyWith(currentMileage: newMileage);
    _vehicles = _vehicles.map((v) => v.id == vehicle.id ? updated : v).toList();
    _emitLoadedOrEmpty();
    await _updateVehicleUseCase(updated);
  }

  void applySavedVehicleEdit(VehicleModel updated) {
    _vehicles = _vehicles.map((v) => v.id == updated.id ? updated : v).toList();
    _emitLoadedOrEmpty();
  }

  Future<void> setMainVehicle(String vehicleId) async {
    if (!_vehicles.any((v) => v.id == vehicleId)) return;

    final result = await _setMainVehicleUseCase(vehicleId);
    result.fold((_) {}, (updated) {
      _vehicles = _vehicles
          .map((v) => v.copyWith(isMainVehicle: v.id == updated.id))
          .toList();
      _selectedVehicleId = updated.id;
      _emitLoadedOrEmpty();
    });
  }

  void addVehicleLocally(VehicleModel vehicle) {
    _vehicles = [..._vehicles, vehicle];
    if (_vehicles.length == 1) {
      _selectedVehicleId = vehicle.id;
    }
    _emitLoadedOrEmpty();
  }

  void updateSoatLocally(String vehicleId, {required DateTime expiryDate}) {
    _vehicles = _vehicles.map((v) {
      if (v.id != vehicleId) return v;
      return v.copyWith(
        soatStatus: _soatStatusFrom(expiryDate),
        soatExpiryDate: expiryDate,
      );
    }).toList();
    _emitLoadedOrEmpty();
  }

  SoatStatus _soatStatusFrom(DateTime expiryDate) {
    final daysRemaining = expiryDate.difference(DateTime.now()).inDays;
    if (daysRemaining < 0) return SoatStatus.expired;
    if (daysRemaining <= 30) return SoatStatus.expiringSoon;
    return SoatStatus.valid;
  }

  void deleteVehicleLocally(String vehicleId) {
    final wasSelection =
        currentVehicle?.id == vehicleId || _selectedVehicleId == vehicleId;

    _vehicles = _vehicles.where((v) => v.id != vehicleId).toList();

    if (_vehicles.isEmpty) {
      _selectedVehicleId = null;
      emit(const ResultState.empty());
      return;
    }

    if (wasSelection) {
      _selectedVehicleId = _selectionIdDefault(_vehicles);
    }
    _emitLoadedOrEmpty();
  }

  void clearVehicles() {
    _vehicles = [];
    _selectedVehicleId = null;
    emit(const ResultState.empty());
  }

  VehicleModel? _mainVehicle(List<VehicleModel> list) {
    for (final v in list) {
      if (v.isMainVehicle) return v;
    }
    return null;
  }

  String? _selectionIdDefault(List<VehicleModel> list) {
    if (list.isEmpty) return null;
    final main = _mainVehicle(list);
    return main?.id ?? list.first.id;
  }

  void _emitLoadedOrEmpty() {
    if (_vehicles.isEmpty) {
      emit(const ResultState.empty());
      return;
    }
    emit(ResultState.data(data: List<VehicleModel>.from(_vehicles)));
  }
}
