import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../event.dart';
import '../events_repository.dart';

@injectable
class GetMyEventsUseCase {
  const GetMyEventsUseCase(this._repository);

  final EventsRepository _repository;

  Future<Either<DomainException, List<Event>>> call() =>
      _repository.getMyEvents();
}
