import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/soat/domain/repository/soat_repository.dart';

@injectable
class DeleteSoatUseCase {
  DeleteSoatUseCase(this._repository);

  final SoatRepository _repository;

  Future<Either<DomainException, Unit>> call(String vehicleId) {
    return _repository.deleteSoat(vehicleId);
  }
}
