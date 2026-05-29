import 'package:dartz/dartz.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';

abstract class SoatRepository {
  Future<Either<DomainException, SoatModel?>> getSoat(String vehicleId);

  Future<Either<DomainException, SoatModel>> saveSoat({
    required String vehicleId,
    required SoatModel soat,
  });

  Future<Either<DomainException, Unit>> deleteSoat(String vehicleId);
}
