import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../events_repository.dart';

@injectable
class CancelEventUseCase {
  const CancelEventUseCase(this._repository);

  final EventsRepository _repository;

  Future<Either<DomainException, Unit>> call(String eventId) =>
      _repository.cancelEvent(eventId);
}
