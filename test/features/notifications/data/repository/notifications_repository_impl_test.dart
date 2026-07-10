import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/notifications/data/dto/notification_dto.dart';
import 'package:rideglory/features/notifications/data/repository/notifications_repository_impl.dart';
import 'package:rideglory/features/notifications/data/service/notifications_service.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';

class MockNotificationsService extends Mock implements NotificationsService {}

void main() {
  late MockNotificationsService mockService;
  late NotificationsRepositoryImpl repository;

  setUp(() {
    mockService = MockNotificationsService();
    repository = NotificationsRepositoryImpl(mockService);
  });

  DioException dioException() {
    return DioException(
      requestOptions: RequestOptions(path: '/notifications'),
      type: DioExceptionType.connectionError,
    );
  }

  group('getNotifications', () {
    final dto = NotificationDto(
      id: 'n1',
      userId: 'u1',
      type: 'NEW_REGISTRATION',
      payload: const {'route': 'rideglory://events/detail-by-id?id=1'},
      isRead: false,
      createdAt: DateTime(2026, 6, 1),
    );

    test('camino feliz — mapea NotificationDto a NotificationModel', () async {
      when(
        () => mockService.getNotifications(cursor: null, limit: 20),
      ).thenAnswer(
        (_) async =>
            NotificationPageDto(data: [dto], nextCursor: 'cursor2'),
      );

      final result = await repository.getNotifications();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (page) {
        expect(page.data, hasLength(1));
        expect(page.data.first.id, 'n1');
        expect(page.data.first.type, NotificationType.newRegistration);
        expect(
          page.data.first.route,
          'rideglory://events/detail-by-id?id=1',
        );
        expect(page.nextCursor, 'cursor2');
      });
    });

    test('camino de error — DioException retorna Left', () async {
      when(
        () => mockService.getNotifications(cursor: null, limit: 20),
      ).thenThrow(dioException());

      final result = await repository.getNotifications();

      expect(result.isLeft(), isTrue);
    });
  });

  group('markRead', () {
    test('camino feliz — retorna Right', () async {
      when(() => mockService.markRead('n1')).thenAnswer((_) async {});

      final result = await repository.markRead('n1');

      expect(result.isRight(), isTrue);
      verify(() => mockService.markRead('n1')).called(1);
    });

    test('camino de error — DioException retorna Left', () async {
      when(() => mockService.markRead('n1')).thenThrow(dioException());

      final result = await repository.markRead('n1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('markAllRead', () {
    test('camino feliz — retorna Right', () async {
      when(() => mockService.markAllRead()).thenAnswer((_) async {});

      final result = await repository.markAllRead();

      expect(result.isRight(), isTrue);
      verify(() => mockService.markAllRead()).called(1);
    });

    test('camino de error — DioException retorna Left', () async {
      when(() => mockService.markAllRead()).thenThrow(dioException());

      final result = await repository.markAllRead();

      expect(result.isLeft(), isTrue);
    });
  });

  group('registerFcmToken', () {
    test('camino feliz — envía {fcmToken: token} y retorna Right', () async {
      when(
        () => mockService.registerFcmToken({'fcmToken': 'token-123'}),
      ).thenAnswer((_) async {});

      final result = await repository.registerFcmToken('token-123');

      expect(result.isRight(), isTrue);
      verify(
        () => mockService.registerFcmToken({'fcmToken': 'token-123'}),
      ).called(1);
    });

    test('camino de error — DioException retorna Left', () async {
      when(
        () => mockService.registerFcmToken({'fcmToken': 'token-123'}),
      ).thenThrow(dioException());

      final result = await repository.registerFcmToken('token-123');

      expect(result.isLeft(), isTrue);
    });
  });
}
