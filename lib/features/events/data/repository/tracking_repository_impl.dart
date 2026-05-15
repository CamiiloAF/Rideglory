import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/events/data/dto/rider_tracking_dto.dart';
import 'package:rideglory/features/events/data/service/event_service.dart';
import 'package:rideglory/features/events/data/service/tracking_service.dart';
import 'package:rideglory/features/events/data/service/tracking_ws_client.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/domain/model/sos_alert_model.dart';
import 'package:rideglory/features/events/domain/model/update_location_request.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';

@Injectable(as: TrackingRepository)
class TrackingRepositoryImpl implements TrackingRepository {
  TrackingRepositoryImpl(
    this._trackingService,
    this._trackingWsClient,
    this._eventService,
    this._dio,
  );

  final TrackingService _trackingService;
  final TrackingWsClient _trackingWsClient;
  final EventService _eventService;
  final Dio _dio;

  @override
  Stream<List<RiderTrackingModel>> watchActiveRiders(String eventId) {
    final baseUrl = _dio.options.baseUrl;
    final websocketStream = _trackingWsClient.watchRiders(
      eventId: eventId,
      baseUrl: baseUrl,
    );
    return Stream<List<RiderTrackingModel>>.multi((controller) {
      final wsSubscription = websocketStream.listen(
        controller.add,
        onError: controller.addError,
      );
      unawaited(
        _trackingService.snapshot(eventId).then((snapshot) {
          controller.add(snapshot);
        }),
      );
      controller.onCancel = () async {
        await wsSubscription.cancel();
      };
    });
  }

  @override
  Future<Either<DomainException, Nothing>> startTracking({
    required String eventId,
    required RiderTrackingModel initialData,
  }) {
    final riderDto = RiderTrackingDto(
      userId: initialData.userId,
      fullName: initialData.fullName,
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
        await _trackingService.startSession(eventId: eventId, rider: riderDto);
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
        await _trackingWsClient.publishLocation(request);
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
        await _trackingWsClient.leaveSession(eventId: eventId, userId: userId);
        await _trackingService.stopSession(eventId: eventId, userId: userId);
        return const Nothing();
      },
    );
  }

  @override
  Future<Either<DomainException, Nothing>> endRide(String eventId) {
    return executeService(
      function: () async {
        await _eventService.endRide(eventId);
        return const Nothing();
      },
    );
  }

  @override
  void publishSos({
    required String eventId,
    required String userId,
    double? latitude,
    double? longitude,
  }) {
    _trackingWsClient.publishSos(
      eventId: eventId,
      userId: userId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Stream<SosAlertModel> get sosAlerts => _trackingWsClient.sosAlerts;

  @override
  Stream<void> get eventEnded => _trackingWsClient.eventEnded;
}
