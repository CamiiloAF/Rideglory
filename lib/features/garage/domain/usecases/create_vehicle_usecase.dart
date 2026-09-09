import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../models/vehicle.dart';
import '../repository/garage_repository.dart';

@injectable
class CreateVehicleUseCase {
  const CreateVehicleUseCase(this._repository);

  final GarageRepository _repository;

  Future<Either<DomainException, Vehicle>> call(VehicleInput input) {
    return _repository.createVehicle(input);
  }
}
