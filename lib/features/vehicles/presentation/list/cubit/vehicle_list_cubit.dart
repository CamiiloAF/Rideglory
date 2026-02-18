import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/archive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/unarchive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

@injectable
class VehicleListCubit extends Cubit<ResultState<List<VehicleModel>>> {
  VehicleListCubit(
    this._getVehiclesUseCase,
    this._vehicleCubit,
    this._archiveVehicleUseCase,
    this._unarchiveVehicleUseCase,
  ) : super(const ResultState.initial());

  final GetVehiclesUseCase _getVehiclesUseCase;
  final VehicleCubit _vehicleCubit;
  final ArchiveVehicleUseCase _archiveVehicleUseCase;
  final UnarchiveVehicleUseCase _unarchiveVehicleUseCase;

  bool _showArchivedVehicles = false;
  List<VehicleModel> _allVehicles = [];

  bool get showArchivedVehicles => _showArchivedVehicles;
  List<VehicleModel> get activeVehicles =>
      _allVehicles.where((v) => !v.isArchived).toList();

  Future<void> loadVehicles() async {
    emit(const ResultState.loading());
    final result = await _getVehiclesUseCase();

    result.fold((error) => emit(ResultState.error(error: error)), (vehicles) {
      _allVehicles = vehicles;
      _filterAndEmitVehicles();
    });
  }

  void toggleShowArchived() {
    _showArchivedVehicles = !_showArchivedVehicles;
    _filterAndEmitVehicles();
  }

  void _filterAndEmitVehicles() {
    final filteredVehicles = _showArchivedVehicles
        ? _allVehicles.where((v) => v.isArchived).toList()
        : _allVehicles.where((v) => !v.isArchived).toList();

    if (filteredVehicles.isEmpty) {
      emit(const ResultState.empty());
    } else {
      emit(ResultState.data(data: filteredVehicles));
      // Only update available vehicles with non-archived ones
      final activeVehicles = _allVehicles.where((v) => !v.isArchived).toList();
      _vehicleCubit.updateAvailableVehicles(activeVehicles);
    }
  }

  Future<void> archiveVehicle(VehicleModel vehicle) async {
    final result = await _archiveVehicleUseCase(vehicle);
    result.fold(
      (error) {
        // Handle error if needed
      },
      (archivedVehicle) async {
        // Update the vehicle in the list
        _allVehicles = _allVehicles.map((v) {
          return v.id == archivedVehicle.id ? archivedVehicle : v;
        }).toList();

        // If the archived vehicle was the current/main vehicle,
        // set another active vehicle as main
        final currentVehicle = _vehicleCubit.currentVehicle;
        if (currentVehicle?.id == archivedVehicle.id) {
          final activeVehicles = _allVehicles
              .where((v) => !v.isArchived)
              .toList();
          if (activeVehicles.isNotEmpty) {
            await _vehicleCubit.setMainVehicle(activeVehicles.first.id!);
          }
        }

        _filterAndEmitVehicles();
      },
    );
  }

  Future<void> unarchiveVehicle(VehicleModel vehicle) async {
    final result = await _unarchiveVehicleUseCase(vehicle);
    result.fold(
      (error) {
        // Handle error if needed
      },
      (unarchivedVehicle) {
        // Update the vehicle in the list
        _allVehicles = _allVehicles.map((v) {
          return v.id == unarchivedVehicle.id ? unarchivedVehicle : v;
        }).toList();
        _filterAndEmitVehicles();
      },
    );
  }

  void removeVehicleFromList(String vehicleId) {
    _allVehicles = _allVehicles.where((v) => v.id != vehicleId).toList();
    _filterAndEmitVehicles();
  }
}
