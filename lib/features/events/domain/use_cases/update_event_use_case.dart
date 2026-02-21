import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';

@injectable
class UpdateEventUseCase {
  UpdateEventUseCase(this._eventRepository);

  final EventRepository _eventRepository;

  Future<Either<DomainException, EventModel>> call(EventModel event) =>
      _eventRepository.updateEvent(event);
}
