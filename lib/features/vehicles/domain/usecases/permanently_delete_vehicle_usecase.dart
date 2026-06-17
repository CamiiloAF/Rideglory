import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@injectable
class PermanentlyDeleteVehicleUseCase {
  PermanentlyDeleteVehicleUseCase(this._vehicleRepository);

  final VehicleRepository _vehicleRepository;

  Future<Either<DomainException, void>> call(String vehicleId) {
    return _vehicleRepository.permanentlyDeleteVehicle(vehicleId);
  }
}
