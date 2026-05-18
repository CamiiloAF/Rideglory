import 'package:dartz/dartz.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/soat_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

abstract class VehicleRepository {
  Future<Either<DomainException, List<VehicleModel>>> getMyVehicles();

  Future<Either<DomainException, VehicleModel>> setMainVehicle(String vehicleId);

  Future<Either<DomainException, VehicleModel>> addVehicle(
    VehicleModel vehicle,
  );

  Future<Either<DomainException, VehicleModel>> updateVehicle(
    VehicleModel vehicle,
  );

  Future<Either<DomainException, void>> deleteVehicle(String id);

  Future<Either<DomainException, String>> uploadVehicleImage({
    required String vehicleId,
    required String localImagePath,
  });

  Future<Either<DomainException, SoatModel>> upsertSoat({
    required String vehicleId,
    required SoatModel soat,
  });

  Future<Either<DomainException, SoatModel>> getSoat(String vehicleId);
}
