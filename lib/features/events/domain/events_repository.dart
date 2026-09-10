import 'package:dartz/dartz.dart';

import '../../../core/exceptions/domain_exception.dart';
import 'create_event_params.dart';
import 'destination_suggestion.dart';
import 'event.dart';
import 'event_registrant.dart';
import 'event_route_change.dart';
import 'event_vehicle_option.dart';
import 'register_for_event_params.dart';

abstract class EventsRepository {
  /// Próximas: `published`/`started` con `start_at >= hoy`, para cualquier
  /// autenticado. Mías: organizadas o con inscripción propia (cualquier
  /// estado, incluida `draft` si soy el organizador).
  Future<Either<DomainException, List<Event>>> getUpcomingEvents();

  Future<Either<DomainException, List<Event>>> getMyEvents();

  Future<Either<DomainException, Event>> getEventDetail(String eventId);

  Future<Either<DomainException, List<EventRouteChange>>> getRouteChanges(
    String eventId,
  );

  Future<Either<DomainException, List<EventVehicleOption>>> getMyVehicles();

  Future<Either<DomainException, String>> createEvent(CreateEventParams params);

  Future<Either<DomainException, Unit>> publishEvent(String eventId);

  Future<Either<DomainException, Unit>> startEvent(String eventId);

  Future<Either<DomainException, Unit>> cancelEvent(String eventId);

  Future<Either<DomainException, Unit>> addRouteChange(
    String eventId,
    String message,
  );

  Future<Either<DomainException, Unit>> registerForEvent(
    RegisterForEventParams params,
  );

  Future<Either<DomainException, Unit>> cancelMyRegistration(String eventId);

  Future<Either<DomainException, List<EventRegistrant>>> getRegistrants(
    String eventId,
  );

  Future<Either<DomainException, Unit>> setRegistrationStatus(
    String registrationId,
    bool approve,
  );

  Future<Either<DomainException, List<DestinationSuggestion>>>
  searchDestinations(String query);

  Future<Either<DomainException, String?>> uploadEventImage(
    String eventId,
    String localFilePath,
  );
}
