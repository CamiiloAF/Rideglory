import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/repository/user_main_vehicle_repository.dart';

/// Use case to get only the main vehicle ID for the current user
@injectable
class GetMainVehicleIdUseCase {
  final UserMainVehicleRepository _repository;

  GetMainVehicleIdUseCase(this._repository);

  Future<Either<DomainException, String?>> call() {
    return _repository.getMainVehicleId();
  }
}
