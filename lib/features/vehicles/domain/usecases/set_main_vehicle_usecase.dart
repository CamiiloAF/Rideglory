import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/user_main_vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/user_main_vehicle_repository.dart';

/// Use case to set a vehicle as the main vehicle for the user
///
/// This will update the user's main vehicle preference in the userMainVehicle collection
@injectable
class SetMainVehicleUseCase {
  final UserMainVehicleRepository _repository;

  SetMainVehicleUseCase(this._repository);

  Future<Either<DomainException, UserMainVehicleModel>> call(String vehicleId) {
    return _repository.setMainVehicleId(vehicleId);
  }
}
