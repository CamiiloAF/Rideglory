import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../models/vehicle.dart';
import '../repository/garage_repository.dart';

@injectable
class GetVehiclesUseCase {
  const GetVehiclesUseCase(this._repository);

  final GarageRepository _repository;

  Future<Either<DomainException, List<Vehicle>>> call() {
    return _repository.getVehicles();
  }
}
