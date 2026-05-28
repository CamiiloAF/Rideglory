import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/soat/data/dto/soat_dto.dart';
import 'package:rideglory/features/soat/data/service/soat_service.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/domain/repository/soat_repository.dart';

@Injectable(as: SoatRepository)
class SoatRepositoryImpl implements SoatRepository {
  SoatRepositoryImpl(this._soatService);

  final SoatService _soatService;

  @override
  Future<Either<DomainException, SoatModel?>> getSoat(String vehicleId) async {
    try {
      final dto = await _soatService.getSoat(vehicleId);
      return Right(dto);
    } on DioException catch (dioException) {
      if (dioException.response?.statusCode == 404) {
        return const Right(null);
      }
      return const Left(
        DomainException(
          message: 'No se pudo cargar el SOAT. Intenta de nuevo.',
        ),
      );
    } catch (error) {
      return const Left(
        DomainException(
          message: 'No se pudo cargar el SOAT. Intenta de nuevo.',
        ),
      );
    }
  }

  @override
  Future<Either<DomainException, SoatModel>> saveSoat({
    required String vehicleId,
    required SoatModel soat,
  }) async {
    return executeService(
      function: () async {
        final dto = await _soatService.saveSoat(
          vehicleId,
          soat.toRequestJson(),
        );
        return dto;
      },
    );
  }
}
