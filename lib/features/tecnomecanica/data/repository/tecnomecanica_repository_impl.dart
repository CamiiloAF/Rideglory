import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/tecnomecanica/data/dto/tecnomecanica_dto.dart';
import 'package:rideglory/features/tecnomecanica/data/service/tecnomecanica_service.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart';

@Injectable(as: TecnomecanicaRepository)
class TecnomecanicaRepositoryImpl implements TecnomecanicaRepository {
  TecnomecanicaRepositoryImpl(this._tecnomecanicaService);

  final TecnomecanicaService _tecnomecanicaService;

  @override
  Future<Either<DomainException, TecnomecanicaModel?>> getTecnomecanica(
    String vehicleId,
  ) async {
    try {
      final dto = await _tecnomecanicaService.getTecnomecanica(vehicleId);
      return Right(dto);
    } on DioException catch (dioException) {
      if (dioException.response?.statusCode == 404) {
        return const Right(null);
      }
      return const Left(
        DomainException(
          message:
              'No se pudo cargar la revisión técnico-mecánica. Intenta de nuevo.',
        ),
      );
    } catch (_) {
      return const Left(
        DomainException(
          message:
              'No se pudo cargar la revisión técnico-mecánica. Intenta de nuevo.',
        ),
      );
    }
  }

  @override
  Future<Either<DomainException, TecnomecanicaModel>> saveTecnomecanica({
    required String vehicleId,
    required TecnomecanicaModel tecnomecanica,
  }) async {
    return executeService(
      function: () async {
        final requestDto = CreateTecnomecanicaRequestDto(
          cdaName: tecnomecanica.cdaName,
          startDate: tecnomecanica.startDate,
          expiryDate: tecnomecanica.expiryDate,
          documentUrl: tecnomecanica.documentUrl,
        );
        final dto = await _tecnomecanicaService.saveTecnomecanica(
          vehicleId,
          requestDto.toJson(),
        );
        return dto;
      },
    );
  }

  @override
  Future<Either<DomainException, Unit>> deleteTecnomecanica(
    String vehicleId,
  ) async {
    return executeService(
      function: () async {
        await _tecnomecanicaService.deleteTecnomecanica(vehicleId);
        return unit;
      },
    );
  }
}
