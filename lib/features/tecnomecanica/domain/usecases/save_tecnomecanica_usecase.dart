import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart';

@injectable
class SaveTecnomecanicaUseCase {
  SaveTecnomecanicaUseCase(this._repository);

  final TecnomecanicaRepository _repository;

  Future<Either<DomainException, TecnomecanicaModel>> call({
    required String vehicleId,
    required TecnomecanicaModel tecnomecanica,
  }) {
    return _repository.saveTecnomecanica(
      vehicleId: vehicleId,
      tecnomecanica: tecnomecanica,
    );
  }
}
