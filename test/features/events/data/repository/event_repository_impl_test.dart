import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/data/dto/event_dto.dart';
import 'package:rideglory/features/events/data/repository/event_repository_impl.dart';
import 'package:rideglory/features/events/data/service/event_service.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/upload_event_image_request.dart';

class MockEventService extends Mock implements EventService {}

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockReference extends Mock implements Reference {}

class _FakeTaskSnapshot extends Fake implements TaskSnapshot {
  _FakeTaskSnapshot(this._ref);
  final Reference _ref;

  @override
  Reference get ref => _ref;
}

class _FakeUploadTask extends Fake implements UploadTask {
  _FakeUploadTask(this._snapshot);
  final TaskSnapshot _snapshot;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(TaskSnapshot value) onValue, {
    Function? onError,
  }) => Future<TaskSnapshot>.value(_snapshot).then(onValue, onError: onError);
}

void main() {
  late MockEventService mockEventService;
  late MockFirebaseStorage mockStorage;
  late EventRepositoryImpl repository;

  final event = EventDto(
    id: 'event-1',
    ownerId: 'owner-1',
    name: 'Rodada nocturna',
    description: 'Una rodada',
    startDate: DateTime(2026, 8, 1),
    difficulty: EventDifficulty.two,
    meetingTime: DateTime(2026, 8, 1, 18),
    eventType: EventType.onRoad,
  );

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(File('/tmp/fallback.jpg'));
  });

  setUp(() {
    mockEventService = MockEventService();
    mockStorage = MockFirebaseStorage();
    repository = EventRepositoryImpl(mockEventService, mockStorage);
  });

  DioException dioException({int statusCode = 500}) => DioException(
    requestOptions: RequestOptions(path: '/events'),
    response: Response(
      requestOptions: RequestOptions(path: '/events'),
      statusCode: statusCode,
    ),
    type: DioExceptionType.badResponse,
  );

  group('getEvents', () {
    test('returns Right with events on success', () async {
      when(
        () => mockEventService.getEvents(
          type: any(named: 'type'),
          dateFrom: any(named: 'dateFrom'),
          dateTo: any(named: 'dateTo'),
        ),
      ).thenAnswer((_) async => [event]);

      final result = await repository.getEvents(type: 'ON_ROAD');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (events) => expect(events, [event]),
      );
    });

    test('returns Left on DioException', () async {
      when(
        () => mockEventService.getEvents(
          type: any(named: 'type'),
          dateFrom: any(named: 'dateFrom'),
          dateTo: any(named: 'dateTo'),
        ),
      ).thenThrow(dioException());

      final result = await repository.getEvents();

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, isA<DomainException>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('getMyEvents', () {
    test('returns Right with events on success', () async {
      when(
        () => mockEventService.getMyEvents(),
      ).thenAnswer((_) async => [event]);

      final result = await repository.getMyEvents();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (events) => expect(events, [event]),
      );
    });

    test('returns Left on DioException', () async {
      when(() => mockEventService.getMyEvents()).thenThrow(dioException());

      final result = await repository.getMyEvents();

      expect(result.isLeft(), isTrue);
    });
  });

  group('getEventById', () {
    test('returns Right with event on success', () async {
      when(
        () => mockEventService.getEventById('event-1'),
      ).thenAnswer((_) async => event);

      final result = await repository.getEventById('event-1');

      expect(result, equals(Right(event)));
    });

    test('returns Left on 404', () async {
      when(
        () => mockEventService.getEventById('missing'),
      ).thenThrow(dioException(statusCode: 404));

      final result = await repository.getEventById('missing');

      expect(result.isLeft(), isTrue);
    });
  });

  group('createEvent', () {
    test('serializes the event and returns Right on success', () async {
      when(
        () => mockEventService.createEvent(any()),
      ).thenAnswer((_) async => event);

      final result = await repository.createEvent(event);

      expect(result, equals(Right(event)));
      verify(() => mockEventService.createEvent(event.toJson())).called(1);
    });

    test('returns Left on DioException', () async {
      when(
        () => mockEventService.createEvent(any()),
      ).thenThrow(dioException(statusCode: 400));

      final result = await repository.createEvent(event);

      expect(result.isLeft(), isTrue);
    });
  });

  group('updateEvent', () {
    test('returns Right on success', () async {
      when(
        () => mockEventService.updateEvent(any(), any()),
      ).thenAnswer((_) async => event);

      final result = await repository.updateEvent(event);

      expect(result, equals(Right(event)));
      verify(
        () => mockEventService.updateEvent('event-1', event.toJson()),
      ).called(1);
    });

    test('returns Left immediately when event has no id', () async {
      final eventWithoutId = EventDto(
        id: null,
        ownerId: event.ownerId,
        name: event.name,
        description: event.description,
        startDate: event.startDate,
        difficulty: event.difficulty,
        meetingTime: event.meetingTime,
        eventType: event.eventType,
      );

      final result = await repository.updateEvent(eventWithoutId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, contains('Event ID is required')),
        (_) => fail('Expected Left'),
      );
      verifyNever(() => mockEventService.updateEvent(any(), any()));
    });

    test('returns Left on DioException', () async {
      when(
        () => mockEventService.updateEvent(any(), any()),
      ).thenThrow(dioException(statusCode: 409));

      final result = await repository.updateEvent(event);

      expect(result.isLeft(), isTrue);
    });
  });

  group('deleteEvent', () {
    test('returns Right with Nothing on success', () async {
      when(
        () => mockEventService.deleteEvent('event-1'),
      ).thenAnswer((_) async {});

      final result = await repository.deleteEvent('event-1');

      expect(result.isRight(), isTrue);
    });

    test('returns Left on DioException', () async {
      when(
        () => mockEventService.deleteEvent('event-1'),
      ).thenThrow(dioException(statusCode: 403));

      final result = await repository.deleteEvent('event-1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('publishEvent', () {
    test('returns Right with the published event', () async {
      when(
        () => mockEventService.publishEvent('event-1'),
      ).thenAnswer((_) async => event);

      final result = await repository.publishEvent('event-1');

      expect(result, equals(Right(event)));
    });

    test('returns Left on DioException', () async {
      when(
        () => mockEventService.publishEvent('event-1'),
      ).thenThrow(dioException(statusCode: 400));

      final result = await repository.publishEvent('event-1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('uploadEventImage', () {
    const request = UploadEventImageRequest(
      localImagePath: '/tmp/cover.jpg',
      eventId: 'event-1',
      ownerId: 'owner-1',
    );

    test('returns Right with the download URL on success', () async {
      final downloadRef = MockReference();
      when(
        () => downloadRef.getDownloadURL(),
      ).thenAnswer((_) async => 'https://storage.example.com/cover.jpg');

      final leafRef = MockReference();
      when(
        () => leafRef.putFile(any()),
      ).thenAnswer((_) => _FakeUploadTask(_FakeTaskSnapshot(downloadRef)));

      final rootRef = MockReference();
      when(() => rootRef.child(any())).thenReturn(leafRef);
      when(() => mockStorage.ref()).thenReturn(rootRef);

      final result = await repository.uploadEventImage(request);

      expect(
        result,
        const Right<DomainException, String>(
          'https://storage.example.com/cover.jpg',
        ),
      );
      verify(() => rootRef.child('events/event-1/cover.jpg')).called(1);
    });

    test('returns Left when the storage call throws', () async {
      when(() => mockStorage.ref()).thenThrow(Exception('storage unavailable'));

      final result = await repository.uploadEventImage(request);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, isA<DomainException>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
