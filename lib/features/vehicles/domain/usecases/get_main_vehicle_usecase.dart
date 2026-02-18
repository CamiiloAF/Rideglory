import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/user_main_vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/user_main_vehicle_repository.dart';

/// Use case to get the main vehicle preference for the current user
@injectable
class GetMainVehicleUseCase {
  final UserMainVehicleRepository _repository;

  GetMainVehicleUseCase(this._repository);

  Future<Either<DomainException, UserMainVehicleModel?>> call() {
    return _repository.getMainVehicle();
  }
}
