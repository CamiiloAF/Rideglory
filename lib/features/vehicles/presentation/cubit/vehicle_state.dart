part of 'vehicle_cubit.dart';

// TODO ELIMINAR ESTO Y USAr result state
abstract class VehicleState {
  const VehicleState();
}

class VehicleInitial extends VehicleState {
  const VehicleInitial();
}

class VehicleLoaded extends VehicleState {
  final VehicleModel vehicle;

  const VehicleLoaded(this.vehicle);
}

class VehicleEmpty extends VehicleState {
  const VehicleEmpty();
}
