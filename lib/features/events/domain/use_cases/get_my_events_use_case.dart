import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';

@injectable
class GetMyEventsUseCase {
  GetMyEventsUseCase(this._eventRepository);

  final EventRepository _eventRepository;

  Future<Either<DomainException, List<EventModel>>> call() =>
      _eventRepository.getMyEvents();
}
