import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../models/vehicle.dart';
import '../repository/garage_repository.dart';

@injectable
class UpdateVehicleUseCase {
  const UpdateVehicleUseCase(this._repository);

  final GarageRepository _repository;

  Future<Either<DomainException, Vehicle>> call(
    String vehicleId,
    VehicleInput input,
  ) {
    return _repository.updateVehicle(vehicleId, input);
  }
}
