import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/domain/repository/soat_repository.dart';

@injectable
class SaveSoatUseCase {
  SaveSoatUseCase(this._repository);

  final SoatRepository _repository;

  Future<Either<DomainException, SoatModel>> call({
    required String vehicleId,
    required SoatModel soat,
  }) {
    return _repository.saveSoat(vehicleId: vehicleId, soat: soat);
  }
}
