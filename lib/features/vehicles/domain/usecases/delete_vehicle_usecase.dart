import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@injectable
class DeleteVehicleUseCase {
  final VehicleRepository _repository;

  DeleteVehicleUseCase(this._repository);

  Future<Either<DomainException, void>> call(String vehicleId) {
    return _repository.deleteVehicle(vehicleId);
  }
}
