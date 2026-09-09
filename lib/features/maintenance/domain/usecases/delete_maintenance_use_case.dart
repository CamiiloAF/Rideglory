import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../maintenance_repository.dart';

@injectable
class DeleteMaintenanceUseCase {
  const DeleteMaintenanceUseCase(this._repository);

  final MaintenanceRepository _repository;

  Future<Either<DomainException, Unit>> call(String id) {
    return _repository.deleteMaintenance(id);
  }
}
