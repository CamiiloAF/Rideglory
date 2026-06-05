import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart';

@injectable
class DeleteTecnomecanicaUseCase {
  DeleteTecnomecanicaUseCase(this._repository);

  final TecnomecanicaRepository _repository;

  Future<Either<DomainException, Unit>> call(String vehicleId) {
    return _repository.deleteTecnomecanica(vehicleId);
  }
}
