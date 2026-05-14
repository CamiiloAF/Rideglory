import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/domain/repository/soat_repository.dart';

@injectable
class GetSoatUseCase {
  GetSoatUseCase(this._repository);

  final SoatRepository _repository;

  Future<Either<DomainException, SoatModel?>> call(String vehicleId) {
    return _repository.getSoat(vehicleId);
  }
}
