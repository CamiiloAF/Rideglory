import 'package:dartz/dartz.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

abstract class EventRepository {
  Future<Either<DomainException, List<EventModel>>> getEvents();

  Future<Either<DomainException, List<EventModel>>> getMyEvents();

  Future<Either<DomainException, EventModel>> getEventById(String id);

  Future<Either<DomainException, EventModel>> addEvent(EventModel event);

  Future<Either<DomainException, EventModel>> updateEvent(EventModel event);

  Future<Either<DomainException, Nothing>> deleteEvent(String id);
}
