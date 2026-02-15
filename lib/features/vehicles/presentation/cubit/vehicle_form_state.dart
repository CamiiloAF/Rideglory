part of 'vehicle_form_cubit.dart';

abstract class VehicleFormState {
  const VehicleFormState();
}

class VehicleFormInitial extends VehicleFormState {
  const VehicleFormInitial();
}

class VehicleFormEditing extends VehicleFormState {
  final VehicleModel vehicle;

  const VehicleFormEditing(this.vehicle);
}

class VehicleFormLoading extends VehicleFormState {
  const VehicleFormLoading();
}

class VehicleFormSuccess extends VehicleFormState {
  final VehicleModel vehicle;

  const VehicleFormSuccess(this.vehicle);
}

class VehicleFormError extends VehicleFormState {
  final String message;

  const VehicleFormError(this.message);
}
