import 'package:dartz/dartz.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

abstract class VehicleRepository {
  Future<Either<DomainException, List<VehicleModel>>> getVehiclesByUserId();

  Future<Either<DomainException, VehicleModel>> addVehicle(
    VehicleModel vehicle,
  );

  Future<Either<DomainException, VehicleModel>> updateVehicle(
    VehicleModel vehicle,
  );

  Future<Either<DomainException, void>> deleteVehicle(String id);
}
