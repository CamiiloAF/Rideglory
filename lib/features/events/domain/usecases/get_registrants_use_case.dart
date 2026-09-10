import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../event_registrant.dart';
import '../events_repository.dart';

@injectable
class GetRegistrantsUseCase {
  const GetRegistrantsUseCase(this._repository);

  final EventsRepository _repository;

  Future<Either<DomainException, List<EventRegistrant>>> call(String eventId) =>
      _repository.getRegistrants(eventId);
}
