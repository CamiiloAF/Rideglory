import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../repository/garage_repository.dart';

@injectable
class SetMainVehicleUseCase {
  const SetMainVehicleUseCase(this._repository);

  final GarageRepository _repository;

  Future<Either<DomainException, Unit>> call(String vehicleId) {
    return _repository.setMainVehicle(vehicleId);
  }
}
