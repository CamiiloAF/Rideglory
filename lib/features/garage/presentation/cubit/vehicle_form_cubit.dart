import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/usecases/archive_vehicle_usecase.dart';
import '../../domain/usecases/create_vehicle_usecase.dart';
import '../../domain/usecases/delete_vehicle_usecase.dart';
import '../../domain/usecases/set_main_vehicle_usecase.dart';
import '../../domain/usecases/unarchive_vehicle_usecase.dart';
import '../../domain/usecases/update_vehicle_usecase.dart';
import '../../domain/repository/garage_repository.dart';
import '../../domain/utils/vehicle_plate_validator.dart';
import 'vehicle_form_state.dart';

/// Alta (A2, dos pasos: placa y ficha) y edición de una moto.
///
/// Se instancia una vez por pantalla vía factory de `injectable` (no
/// `@singleton`): cada apertura del formulario tiene su propio estado. Los
/// controllers de texto viven aquí (no en un `StatefulWidget`, que esta app
/// no usa): el cubit tiene la misma vida que la pantalla y los cierra en
/// `close()`, así que la identidad del controller es estable entre
/// reconstrucciones del `BlocBuilder` y no salta el cursor al escribir.
@injectable
class VehicleFormCubit extends Cubit<VehicleFormState> {
  VehicleFormCubit(
    this._createVehicle,
    this._updateVehicle,
    this._setMainVehicle,
    this._archiveVehicle,
    this._unarchiveVehicle,
    this._deleteVehicle,
  ) : super(const VehicleFormState());

  final CreateVehicleUseCase _createVehicle;
  final UpdateVehicleUseCase _updateVehicle;
  final SetMainVehicleUseCase _setMainVehicle;
  final ArchiveVehicleUseCase _archiveVehicle;
  final UnarchiveVehicleUseCase _unarchiveVehicle;
  final DeleteVehicleUseCase _deleteVehicle;

  String? _editingVehicleId;

  final TextEditingController plateController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController engineCcController = TextEditingController();
  final TextEditingController mileageController = TextEditingController();

  bool get isEditing => _editingVehicleId != null;

  /// Carga los valores existentes y salta directo al paso de ficha.
  void startEditing(Vehicle vehicle) {
    _editingVehicleId = vehicle.id;
    plateController.text = vehicle.licensePlate ?? '';
    brandController.text = vehicle.brand;
    modelController.text = vehicle.model;
    yearController.text = vehicle.year?.toString() ?? '';
    engineCcController.text = vehicle.engineCc?.toString() ?? '';
    mileageController.text = vehicle.currentMileage.toString();
    emit(
      state.copyWith(
        step: VehicleFormStep.details,
        plate: vehicle.licensePlate ?? '',
        brand: vehicle.brand,
        model: vehicle.model,
        year: vehicle.year,
        engineCc: vehicle.engineCc,
        currentMileage: vehicle.currentMileage,
        existingImageUrl: vehicle.imageUrl,
        isMain: vehicle.isMain,
      ),
    );
  }

  Future<void> setMain() async {
    final vehicleId = _editingVehicleId;
    if (vehicleId == null) return;
    final result = await _setMainVehicle(vehicleId);
    result.fold((error) {}, (_) => emit(state.copyWith(isMain: true)));
  }

  Future<void> archive() async {
    final vehicleId = _editingVehicleId;
    if (vehicleId == null) return;
    await _archiveVehicle(vehicleId);
  }

  Future<void> unarchive() async {
    final vehicleId = _editingVehicleId;
    if (vehicleId == null) return;
    await _unarchiveVehicle(vehicleId);
  }

  Future<bool> delete() async {
    final vehicleId = _editingVehicleId;
    if (vehicleId == null) return false;
    final result = await _deleteVehicle(vehicleId);
    return result.isRight();
  }

  void plateChanged(String rawPlate) {
    final normalized = VehiclePlateValidator.normalize(rawPlate);
    emit(state.copyWith(plate: normalized, plateInvalid: false));
  }

  void continueFromPlate() {
    if (state.plate.isEmpty) return;
    final isValid = VehiclePlateValidator.isValid(state.plate);
    if (!isValid) {
      emit(state.copyWith(plateInvalid: true));
      return;
    }
    emit(state.copyWith(step: VehicleFormStep.details, plateInvalid: false));
  }

  void changePlate() {
    emit(state.copyWith(step: VehicleFormStep.plate, plateInvalid: false));
  }

  void brandSelected(String brand) {
    brandController.text = brand;
    emit(state.copyWith(brand: brand));
  }

  void modelChanged(String model) => emit(state.copyWith(model: model));

  void yearChanged(String rawYear) =>
      emit(state.copyWith(year: int.tryParse(rawYear)));

  void engineCcChanged(String rawEngineCc) {
    emit(state.copyWith(engineCc: int.tryParse(rawEngineCc)));
  }

  void mileageChanged(String rawMileage) {
    final digitsOnly = rawMileage.replaceAll('.', '');
    emit(state.copyWith(currentMileage: int.tryParse(digitsOnly) ?? 0));
  }

  void imagePicked(Uint8List bytes, String extension) {
    emit(state.copyWith(imageBytes: bytes, imageExtension: extension));
  }

  Future<void> submit() async {
    emit(state.copyWith(submission: const ResultState.loading()));

    final input = VehicleInput(
      brand: state.brand,
      model: state.model,
      year: state.year,
      engineCc: state.engineCc,
      licensePlate: state.plate.isEmpty ? null : state.plate,
      currentMileage: state.currentMileage,
      imageBytes: state.imageBytes,
      imageExtension: state.imageExtension,
    );

    final editingId = _editingVehicleId;
    final result = editingId == null
        ? await _createVehicle(input)
        : await _updateVehicle(editingId, input);

    result.fold(
      (error) =>
          emit(state.copyWith(submission: ResultState.error(error: error))),
      (vehicle) =>
          emit(state.copyWith(submission: ResultState.data(data: vehicle))),
    );
  }

  void resetSubmissionError() {
    emit(state.copyWith(submission: const ResultState.initial()));
  }

  @override
  Future<void> close() {
    plateController.dispose();
    brandController.dispose();
    modelController.dispose();
    yearController.dispose();
    engineCcController.dispose();
    mileageController.dispose();
    return super.close();
  }
}
