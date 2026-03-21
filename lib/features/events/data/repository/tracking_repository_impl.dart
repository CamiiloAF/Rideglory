import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/events/data/dto/rider_tracking_dto.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/domain/model/update_location_request.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';

/// Firestore-backed implementation of [TrackingRepository].
///
/// Path: `events/{eventId}/tracking/{userId}`.
/// Ensure security rules allow participants to read the subcollection and each
/// user to create/update/delete only their own document.
@Injectable(as: TrackingRepository)
class TrackingRepositoryImpl implements TrackingRepository {
  TrackingRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const _eventsCollection = 'events';
  static const _trackingSubcollection = 'tracking';

  CollectionReference<Map<String, dynamic>> _trackingCollection(String eventId) {
    return _firestore
        .collection(_eventsCollection)
        .doc(eventId)
        .collection(_trackingSubcollection);
  }

  @override
  Stream<List<RiderTrackingModel>> watchActiveRiders(String eventId) {
    return _trackingCollection(eventId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RiderTrackingDto.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  @override
  Future<Either<DomainException, Nothing>> startTracking({
    required String eventId,
    required RiderTrackingModel initialData,
  }) {
    final dto = RiderTrackingDto(
      userId: initialData.userId,
      firstName: initialData.firstName,
      lastName: initialData.lastName,
      role: initialData.role,
      latitude: initialData.latitude,
      longitude: initialData.longitude,
      speedKmh: initialData.speedKmh,
      distanceMeters: initialData.distanceMeters,
      batteryPercent: initialData.batteryPercent,
      isActive: initialData.isActive,
      deviceLabel: initialData.deviceLabel,
      lastUpdated: initialData.lastUpdated,
    );
    return executeService(
      function: () async {
        await _trackingCollection(eventId).doc(dto.userId).set(dto.toJson());
        return const Nothing();
      },
    );
  }

  @override
  Future<Either<DomainException, Nothing>> updateLocation(
    UpdateLocationRequest request,
  ) {
    return executeService(
      function: () async {
        await _trackingCollection(request.eventId).doc(request.userId).update({
          'latitude': request.latitude,
          'longitude': request.longitude,
          'speedKmh': request.speedKmh,
          'distanceMeters': request.distanceMeters,
          'batteryPercent': request.batteryPercent,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        return const Nothing();
      },
    );
  }

  @override
  Future<Either<DomainException, Nothing>> stopTracking({
    required String eventId,
    required String userId,
  }) {
    return executeService(
      function: () async {
        await _trackingCollection(eventId).doc(userId).delete();
        return const Nothing();
      },
    );
  }
}
