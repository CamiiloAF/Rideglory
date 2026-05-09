import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@injectable
class DeleteVehicleUseCase {
  DeleteVehicleUseCase(this._vehicleRepository);

  final VehicleRepository _vehicleRepository;

  /// Backend soft-deletes related maintenances before removing the vehicle.
  Future<Either<DomainException, void>> call(String vehicleId) {
    return _vehicleRepository.deleteVehicle(vehicleId);
  }
}
