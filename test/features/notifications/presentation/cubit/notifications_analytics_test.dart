// Analytics tests — Fase 9: Notificaciones
// Verifica:
//   notification_marked_read se emite al marcar una leída (markRead).
//   notifications_all_read se emite al marcar todas (markAllRead).
//   load() NO emite notification_marked_read (recibida vs abierta — AC 3).
//   G2: sin id de notificación ni texto como param.

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';
import 'package:rideglory/features/notifications/domain/repository/notifications_repository.dart';
import 'package:rideglory/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:rideglory/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:rideglory/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_cubit.dart';

class MockGetNotificationsUseCase extends Mock
    implements GetNotificationsUseCase {}

class MockMarkNotificationReadUseCase extends Mock
    implements MarkNotificationReadUseCase {}

class MockMarkAllNotificationsReadUseCase extends Mock
    implements MarkAllNotificationsReadUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

NotificationModel _buildNotification({
  required String id,
  bool isRead = false,
}) => NotificationModel(
  id: id,
  type: NotificationType.general,
  title: 'Notificación $id',
  body: 'Cuerpo $id',
  createdAt: DateTime(2026, 6, 1),
  isRead: isRead,
);

void main() {
  late MockGetNotificationsUseCase mockGetNotifications;
  late MockMarkNotificationReadUseCase mockMarkRead;
  late MockMarkAllNotificationsReadUseCase mockMarkAllRead;
  late MockAnalyticsService mockAnalytics;
  late NotificationsCubit cubit;

  final notification1 = _buildNotification(id: 'n1');
  final notification2 = _buildNotification(id: 'n2', isRead: true);

  setUp(() {
    mockGetNotifications = MockGetNotificationsUseCase();
    mockMarkRead = MockMarkNotificationReadUseCase();
    mockMarkAllRead = MockMarkAllNotificationsReadUseCase();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    cubit = NotificationsCubit(
      mockGetNotifications,
      mockMarkRead,
      mockMarkAllRead,
      mockAnalytics,
    );
  });

  tearDown(() => cubit.close());

  group('NotificationsCubit — analytics Fase 9', () {
    // TC-notif-a1: notification_marked_read se emite al markRead
    test('TC-notif-a1: markRead → notification_marked_read emitido', () async {
      when(() => mockGetNotifications()).thenAnswer(
        (_) async =>
            Right(NotificationsPage(data: [notification1, notification2])),
      );
      when(() => mockMarkRead('n1')).thenAnswer((_) async => const Right(null));

      await cubit.load();
      await cubit.markRead('n1');

      verify(
        () => mockAnalytics.logEvent(
          AnalyticsEvents.notificationMarkedRead,
          any(),
        ),
      ).called(1);
    });

    // TC-notif-a2: AC 3 — load() NO emite notification_marked_read
    // (recibida vs abierta: renderizar el listado no es "abrir")
    test('TC-notif-a2: load() → notification_marked_read NO emitido '
        '(distinción recibida vs abierta)', () async {
      when(() => mockGetNotifications()).thenAnswer(
        (_) async =>
            Right(NotificationsPage(data: [notification1, notification2])),
      );

      await cubit.load();

      verifyNever(
        () => mockAnalytics.logEvent(
          AnalyticsEvents.notificationMarkedRead,
          any(),
        ),
      );
      verifyNever(
        () => mockAnalytics.logEvent(AnalyticsEvents.notificationMarkedRead),
      );
    });

    // TC-notif-a3: notifications_all_read se emite al markAllRead
    test('TC-notif-a3: markAllRead → notifications_all_read emitido', () async {
      when(() => mockGetNotifications()).thenAnswer(
        (_) async =>
            Right(NotificationsPage(data: [notification1, notification2])),
      );
      when(() => mockMarkAllRead()).thenAnswer((_) async => const Right(null));

      await cubit.load();
      await cubit.markAllRead();

      verify(
        () => mockAnalytics.logEvent(AnalyticsEvents.notificationsAllRead),
      ).called(1);
    });

    // TC-notif-a4: G2 — notification_marked_read no contiene id ni texto
    test('TC-notif-a4: G2 — params de notification_marked_read no contienen id '
        'ni texto de notificación', () async {
      when(() => mockGetNotifications()).thenAnswer(
        (_) async =>
            Right(NotificationsPage(data: [notification1, notification2])),
      );
      when(() => mockMarkRead('n1')).thenAnswer((_) async => const Right(null));

      await cubit.load();
      await cubit.markRead('n1');

      final captured = verify(
        () => mockAnalytics.logEvent(
          AnalyticsEvents.notificationMarkedRead,
          captureAny(),
        ),
      ).captured;

      final params = captured.single as Map<String, Object>;

      // id y texto del cuerpo nunca como valor
      expect(params.values, isNot(contains('n1')));
      expect(params.values, isNot(contains('Notificación n1')));
      expect(params.values, isNot(contains('Cuerpo n1')));
    });
  });
}
