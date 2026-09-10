import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/exceptions/domain_exception.dart';
import '../../domain/create_event_params.dart';
import '../../domain/destination_suggestion.dart';
import '../../domain/event.dart';
import '../../domain/event_difficulty.dart';
import '../../domain/event_error_code.dart';
import '../../domain/event_registrant.dart';
import '../../domain/event_route_change.dart';
import '../../domain/event_vehicle_option.dart';
import '../../domain/events_repository.dart';
import '../../domain/register_for_event_params.dart';
import '../../domain/registration_status.dart';
import '../datasources/events_datasource.dart';
import '../datasources/nominatim_datasource.dart';
import '../dto/event_dto.dart';

/// El `message` de [DomainException] es un código de [EventErrorCode] o un
/// identificador corto para logs/Sentry — nunca el texto crudo del SDK.
@Injectable(as: EventsRepository)
class EventsRepositoryImpl implements EventsRepository {
  const EventsRepositoryImpl(this._datasource, this._nominatim);

  final EventsDatasource _datasource;
  final NominatimDatasource _nominatim;

  @override
  Future<Either<DomainException, List<Event>>> getUpcomingEvents() {
    return _guard(() async {
      final dtos = await _datasource.fetchUpcomingEvents();
      return _toDomainList(dtos);
    });
  }

  @override
  Future<Either<DomainException, List<Event>>> getMyEvents() {
    return _guard(() async {
      final dtos = await _datasource.fetchMyEvents();
      return _toDomainList(dtos);
    });
  }

  @override
  Future<Either<DomainException, Event>> getEventDetail(String eventId) {
    return _guard(() async {
      final dto = await _datasource.fetchEventDetail(eventId);
      final imageUrl = await _datasource.createSignedImageUrl(dto.imagePath);
      return dto.toDomain(
        currentUserId: _datasource.currentUserId,
        imageUrl: imageUrl,
      );
    });
  }

  Future<List<Event>> _toDomainList(List<EventDto> dtos) async {
    final userId = _datasource.currentUserId;
    final events = <Event>[];
    for (final dto in dtos) {
      final imageUrl = await _datasource.createSignedImageUrl(dto.imagePath);
      events.add(dto.toDomain(currentUserId: userId, imageUrl: imageUrl));
    }
    return events;
  }

  @override
  Future<Either<DomainException, List<EventRouteChange>>> getRouteChanges(
    String eventId,
  ) {
    return _guard(() async {
      final dtos = await _datasource.fetchRouteChanges(eventId);
      return dtos.map((dto) => dto.toDomain()).toList();
    });
  }

  @override
  Future<Either<DomainException, List<EventVehicleOption>>> getMyVehicles() {
    return _guard(() async {
      final dtos = await _datasource.fetchMyVehicles();
      return dtos.map((dto) => dto.toDomain()).toList();
    });
  }

  @override
  Future<Either<DomainException, String>> createEvent(
    CreateEventParams params,
  ) {
    return _guard(() async {
      return _datasource.createDraftEvent({
        'name': params.name,
        'description': params.description,
        'start_at': params.startAt.toUtc().toIso8601String(),
        'meeting_point': params.meetingPoint,
        'destination_name': params.destinationName,
        'destination_lat': params.destinationLat,
        'destination_lng': params.destinationLng,
        'route_text': params.routeText,
        'difficulty': eventDifficultyToScore(params.difficulty),
        'max_participants': params.maxParticipants,
        'price': params.price,
      });
    });
  }

  @override
  Future<Either<DomainException, Unit>> publishEvent(String eventId) {
    return _guard(() async {
      await _datasource.publishEvent(eventId);
      return unit;
    });
  }

  @override
  Future<Either<DomainException, Unit>> startEvent(String eventId) {
    return _guard(() async {
      await _datasource.startEvent(eventId);
      return unit;
    });
  }

  @override
  Future<Either<DomainException, Unit>> cancelEvent(String eventId) {
    return _guard(() async {
      await _datasource.cancelEvent(eventId);
      return unit;
    });
  }

  @override
  Future<Either<DomainException, Unit>> addRouteChange(
    String eventId,
    String message,
  ) {
    return _guard(() async {
      await _datasource.addRouteChange(eventId, message);
      return unit;
    });
  }

  @override
  Future<Either<DomainException, Unit>> registerForEvent(
    RegisterForEventParams params,
  ) {
    return _guard(() async {
      await _datasource.insertRegistration({
        'event_id': params.eventId,
        'vehicle_id': params.vehicleId,
        'full_name': params.fullName,
        'phone': params.phone,
        'blood_type': _bloodTypeToDb(params.bloodType),
        'eps': params.eps,
        'emergency_contact_name': params.emergencyContactName,
        'emergency_contact_phone': params.emergencyContactPhone,
        'share_medical_info': params.shareMedicalInfo,
        'allow_organizer_contact': params.allowOrganizerContact,
        // No nulos si aceptó: el trigger de la base sella el valor real con
        // now(); aquí solo se manda una marca no nula para que selle.
        'risk_accepted_at': params.acceptsRisk
            ? DateTime.now().toUtc().toIso8601String()
            : null,
        'medical_consent_at': params.shareMedicalInfo
            ? DateTime.now().toUtc().toIso8601String()
            : null,
        'consent_version': params.consentVersion,
      });
      return unit;
    });
  }

  @override
  Future<Either<DomainException, Unit>> cancelMyRegistration(String eventId) {
    return _guard(() async {
      await _datasource.cancelMyRegistration(eventId);
      return unit;
    });
  }

  @override
  Future<Either<DomainException, List<EventRegistrant>>> getRegistrants(
    String eventId,
  ) {
    return _guard(() async {
      final dtos = await _datasource.fetchRegistrants(eventId);
      return dtos.map((dto) => dto.toDomain()).toList();
    });
  }

  @override
  Future<Either<DomainException, Unit>> setRegistrationStatus(
    String registrationId,
    bool approve,
  ) {
    return _guard(() async {
      await _datasource.setRegistrationStatus(
        registrationId,
        approve ? 'approved' : 'rejected',
      );
      return unit;
    });
  }

  @override
  Future<Either<DomainException, List<DestinationSuggestion>>>
  searchDestinations(String query) {
    return _guard(() async {
      final dtos = await _nominatim.search(query);
      return dtos.map((dto) => dto.toDomain()).toList();
    });
  }

  @override
  Future<Either<DomainException, String?>> uploadEventImage(
    String eventId,
    String localFilePath,
  ) {
    return _guard(() async {
      return _datasource.uploadEventImage(eventId, localFilePath);
    });
  }

  String? _bloodTypeToDb(EventBloodType? bloodType) {
    if (bloodType == null) return null;
    return switch (bloodType) {
      EventBloodType.oPositive => 'o_positive',
      EventBloodType.oNegative => 'o_negative',
      EventBloodType.aPositive => 'a_positive',
      EventBloodType.aNegative => 'a_negative',
      EventBloodType.bPositive => 'b_positive',
      EventBloodType.bNegative => 'b_negative',
      EventBloodType.abPositive => 'ab_positive',
      EventBloodType.abNegative => 'ab_negative',
    };
  }

  Future<Either<DomainException, T>> _guard<T>(
    Future<T> Function() action,
  ) async {
    try {
      return Right(await action());
    } on PostgrestException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('registration_requires_18_years_or_older')) {
        return const Left(DomainException(message: EventErrorCode.underage));
      }
      if (message.contains('birth_date_required_for_registration')) {
        return const Left(
          DomainException(message: EventErrorCode.birthDateRequired),
        );
      }
      if (message.contains('duplicate key') ||
          message.contains('event_registrations_event_id_user_id_key')) {
        return const Left(
          DomainException(message: EventErrorCode.alreadyRegistered),
        );
      }
      return Left(DomainException(message: 'postgrest_error: ${error.code}'));
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('socketexception') ||
          text.contains('failed host lookup') ||
          text.contains('clientexception')) {
        return const Left(DomainException(message: EventErrorCode.offline));
      }
      return Left(DomainException(message: 'unknown_error: $error'));
    }
  }
}
