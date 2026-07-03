import 'package:dartz/dartz.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_soat_form_data.dart';

abstract class VehicleRepository {
  Future<Either<DomainException, List<VehicleModel>>> getMyVehicles();

  Future<Either<DomainException, VehicleModel>> setMainVehicle(
    String vehicleId,
  );

  Future<Either<DomainException, VehicleModel>> addVehicle(
    VehicleModel vehicle,
  );

  Future<Either<DomainException, VehicleModel>> updateVehicle(
    VehicleModel vehicle,
  );

  Future<Either<DomainException, void>> permanentlyDeleteVehicle(String id);

  Future<Either<DomainException, String>> uploadVehicleImage({
    required String vehicleId,
    required String localImagePath,
  });

  Future<Either<DomainException, VehicleSoatFormData>> upsertSoat({
    required String vehicleId,
    required VehicleSoatFormData soat,
  });

  Future<Either<DomainException, VehicleSoatFormData>> getSoat(
    String vehicleId,
  );
}
