import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../events_repository.dart';

@injectable
class SetRegistrationStatusUseCase {
  const SetRegistrationStatusUseCase(this._repository);

  final EventsRepository _repository;

  Future<Either<DomainException, Unit>> call(
    String registrationId,
    bool approve,
  ) => _repository.setRegistrationStatus(registrationId, approve);
}
