import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/data/dto/rider_tracking_dto.dart';
import 'package:rideglory/features/events/data/repository/tracking_repository_impl.dart';
import 'package:rideglory/features/events/data/service/event_service.dart';
import 'package:rideglory/features/events/data/service/tracking_service.dart';
import 'package:rideglory/features/events/data/service/tracking_ws_client.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/domain/model/sos_alert_model.dart';
import 'package:rideglory/features/events/domain/model/update_location_request.dart';

class MockTrackingService extends Mock implements TrackingService {}

class MockTrackingWsClient extends Mock implements TrackingWsClient {}

class MockEventService extends Mock implements EventService {}

class MockDio extends Mock implements Dio {}

class FakeBaseOptions extends Fake implements BaseOptions {
  @override
  String baseUrl = 'https://api.rideglory.com';
}

void main() {
  late MockTrackingService mockTrackingService;
  late MockTrackingWsClient mockWsClient;
  late MockEventService mockEventService;
  late MockDio mockDio;
  late TrackingRepositoryImpl repository;

  final rider = RiderTrackingModel(
    userId: 'user-1',
    fullName: 'Camilo Agudelo',
    role: RiderTrackingRole.rider,
    latitude: 4.65,
    longitude: -74.05,
    speedKmh: 20,
    distanceMeters: 500,
    batteryPercent: 90,
    isActive: true,
    deviceLabel: 'iPhone',
    lastUpdated: DateTime(2026, 8, 1),
  );

  const updateLocationRequest = UpdateLocationRequest(
    eventId: 'event-1',
    userId: 'user-1',
    latitude: 4.65,
    longitude: -74.05,
    speedKmh: 30,
    distanceMeters: 1000,
    batteryPercent: 75,
  );

  setUpAll(() {
    registerFallbackValue(updateLocationRequest);
    registerFallbackValue(
      RiderTrackingDto(
        userId: rider.userId,
        fullName: rider.fullName,
        role: rider.role,
        latitude: rider.latitude,
        longitude: rider.longitude,
        speedKmh: rider.speedKmh,
        distanceMeters: rider.distanceMeters,
        batteryPercent: rider.batteryPercent,
        isActive: rider.isActive,
        deviceLabel: rider.deviceLabel,
        lastUpdated: rider.lastUpdated,
      ),
    );
  });

  setUp(() {
    mockTrackingService = MockTrackingService();
    mockWsClient = MockTrackingWsClient();
    mockEventService = MockEventService();
    mockDio = MockDio();
    when(() => mockDio.options).thenReturn(FakeBaseOptions());
    repository = TrackingRepositoryImpl(
      mockTrackingService,
      mockWsClient,
      mockEventService,
      mockDio,
    );
  });

  DioException dioException({int statusCode = 500}) => DioException(
    requestOptions: RequestOptions(path: '/tracking'),
    response: Response(
      requestOptions: RequestOptions(path: '/tracking'),
      statusCode: statusCode,
    ),
    type: DioExceptionType.badResponse,
  );

  group('startTracking', () {
    test('returns Right with Nothing on success', () async {
      when(
        () => mockTrackingService.startSession(
          eventId: any(named: 'eventId'),
          rider: any(named: 'rider'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.startTracking(
        eventId: 'event-1',
        initialData: rider,
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockTrackingService.startSession(
          eventId: 'event-1',
          rider: any(named: 'rider'),
        ),
      ).called(1);
    });

    test('returns Left on DioException', () async {
      when(
        () => mockTrackingService.startSession(
          eventId: any(named: 'eventId'),
          rider: any(named: 'rider'),
        ),
      ).thenThrow(dioException());

      final result = await repository.startTracking(
        eventId: 'event-1',
        initialData: rider,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, isA<DomainException>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('updateLocation', () {
    test('publishes via the WS client and returns Right', () async {
      when(
        () => mockWsClient.publishLocation(any()),
      ).thenAnswer((_) async {});

      final result = await repository.updateLocation(updateLocationRequest);

      expect(result.isRight(), isTrue);
      verify(
        () => mockWsClient.publishLocation(updateLocationRequest),
      ).called(1);
    });

    test('returns Left when the WS client throws', () async {
      when(
        () => mockWsClient.publishLocation(any()),
      ).thenThrow(Exception('socket closed'));

      final result = await repository.updateLocation(updateLocationRequest);

      expect(result.isLeft(), isTrue);
    });
  });

  group('stopTracking', () {
    test('leaves the WS session then stops the HTTP session', () async {
      when(
        () => mockWsClient.leaveSession(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockTrackingService.stopSession(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.stopTracking(
        eventId: 'event-1',
        userId: 'user-1',
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockWsClient.leaveSession(eventId: 'event-1', userId: 'user-1'),
      ).called(1);
      verify(
        () => mockTrackingService.stopSession(
          eventId: 'event-1',
          userId: 'user-1',
        ),
      ).called(1);
    });

    test('returns Left when the HTTP call fails', () async {
      when(
        () => mockWsClient.leaveSession(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockTrackingService.stopSession(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenThrow(dioException(statusCode: 404));

      final result = await repository.stopTracking(
        eventId: 'event-1',
        userId: 'user-1',
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('endRide', () {
    test('returns Right with Nothing on success', () async {
      when(
        () => mockEventService.endRide('event-1'),
      ).thenAnswer((_) async {});

      final result = await repository.endRide('event-1');

      expect(result.isRight(), isTrue);
    });

    test('returns Left on DioException', () async {
      when(
        () => mockEventService.endRide('event-1'),
      ).thenThrow(dioException(statusCode: 403));

      final result = await repository.endRide('event-1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('SOS passthrough', () {
    test('publishSos delegates to the WS client', () {
      repository.publishSos(
        eventId: 'event-1',
        userId: 'user-1',
        latitude: 4.65,
        longitude: -74.05,
      );

      verify(
        () => mockWsClient.publishSos(
          eventId: 'event-1',
          userId: 'user-1',
          latitude: 4.65,
          longitude: -74.05,
        ),
      ).called(1);
    });

    test('cancelSos delegates to the WS client', () {
      repository.cancelSos(eventId: 'event-1', userId: 'user-1');

      verify(
        () => mockWsClient.cancelSos(eventId: 'event-1', userId: 'user-1'),
      ).called(1);
    });

    test('sosAlerts, sosCleared and eventEnded proxy the WS client streams', () {
      final sosController = StreamController<SosAlertModel>();
      final clearedController = StreamController<String>();
      final endedController = StreamController<void>();

      when(() => mockWsClient.sosAlerts).thenAnswer((_) => sosController.stream);
      when(
        () => mockWsClient.sosCleared,
      ).thenAnswer((_) => clearedController.stream);
      when(
        () => mockWsClient.eventEnded,
      ).thenAnswer((_) => endedController.stream);

      expect(repository.sosAlerts, emits(isA<SosAlertModel>()));
      expect(repository.sosCleared, emits('user-1'));
      expect(repository.eventEnded, emits(null));

      sosController.add(
        const SosAlertModel(userId: 'user-1', riderName: 'Camilo'),
      );
      clearedController.add('user-1');
      endedController.add(null);

      sosController.close();
      clearedController.close();
      endedController.close();
    });
  });

  group('watchActiveRiders', () {
    test('merges the WS stream with the initial HTTP snapshot', () async {
      final ridersDto = RiderTrackingDto(
        userId: rider.userId,
        fullName: rider.fullName,
        role: rider.role,
        latitude: rider.latitude,
        longitude: rider.longitude,
        speedKmh: rider.speedKmh,
        distanceMeters: rider.distanceMeters,
        batteryPercent: rider.batteryPercent,
        isActive: rider.isActive,
        deviceLabel: rider.deviceLabel,
        lastUpdated: rider.lastUpdated,
      );

      when(
        () => mockWsClient.watchRiders(
          eventId: any(named: 'eventId'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenAnswer((_) => const Stream<List<RiderTrackingModel>>.empty());
      when(
        () => mockTrackingService.snapshot('event-1'),
      ).thenAnswer((_) async => [ridersDto]);

      final firstEmission = await repository
          .watchActiveRiders('event-1')
          .first;

      expect(firstEmission, [ridersDto]);
      verify(
        () => mockWsClient.watchRiders(
          eventId: 'event-1',
          baseUrl: 'https://api.rideglory.com',
        ),
      ).called(1);
    });

    test('forwards errors emitted by the WS stream', () async {
      when(
        () => mockWsClient.watchRiders(
          eventId: any(named: 'eventId'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenAnswer(
        (_) => Stream<List<RiderTrackingModel>>.error(StateError('ws down')),
      );
      when(
        () => mockTrackingService.snapshot('event-1'),
      ).thenAnswer((_) async => []);

      await expectLater(
        repository.watchActiveRiders('event-1'),
        emitsError(isA<StateError>()),
      );
    });
  });
}
