import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@injectable
class AddVehicleUseCase {
  final VehicleRepository _repository;

  AddVehicleUseCase(this._repository);

  Future<Either<DomainException, VehicleModel>> call(VehicleModel vehicle) {
    return _repository.addVehicle(vehicle);
  }
}
