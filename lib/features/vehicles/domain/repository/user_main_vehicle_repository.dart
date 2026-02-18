import 'package:dartz/dartz.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/user_main_vehicle_model.dart';

abstract class UserMainVehicleRepository {
  /// Get the main vehicle preference for the current user
  Future<Either<DomainException, UserMainVehicleModel?>> getMainVehicle();

  /// Get only the main vehicle ID for the current user
  Future<Either<DomainException, String?>> getMainVehicleId();

  /// Set the main vehicle for the current user
  Future<Either<DomainException, UserMainVehicleModel>> setMainVehicleId(
    String vehicleId,
  );
}
