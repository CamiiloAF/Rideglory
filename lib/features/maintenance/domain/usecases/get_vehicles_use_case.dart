import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../maintenance_repository.dart';
import '../vehicle_option.dart';

@injectable
class GetVehiclesUseCase {
  const GetVehiclesUseCase(this._repository);

  final MaintenanceRepository _repository;

  Future<Either<DomainException, List<VehicleOption>>> call() {
    return _repository.getVehicles();
  }
}
