part of 'vehicle_form_cubit.dart';

@freezed
abstract class VehicleFormState with _$VehicleFormState {
  const VehicleFormState._();

  factory VehicleFormState({
    @Default(ResultState.initial()) ResultState<VehicleModel> vehicleResult,
    @Default(null) VehicleModel? vehicle,
  }) = _VehicleFormState;

  bool get isLoading => vehicleResult is Loading;
  bool get isEditing => vehicle != null;
}
