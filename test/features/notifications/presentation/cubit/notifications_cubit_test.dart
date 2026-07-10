import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';
import 'package:rideglory/features/notifications/domain/repository/notifications_repository.dart';
import 'package:rideglory/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:rideglory/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:rideglory/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_state.dart';

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
  title: 'Test $id',
  body: 'Body $id',
  createdAt: DateTime(2026, 5, 1),
  isRead: isRead,
);

void main() {
  late MockGetNotificationsUseCase mockGetNotifications;
  late MockMarkNotificationReadUseCase mockMarkRead;
  late MockMarkAllNotificationsReadUseCase mockMarkAllRead;
  late NotificationsCubit cubit;

  final notification1 = _buildNotification(id: 'n1');
  final notification2 = _buildNotification(id: 'n2', isRead: true);
  final notification3 = _buildNotification(id: 'n3');

  setUp(() {
    mockGetNotifications = MockGetNotificationsUseCase();
    mockMarkRead = MockMarkNotificationReadUseCase();
    mockMarkAllRead = MockMarkAllNotificationsReadUseCase();
    final mockAnalytics = MockAnalyticsService();
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

  group('NotificationsCubit — initial state', () {
    // TC-2-32: initial state has listResult = initial, unreadCount = 0
    test('TC-2-32: initial state is correct', () {
      expect(
        cubit.state.listResult,
        const ResultState<List<NotificationModel>>.initial(),
      );
      expect(cubit.state.unreadCount, 0);
      expect(cubit.state.nextCursor, isNull);
      expect(cubit.state.isLoadingMore, false);
    });
  });

  group('NotificationsCubit — load (US-2-11)', () {
    // TC-2-33: load() emits loading → data with correct unreadCount
    blocTest<NotificationsCubit, NotificationsState>(
      'TC-2-33: load() emits data with unreadCount = 2 for 2 unread items',
      setUp: () {
        when(() => mockGetNotifications()).thenAnswer(
          (_) async => Right(
            NotificationsPage(
              data: [notification1, notification2, notification3],
              nextCursor: null,
            ),
          ),
        );
      },
      build: () => cubit,
      act: (c) => c.load(),
      expect: () => [
        predicate<NotificationsState>(
          (state) => state.listResult is Loading<List<NotificationModel>>,
          'loading state',
        ),
        predicate<NotificationsState>(
          (state) =>
              state.listResult is Data<List<NotificationModel>> &&
              (state.listResult as Data<List<NotificationModel>>).data.length ==
                  3 &&
              state.unreadCount == 2 &&
              state.nextCursor == null,
          'data state with unreadCount=2',
        ),
      ],
    );

    // TC-2-34: load() emits empty when server returns no notifications
    blocTest<NotificationsCubit, NotificationsState>(
      'TC-2-34: load() emits empty state when no notifications returned',
      setUp: () {
        when(
          () => mockGetNotifications(),
        ).thenAnswer((_) async => const Right(NotificationsPage(data: [])));
      },
      build: () => cubit,
      act: (c) => c.load(),
      expect: () => [
        predicate<NotificationsState>(
          (state) => state.listResult is Loading<List<NotificationModel>>,
        ),
        predicate<NotificationsState>(
          (state) =>
              state.listResult is Empty<List<NotificationModel>> &&
              state.unreadCount == 0,
        ),
      ],
    );

    // TC-2-35: load() emits error on failure
    blocTest<NotificationsCubit, NotificationsState>(
      'TC-2-35: load() emits error when use case fails',
      setUp: () {
        when(() => mockGetNotifications()).thenAnswer(
          (_) async => const Left(DomainException(message: 'Sin conexión')),
        );
      },
      build: () => cubit,
      act: (c) => c.load(),
      expect: () => [
        predicate<NotificationsState>(
          (state) => state.listResult is Loading<List<NotificationModel>>,
        ),
        predicate<NotificationsState>(
          (state) =>
              state.listResult is Error<List<NotificationModel>> &&
              (state.listResult as Error<List<NotificationModel>>)
                      .error
                      .message ==
                  'Sin conexión',
        ),
      ],
    );

    // TC-2-36: load() stores nextCursor when present
    blocTest<NotificationsCubit, NotificationsState>(
      'TC-2-36: load() stores nextCursor for pagination',
      setUp: () {
        when(() => mockGetNotifications()).thenAnswer(
          (_) async => Right(
            NotificationsPage(data: [notification1], nextCursor: 'cursor-abc'),
          ),
        );
      },
      build: () => cubit,
      act: (c) => c.load(),
      expect: () => [
        anything,
        predicate<NotificationsState>(
          (state) => state.nextCursor == 'cursor-abc',
        ),
      ],
    );
  });

  group('NotificationsCubit — loadMore (cursor pagination)', () {
    // TC-2-37: loadMore() appends items and updates nextCursor
    blocTest<NotificationsCubit, NotificationsState>(
      'TC-2-37: loadMore() appends new items to existing list',
      setUp: () {
        when(() => mockGetNotifications()).thenAnswer(
          (_) async => Right(
            NotificationsPage(
              data: [notification1, notification2],
              nextCursor: 'cursor-page2',
            ),
          ),
        );
        when(() => mockGetNotifications(cursor: 'cursor-page2')).thenAnswer(
          (_) async =>
              Right(NotificationsPage(data: [notification3], nextCursor: null)),
        );
      },
      build: () => cubit,
      act: (c) async {
        await c.load();
        await c.loadMore();
      },
      verify: (c) {
        final state = c.state;
        final data = (state.listResult as Data<List<NotificationModel>>).data;
        expect(data.length, 3);
        expect(state.nextCursor, isNull);
        expect(state.isLoadingMore, false);
      },
    );

    // TC-2-38: loadMore() does nothing when nextCursor is null
    blocTest<NotificationsCubit, NotificationsState>(
      'TC-2-38: loadMore() is no-op when no nextCursor',
      setUp: () {
        when(() => mockGetNotifications()).thenAnswer(
          (_) async =>
              Right(NotificationsPage(data: [notification1], nextCursor: null)),
        );
      },
      build: () => cubit,
      act: (c) async {
        await c.load();
        await c.loadMore(); // should be ignored since nextCursor == null
      },
      verify: (c) {
        verify(() => mockGetNotifications()).called(1);
        verifyNever(() => mockGetNotifications(cursor: any(named: 'cursor')));
      },
    );

    // TC-2-38b (Caso 9C.2): calling loadMore() a second time while the first
    // call is still in flight (isLoadingMore == true) must be a no-op — it
    // must NOT trigger a second request to the use case.
    blocTest<NotificationsCubit, NotificationsState>(
      'TC-2-38b: a concurrent loadMore() call while isLoadingMore == true is '
      'a no-op and does not duplicate the request',
      setUp: () {
        when(() => mockGetNotifications()).thenAnswer(
          (_) async => Right(
            NotificationsPage(data: [notification1], nextCursor: 'cursor-1'),
          ),
        );
      },
      build: () => cubit,
      act: (c) async {
        await c.load();

        final pageCompleter = Completer<Either<DomainException, NotificationsPage>>();
        when(
          () => mockGetNotifications(cursor: 'cursor-1'),
        ).thenAnswer((_) => pageCompleter.future);

        // Fire the first loadMore() without awaiting it — it sets
        // isLoadingMore = true and then awaits the (still pending) use case.
        final firstCall = c.loadMore();

        // While the first call is in flight, fire a second loadMore(): it
        // must be a no-op since state.isLoadingMore is already true.
        await c.loadMore();

        // Now resolve the first call's future so it can complete.
        pageCompleter.complete(
          Right(NotificationsPage(data: [notification2], nextCursor: null)),
        );
        await firstCall;
      },
      verify: (c) {
        verify(() => mockGetNotifications()).called(1);
        verify(() => mockGetNotifications(cursor: 'cursor-1')).called(1);
        final state = c.state;
        final data = (state.listResult as Data<List<NotificationModel>>).data;
        expect(data.length, 2);
        expect(state.isLoadingMore, false);
      },
    );
  });

  group('NotificationsCubit — markRead optimistic update', () {
    // TC-2-39: markRead() optimistically marks item as read and decrements unreadCount
    blocTest<NotificationsCubit, NotificationsState>(
      'TC-2-39: markRead() optimistically updates list and unreadCount',
      setUp: () {
        when(() => mockGetNotifications()).thenAnswer(
          (_) async => Right(
            NotificationsPage(
              data: [notification1, notification2, notification3],
            ),
          ),
        );
        when(
          () => mockMarkRead('n1'),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => cubit,
      act: (c) async {
        await c.load();
        await c.markRead('n1');
      },
      verify: (c) {
        final state = c.state;
        final data = (state.listResult as Data<List<NotificationModel>>).data;
        expect(data.firstWhere((n) => n.id == 'n1').isRead, true);
        expect(state.unreadCount, 1); // was 2, now 1 after marking n1 read
        verify(() => mockMarkRead('n1')).called(1);
      },
    );
  });

  group('NotificationsCubit — markAllRead optimistic update', () {
    // TC-2-40: markAllRead() marks all items read and sets unreadCount to 0
    blocTest<NotificationsCubit, NotificationsState>(
      'TC-2-40: markAllRead() sets all notifications as read',
      setUp: () {
        when(() => mockGetNotifications()).thenAnswer(
          (_) async => Right(
            NotificationsPage(
              data: [notification1, notification2, notification3],
            ),
          ),
        );
        when(
          () => mockMarkAllRead(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => cubit,
      act: (c) async {
        await c.load();
        await c.markAllRead();
      },
      verify: (c) {
        final state = c.state;
        final data = (state.listResult as Data<List<NotificationModel>>).data;
        expect(data.every((n) => n.isRead), true);
        expect(state.unreadCount, 0);
        verify(() => mockMarkAllRead()).called(1);
      },
    );
  });
}
