import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@injectable
class SetMainVehicleUseCase {
  SetMainVehicleUseCase(this._repository);

  final VehicleRepository _repository;

  Future<Either<DomainException, VehicleModel>> call(String vehicleId) {
    return _repository.setMainVehicle(vehicleId);
  }
}
