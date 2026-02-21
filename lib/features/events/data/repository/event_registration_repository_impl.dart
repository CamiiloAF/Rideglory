import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/data/dto/event_registration_dto.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/repository/event_registration_repository.dart';

@Injectable(as: EventRegistrationRepository)
class EventRegistrationRepositoryImpl implements EventRegistrationRepository {
  EventRegistrationRepositoryImpl(this._firestore, this._authService);

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  static const _collectionName = 'event_registrations';

  @override
  Future<Either<DomainException, EventRegistrationModel>> addRegistration(
    EventRegistrationModel registration,
  ) {
    final now = DateTime.now();
    final userId = _authService.currentUser?.uid ?? registration.userId;
    final regWithMeta = registration.copyWith(
      userId: userId,
      status: RegistrationStatus.pending,
      createdDate: now,
      updatedDate: now,
    );

    return executeService(
      function: () async {
        final docRef = _firestore.collection(_collectionName).doc();
        await docRef.set(regWithMeta.toJson());
        return regWithMeta.copyWith(id: docRef.id);
      },
    );
  }

  @override
  Future<Either<DomainException, EventRegistrationModel>> updateRegistration(
    EventRegistrationModel registration,
  ) {
    final updated = registration.copyWith(updatedDate: DateTime.now());

    return executeService(
      function: () async {
        await _firestore
            .collection(_collectionName)
            .doc(updated.id)
            .update(updated.toJson());
        return updated;
      },
    );
  }

  @override
  Future<Either<DomainException, Nothing>> cancelRegistration(String id) {
    return executeService(
      function: () async {
        await _firestore.collection(_collectionName).doc(id).update({
          'status': RegistrationStatus.cancelled.name,
          'updatedDate': DateTime.now().toIso8601String(),
        });
        return Nothing();
      },
    );
  }

  @override
  Future<Either<DomainException, List<EventRegistrationModel>>>
  getRegistrationsByEvent(String eventId) {
    return executeService(
      function: () async {
        final snapshot = await _firestore
            .collection(_collectionName)
            .where('eventId', isEqualTo: eventId)
            .orderBy('createdDate', descending: false)
            .get();

        return snapshot.docs
            .map(
              (e) => EventRegistrationDto.fromJson(e.data()).copyWith(id: e.id),
            )
            .toList();
      },
    );
  }

  @override
  Future<Either<DomainException, List<EventRegistrationModel>>>
  getMyRegistrations() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return Future.value(
        Left(DomainException(message: 'No user is currently authenticated.')),
      );
    }

    return executeService(
      function: () async {
        final snapshot = await _firestore
            .collection(_collectionName)
            .where('userId', isEqualTo: userId)
            .orderBy('createdDate', descending: true)
            .get();

        return snapshot.docs
            .map(
              (e) => EventRegistrationDto.fromJson(e.data()).copyWith(id: e.id),
            )
            .toList();
      },
    );
  }

  @override
  Future<Either<DomainException, EventRegistrationModel?>>
  getMyRegistrationForEvent(String eventId) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return Future.value(
        Left(DomainException(message: 'No user is currently authenticated.')),
      );
    }

    return executeService(
      function: () async {
        final snapshot = await _firestore
            .collection(_collectionName)
            .where('eventId', isEqualTo: eventId)
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) return null;

        final doc = snapshot.docs.first;
        return EventRegistrationDto.fromJson(doc.data()).copyWith(id: doc.id);
      },
    );
  }

  @override
  Future<Either<DomainException, EventRegistrationModel>> approveRegistration(
    String registrationId,
  ) {
    return _updateStatus(registrationId, RegistrationStatus.approved);
  }

  @override
  Future<Either<DomainException, EventRegistrationModel>> rejectRegistration(
    String registrationId,
  ) {
    return _updateStatus(registrationId, RegistrationStatus.rejected);
  }

  @override
  Future<Either<DomainException, EventRegistrationModel>>
  setRegistrationReadyForEdit(String registrationId) {
    return _updateStatus(registrationId, RegistrationStatus.readyForEdit);
  }

  Future<Either<DomainException, EventRegistrationModel>> _updateStatus(
    String registrationId,
    RegistrationStatus status,
  ) {
    return executeService(
      function: () async {
        final now = DateTime.now();
        await _firestore.collection(_collectionName).doc(registrationId).update(
          {'status': status.name, 'updatedDate': now.toIso8601String()},
        );

        final doc = await _firestore
            .collection(_collectionName)
            .doc(registrationId)
            .get();

        return EventRegistrationDto.fromJson(doc.data()!).copyWith(id: doc.id);
      },
    );
  }
}
