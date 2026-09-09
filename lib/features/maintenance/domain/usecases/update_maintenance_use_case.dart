import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../maintenance.dart';
import '../maintenance_repository.dart';
import '../register_maintenance_params.dart';

@injectable
class UpdateMaintenanceUseCase {
  const UpdateMaintenanceUseCase(this._repository);

  final MaintenanceRepository _repository;

  Future<Either<DomainException, Maintenance>> call(
    String id,
    RegisterMaintenanceParams params,
  ) {
    return _repository.updateMaintenance(id, params);
  }
}
