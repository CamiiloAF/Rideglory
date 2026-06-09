import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/repository/ai_description_repository.dart';

@injectable
class GetDescriptionQuotaUseCase {
  const GetDescriptionQuotaUseCase(this._repository);

  final AiDescriptionRepository _repository;

  Future<Either<DomainException, int>> call() =>
      _repository.getDescriptionQuota();
}
