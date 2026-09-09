import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/models/vehicle.dart';

part 'vehicle_form_state.freezed.dart';

/// Paso del flujo de alta: primero la placa (A2), luego el resto de la
/// ficha. En edición se entra directo en [details].
enum VehicleFormStep { plate, details }

/// Estado del alta/edición de una moto. Un único resultado asíncrono
/// (guardar), así que basta un `ResultState<Vehicle>` dentro de la clase de
/// estado en vez de un cubit por paso.
@freezed
abstract class VehicleFormState with _$VehicleFormState {
  const factory VehicleFormState({
    @Default(VehicleFormStep.plate) VehicleFormStep step,
    @Default('') String plate,
    @Default(false) bool plateInvalid,
    @Default('') String brand,
    @Default('') String model,
    int? year,
    int? engineCc,
    @Default(0) int currentMileage,
    @Default(false) bool isMain,
    Uint8List? imageBytes,
    String? imageExtension,
    String? existingImageUrl,
    @Default(ResultState<Vehicle>.initial()) ResultState<Vehicle> submission,
  }) = _VehicleFormState;

  const VehicleFormState._();

  bool get canContinueFromPlate => plate.isNotEmpty && !plateInvalid;

  bool get canSubmitDetails => brand.isNotEmpty && model.isNotEmpty;
}
