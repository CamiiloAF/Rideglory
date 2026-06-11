import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/ai_domain_exceptions.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/data/dto/ai_description_request_dto.dart';
import 'package:rideglory/features/events/data/service/ai_description_service.dart';
import 'package:rideglory/features/events/domain/model/ai_description_request.dart';
import 'package:rideglory/features/events/domain/model/ai_description_result.dart';
import 'package:rideglory/features/events/domain/repository/ai_description_repository.dart';

@Injectable(as: AiDescriptionRepository)
class AiDescriptionRepositoryImpl implements AiDescriptionRepository {
  const AiDescriptionRepositoryImpl(this._service);

  final AiDescriptionService _service;

  @override
  Future<Either<DomainException, int>> getDescriptionQuota() async {
    try {
      final dto = await _service.getQuota();
      return Right(dto.descriptionRemaining);
    } on DioException {
      return const Left(
        AiNetworkErrorException(
          message:
              'No se pudo obtener la cuota de generaciones. Verifica tu conexión.',
        ),
      );
    }
  }

  @override
  Future<Either<DomainException, AiDescriptionResult>> generateDescription(
    AiDescriptionRequest request,
  ) async {
    try {
      final dto = await _service.generateDescription(
        AiDescriptionRequestDto.fromDomain(request),
      );
      return Right(
        AiDescriptionResult(
          markdown: dto.markdown,
          remainingGenerations: dto.remainingGenerations,
          isDescription: dto.isDescription,
        ),
      );
    } on DioException catch (exception) {
      final data = exception.response?.data;
      final errorCode = (data?['error'] ?? data?['message']) as String?;
      final statusCode = exception.response?.statusCode;

      if (statusCode == 429 && errorCode == 'quota_exceeded_user') {
        return const Left(
          AiQuotaExceededUserException(
            message: 'Has alcanzado tu límite diario de generaciones con IA.',
          ),
        );
      }
      if (statusCode == 429 && errorCode == 'quota_exceeded_project') {
        return const Left(
          AiQuotaExceededProjectException(
            message:
                'El servicio de IA está temporalmente no disponible. Intenta más tarde.',
          ),
        );
      }
      if (statusCode == 422 && errorCode == 'safety_blocked') {
        return const Left(
          AiSafetyBlockedException(
            message:
                'Tu mensaje fue bloqueado por filtros de seguridad. Por favor ajusta el contenido e intenta de nuevo.',
          ),
        );
      }
      return const Left(
        AiNetworkErrorException(
          message:
              'No se pudo conectar con el servicio de IA. Verifica tu conexión e intenta de nuevo.',
        ),
      );
    }
  }
}
