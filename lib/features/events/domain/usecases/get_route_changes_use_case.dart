import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../event_route_change.dart';
import '../events_repository.dart';

@injectable
class GetRouteChangesUseCase {
  const GetRouteChangesUseCase(this._repository);

  final EventsRepository _repository;

  Future<Either<DomainException, List<EventRouteChange>>> call(
    String eventId,
  ) => _repository.getRouteChanges(eventId);
}
