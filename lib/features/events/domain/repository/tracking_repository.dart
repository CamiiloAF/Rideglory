import 'package:dartz/dartz.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/domain/model/sos_alert_model.dart';
import 'package:rideglory/features/events/domain/model/update_location_request.dart';

abstract class TrackingRepository {
  Stream<List<RiderTrackingModel>> watchActiveRiders(String eventId);

  Future<Either<DomainException, Nothing>> startTracking({
    required String eventId,
    required RiderTrackingModel initialData,
  });

  Future<Either<DomainException, Nothing>> updateLocation(
    UpdateLocationRequest request,
  );

  Future<Either<DomainException, Nothing>> stopTracking({
    required String eventId,
    required String userId,
  });

  Future<Either<DomainException, Nothing>> endRide(String eventId);

  /// Broadcasts an SOS alert via WebSocket.
  void publishSos({
    required String eventId,
    required String userId,
    double? latitude,
    double? longitude,
  });

  /// Cancels the current user's own SOS alert.
  void cancelSos({required String eventId, required String userId});

  Stream<SosAlertModel> get sosAlerts;

  /// Emits the userId of a rider whose SOS was cleared/cancelled.
  Stream<String> get sosCleared;
  Stream<void> get eventEnded;
}
