import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@injectable
class GetVehiclesUseCase {
  final VehicleRepository _repository;

  GetVehiclesUseCase(this._repository);

  Future<Either<DomainException, List<VehicleModel>>> call() {
    return _repository.getVehiclesByUserId();
  }
}
