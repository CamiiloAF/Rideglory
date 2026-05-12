import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/event_registration/data/dto/event_registration_dto.dart';
import 'package:rideglory/features/event_registration/data/service/registration_service.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/repository/event_registration_repository.dart';

@Injectable(as: EventRegistrationRepository)
class EventRegistrationRepositoryImpl implements EventRegistrationRepository {
  EventRegistrationRepositoryImpl(this._service);

  final RegistrationService _service;

  @override
  Future<Either<DomainException, EventRegistrationModel>> addRegistration(
    EventRegistrationModel registration, {
    bool saveToProfile = false,
  }) {
    return executeService(
      function: () async {
        final dto = await _service.create(
          eventId: registration.eventId,
          body: registration.toDto().toJson(),
          saveToProfile: saveToProfile,
        );
        return dto.toModel();
      },
    );
  }

  @override
  Future<Either<DomainException, EventRegistrationModel>> updateRegistration(
    EventRegistrationModel registration, {
    bool saveToProfile = false,
  }) {
    final id = registration.id;
    if (id == null || id.isEmpty) {
      return Future.value(
        const Left(
          DomainException(message: 'Registration id is required to update.'),
        ),
      );
    }

    return executeService(
      function: () async {
        final dto = await _service.update(
          registrationId: id,
          body: registration.toDto().toJson(),
          saveToProfile: saveToProfile,
        );
        return dto.toModel();
      },
    );
  }

  @override
  Future<Either<DomainException, Nothing>> cancelRegistration(
    String registrationId,
  ) {
    return executeService(
      function: () async {
        await _service.cancel(registrationId);
        return const Nothing();
      },
    );
  }

  @override
  Future<Either<DomainException, List<EventRegistrationModel>>>
  getRegistrationsByEvent(String eventId) {
    return executeService(
      function: () async {
        final rows = await _service.findByEvent(eventId);
        return rows.map((dto) => dto.toModel()).toList();
      },
    );
  }

  @override
  Future<Either<DomainException, List<EventRegistrationModel>>>
  getMyRegistrations() {
    return executeService(
      function: () async {
        final rows = await _service.findMyRegistrations();
        return rows.map((dto) => dto.toModel()).toList();
      },
    );
  }

  @override
  Future<Either<DomainException, EventRegistrationModel?>>
  getMyRegistrationForEvent(String eventId) {
    return executeService(
      function: () async {
        final dto = await _service.findMyRegistrationForEvent(eventId);
        return dto?.toModel();
      },
    );
  }

  @override
  Future<Either<DomainException, EventRegistrationModel>> approveRegistration(
    String registrationId,
  ) {
    return executeService(
      function: () async {
        final dto = await _service.approve(registrationId);
        return dto.toModel();
      },
    );
  }

  @override
  Future<Either<DomainException, EventRegistrationModel>> rejectRegistration(
    String registrationId,
  ) {
    return executeService(
      function: () async {
        final dto = await _service.reject(registrationId);
        return dto.toModel();
      },
    );
  }

  @override
  Future<Either<DomainException, EventRegistrationModel>>
  setRegistrationReadyForEdit(String registrationId) {
    return executeService(
      function: () async {
        final dto = await _service.setReadyForEdit(registrationId);
        return dto.toModel();
      },
    );
  }

}
