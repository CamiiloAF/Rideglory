import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';

/// User vehicles plus UI selection (garage, dropdowns, home). When [state] is
/// [Data], `data` is always the full list; [currentVehicle] is the focused row
/// (explicit selection, else main vehicle, else first).
@injectable
class VehicleCubit extends Cubit<ResultState<List<VehicleModel>>> {
  VehicleCubit(
    this._getMyVehiclesUseCase,
    this._setMainVehicleUseCase,
    this._updateVehicleUseCase,
    this._analytics,
  ) : super(const ResultState.initial());

  final GetMyVehiclesUseCase _getMyVehiclesUseCase;
  final SetMainVehicleUseCase _setMainVehicleUseCase;
  final UpdateVehicleUseCase _updateVehicleUseCase;
  final AnalyticsService _analytics;

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
      _ensureLocalMain();
      _selectedVehicleId = _selectionIdDefault(_vehicles);
      // AC diferido de Fase 5: cablear user property has_vehicle.
      _analytics
          .setUserProperty(
            AnalyticsParams.userPropertyHasVehicle,
            _vehicles.isNotEmpty ? '1' : '0',
          )
          .ignore();
      _emitLoadedOrEmpty();
    });
  }

  void selectVehicle(VehicleModel vehicle) {
    final id = vehicle.id;
    if (id == null) return;
    _selectedVehicleId = id;
    _emitLoadedOrEmpty();
  }

  /// Actualiza el kilometraje del vehículo [vehicleId] (o el actual si es null).
  /// Solo avanza el odómetro: ignora valores menores o iguales al actual.
  Future<void> updateMileage(int newMileage, {String? vehicleId}) async {
    final targetId = vehicleId ?? currentVehicle?.id;
    if (targetId == null) return;
    final index = _vehicles.indexWhere((v) => v.id == targetId);
    if (index == -1) return;
    final vehicle = _vehicles[index];
    if (newMileage <= vehicle.currentMileage) return;
    final updated = vehicle.copyWith(currentMileage: newMileage);
    _vehicles = _vehicles.map((v) => v.id == targetId ? updated : v).toList();
    _emitLoadedOrEmpty();
    await _updateVehicleUseCase(updated);
  }

  void applySavedVehicleEdit(VehicleModel updated) {
    _vehicles = _vehicles.map((v) => v.id == updated.id ? updated : v).toList();
    _emitLoadedOrEmpty();
  }

  Future<String?> setMainVehicle(String vehicleId) async {
    if (!_vehicles.any((v) => v.id == vehicleId)) return null;

    final result = await _setMainVehicleUseCase(vehicleId);
    return result.fold(
      (error) => error.message,
      (updated) {
        _vehicles = _vehicles
            .map((v) => v.copyWith(isMainVehicle: v.id == updated.id))
            .toList();
        _selectedVehicleId = updated.id;
        _analytics.logEvent(AnalyticsEvents.vehicleSetMain).ignore();
        _emitLoadedOrEmpty();
        return null;
      },
    );
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

  void clearSoatLocally(String vehicleId) {
    _vehicles = _vehicles.map((v) {
      if (v.id != vehicleId) return v;
      // copyWith no puede setear `soatExpiryDate` a null (usa `?? this`), así
      // que reconstruimos el modelo dejando el SOAT explícitamente vacío.
      return VehicleModel(
        id: v.id,
        name: v.name,
        brand: v.brand,
        model: v.model,
        year: v.year,
        currentMileage: v.currentMileage,
        licensePlate: v.licensePlate,
        vin: v.vin,
        purchaseDate: v.purchaseDate,
        imageUrl: v.imageUrl,
        createdAt: v.createdAt,
        updatedAt: v.updatedAt,
        isArchived: v.isArchived,
        isMainVehicle: v.isMainVehicle,
        soatStatus: SoatStatus.noSoat,
        color: v.color,
        engine: v.engine,
        horsepower: v.horsepower,
        torque: v.torque,
        weight: v.weight,
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

  void archiveLocally(String id) {
    final wasMain = _vehicles.any((v) => v.id == id && v.isMainVehicle);

    _vehicles = _vehicles.map((v) {
      if (v.id != id) return v;
      return v.copyWith(isArchived: true, isMainVehicle: false);
    }).toList();

    if (wasMain) {
      final actives = _vehicles.where((v) => !v.isArchived).toList();
      _promoteNewMain(actives);
    }

    _emitLoadedOrEmpty();
  }

  void unarchiveLocally(String id) {
    _vehicles = _vehicles.map((v) {
      if (v.id != id) return v;
      return v.copyWith(isArchived: false);
    }).toList();

    final hasActiveMain = _vehicles.any((v) => !v.isArchived && v.isMainVehicle);
    if (!hasActiveMain) {
      _vehicles = _vehicles.map((v) {
        if (v.id != id) return v;
        return v.copyWith(isMainVehicle: true);
      }).toList();
    }

    _emitLoadedOrEmpty();
  }

  void deleteLocally(String id) {
    _vehicles = _vehicles.where((v) => v.id != id).toList();
    if (_selectedVehicleId == id) {
      _selectedVehicleId = _selectionIdDefault(_vehicles);
    }
    _emitLoadedOrEmpty();
  }

  /// Promotes the first active (non-archived) vehicle to main. Ordering:
  /// createdAt desc (nulls last), then id asc as tie-break.
  void _promoteNewMain(List<VehicleModel> actives) {
    if (actives.isEmpty) return;

    final sorted = [...actives]..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) {
          return (a.id ?? '').compareTo(b.id ?? '');
        }
        if (aDate == null) return 1; // nulls last
        if (bDate == null) return -1;
        final cmp = bDate.compareTo(aDate); // desc
        if (cmp != 0) return cmp;
        return (a.id ?? '').compareTo(b.id ?? ''); // tie-break asc
      });

    final newMainId = sorted.first.id;
    _vehicles = _vehicles.map((v) {
      if (v.id == newMainId) return v.copyWith(isMainVehicle: true);
      if (v.isMainVehicle) return v.copyWith(isMainVehicle: false);
      return v;
    }).toList();
    _selectedVehicleId = newMainId;
  }

  void clearVehicles() {
    _vehicles = [];
    _selectedVehicleId = null;
    emit(const ResultState.empty());
  }

  void _ensureLocalMain() {
    final actives = _vehicles.where((v) => !v.isArchived).toList();
    if (actives.isEmpty || actives.any((v) => v.isMainVehicle)) return;
    final firstId = actives.first.id;
    _vehicles = _vehicles
        .map((v) => v.copyWith(isMainVehicle: v.id == firstId))
        .toList();
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
