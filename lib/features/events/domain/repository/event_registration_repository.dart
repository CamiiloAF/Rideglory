import 'package:dartz/dartz.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';

abstract class EventRegistrationRepository {
  Future<Either<DomainException, EventRegistrationModel>> addRegistration(
    EventRegistrationModel registration,
  );

  Future<Either<DomainException, EventRegistrationModel>> updateRegistration(
    EventRegistrationModel registration,
  );

  Future<Either<DomainException, Nothing>> cancelRegistration(String id);

  Future<Either<DomainException, List<EventRegistrationModel>>>
  getRegistrationsByEvent(String eventId);

  Future<Either<DomainException, List<EventRegistrationModel>>>
  getMyRegistrations();

  Future<Either<DomainException, EventRegistrationModel?>>
  getMyRegistrationForEvent(String eventId);

  Future<Either<DomainException, EventRegistrationModel>> approveRegistration(
    String registrationId,
  );

  Future<Either<DomainException, EventRegistrationModel>> rejectRegistration(
    String registrationId,
  );

  Future<Either<DomainException, EventRegistrationModel>>
  setRegistrationReadyForEdit(String registrationId);
}
