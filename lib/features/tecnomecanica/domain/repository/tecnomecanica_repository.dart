import 'package:dartz/dartz.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';

abstract class TecnomecanicaRepository {
  Future<Either<DomainException, TecnomecanicaModel?>> getTecnomecanica(
    String vehicleId,
  );

  Future<Either<DomainException, TecnomecanicaModel>> saveTecnomecanica({
    required String vehicleId,
    required TecnomecanicaModel tecnomecanica,
  });

  Future<Either<DomainException, Unit>> deleteTecnomecanica(String vehicleId);
}
