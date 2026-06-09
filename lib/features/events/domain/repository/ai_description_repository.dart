import 'package:dartz/dartz.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/ai_description_request.dart';
import 'package:rideglory/features/events/domain/model/ai_description_result.dart';

abstract class AiDescriptionRepository {
  Future<Either<DomainException, int>> getDescriptionQuota();

  Future<Either<DomainException, AiDescriptionResult>> generateDescription(
    AiDescriptionRequest request,
  );
}
