import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/data/dto/event_dto.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';

@Injectable(as: EventRepository)
class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._firestore, this._authService);

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  static const _collectionName = 'events';

  @override
  Future<Either<DomainException, List<EventModel>>> getEvents() {
    return executeService(
      function: () async {
        final snapshot = await _firestore
            .collection(_collectionName)
            .orderBy('startDate', descending: false)
            .get();

        return snapshot.docs
            .map((e) => EventDto.fromJson(e.data()).copyWith(id: e.id))
            .toList();
      },
    );
  }

  @override
  Future<Either<DomainException, List<EventModel>>> getMyEvents() {
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
            .where('ownerId', isEqualTo: userId)
            .orderBy('startDate', descending: false)
            .get();

        return snapshot.docs
            .map((e) => EventDto.fromJson(e.data()).copyWith(id: e.id))
            .toList();
      },
    );
  }

  @override
  Future<Either<DomainException, EventModel>> getEventById(String id) {
    return executeService(
      function: () async {
        final doc = await _firestore.collection(_collectionName).doc(id).get();

        if (!doc.exists || doc.data() == null) {
          throw DomainException(message: 'Evento no encontrado.');
        }

        return EventDto.fromJson(doc.data()!).copyWith(id: doc.id);
      },
    );
  }

  @override
  Future<Either<DomainException, EventModel>> addEvent(EventModel event) {
    final now = DateTime.now();
    final userId = _authService.currentUser?.uid ?? event.ownerId;
    final eventWithMeta = event.copyWith(
      ownerId: userId,
      createdDate: now,
      updatedDate: now,
    );

    return executeService(
      function: () async {
        final docRef = _firestore
            .collection(_collectionName)
            .doc(eventWithMeta.id);
        await docRef.set(eventWithMeta.toJson());
        return eventWithMeta.copyWith(id: docRef.id);
      },
    );
  }

  @override
  Future<Either<DomainException, EventModel>> updateEvent(EventModel event) {
    final updatedEvent = event.copyWith(updatedDate: DateTime.now());

    return executeService(
      function: () async {
        await _firestore
            .collection(_collectionName)
            .doc(updatedEvent.id)
            .update(updatedEvent.toJson());
        return updatedEvent;
      },
    );
  }

  @override
  Future<Either<DomainException, Nothing>> deleteEvent(String id) {
    return executeService(
      function: () async {
        await _firestore.collection(_collectionName).doc(id).delete();
        return Nothing();
      },
    );
  }
}
