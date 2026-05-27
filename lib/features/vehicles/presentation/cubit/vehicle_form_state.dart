part of 'vehicle_form_cubit.dart';

/// Datos del SOAT capturados manualmente durante la creación del vehículo.
/// Se guardan en el backend justo después de que el vehículo es creado.
class PendingManualSoat {
  const PendingManualSoat({
    this.policyNumber,
    required this.insurer,
    required this.startDate,
    required this.expiryDate,
    this.localImagePath,
  });

  final String? policyNumber;
  final String insurer;
  final DateTime startDate;
  final DateTime expiryDate;

  /// Ruta local de la foto del documento SOAT seleccionada durante la creación
  /// del vehículo. Se sube al backend justo después de crear el vehículo.
  final String? localImagePath;
}

@freezed
abstract class VehicleFormState with _$VehicleFormState {
  const VehicleFormState._();

  factory VehicleFormState({
    @Default(ResultState.initial()) ResultState<VehicleModel> vehicleResult,
    @Default(null) VehicleModel? vehicle,
    @Default(null) String? localImagePath,
    @Default(null) String? soatLocalPath,
    @Default(null) String? techReviewLocalPath,
    @Default(null) PendingManualSoat? pendingManualSoat,
  }) = _VehicleFormState;

  bool get isLoading => vehicleResult is Loading;
  bool get isEditing => vehicle != null;
}
