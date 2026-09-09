import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../maintenance.dart';
import '../maintenance_repository.dart';

@injectable
class GetMaintenancesUseCase {
  const GetMaintenancesUseCase(this._repository);

  final MaintenanceRepository _repository;

  Future<Either<DomainException, List<Maintenance>>> call() {
    return _repository.getMaintenances();
  }
}
