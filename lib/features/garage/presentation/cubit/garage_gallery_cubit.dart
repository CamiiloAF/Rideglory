import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/usecases/archive_vehicle_usecase.dart';
import '../../domain/usecases/delete_vehicle_usecase.dart';
import '../../domain/usecases/get_vehicles_usecase.dart';
import '../../domain/usecases/set_main_vehicle_usecase.dart';
import '../../domain/usecases/unarchive_vehicle_usecase.dart';

/// Galería del garaje: carga las motos del rider y expone las acciones
/// rápidas de la celda (archivar, restaurar, marcar principal, eliminar).
@injectable
class GarageGalleryCubit extends Cubit<ResultState<List<Vehicle>>> {
  GarageGalleryCubit(
    this._getVehicles,
    this._archiveVehicle,
    this._unarchiveVehicle,
    this._setMainVehicle,
    this._deleteVehicle,
  ) : super(const ResultState.initial());

  final GetVehiclesUseCase _getVehicles;
  final ArchiveVehicleUseCase _archiveVehicle;
  final UnarchiveVehicleUseCase _unarchiveVehicle;
  final SetMainVehicleUseCase _setMainVehicle;
  final DeleteVehicleUseCase _deleteVehicle;

  Future<void> load() async {
    emit(const ResultState.loading());
    final result = await _getVehicles();
    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (vehicles) => emit(vehicles.isEmpty ? const ResultState.empty() : ResultState.data(data: vehicles)),
    );
  }

  Future<void> archive(String vehicleId) async {
    final result = await _archiveVehicle(vehicleId);
    result.fold((error) => emit(ResultState.error(error: error)), (_) => load());
  }

  Future<void> unarchive(String vehicleId) async {
    final result = await _unarchiveVehicle(vehicleId);
    result.fold((error) => emit(ResultState.error(error: error)), (_) => load());
  }

  Future<void> setMain(String vehicleId) async {
    final result = await _setMainVehicle(vehicleId);
    result.fold((error) => emit(ResultState.error(error: error)), (_) => load());
  }

  Future<void> delete(String vehicleId) async {
    final result = await _deleteVehicle(vehicleId);
    result.fold((error) => emit(ResultState.error(error: error)), (_) => load());
  }
}
