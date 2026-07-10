// Widget tests for NotificationBellButton (Casos 4.1 and 7.4):
// - Tapping the bell navigates to /notifications.
// - The badge reacts to changes in NotificationsCubit.state.unreadCount
//   without recreating the widget (cubit is a singleton in the real app).

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:rideglory/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class MockNotificationsCubit extends MockCubit<NotificationsState>
    implements NotificationsCubit {}

Widget _wrap(NotificationsCubit cubit) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: BlocProvider<NotificationsCubit>.value(
            value: cubit,
            child: const NotificationBellButton(),
          ),
        ),
      ),
      GoRoute(
        name: AppRoutes.notifications,
        path: AppRoutes.notifications,
        builder: (_, _) => const Scaffold(body: Text('Notifications page')),
      ),
    ],
  );

  return MaterialApp.router(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    routerConfig: router,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
  );
}

void main() {
  late MockNotificationsCubit cubit;

  setUp(() {
    cubit = MockNotificationsCubit();
  });

  tearDown(() => cubit.close());

  testWidgets(
    'TC-notif-bell-1: tapping the bell navigates to /notifications',
    (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const NotificationsState(unreadCount: 0));

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      expect(find.text('Notifications page'), findsNothing);

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.text('Notifications page'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-notif-bell-2: unreadCount == 0 → outlined icon, no badge',
    (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const NotificationsState(unreadCount: 0));

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsNothing);
      expect(find.text('0'), findsNothing);
    },
  );

  testWidgets(
    'TC-notif-bell-3: unreadCount > 0 → filled icon and badge with count',
    (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const NotificationsState(unreadCount: 3));

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
      expect(find.text('3'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-notif-bell-4: unreadCount > 99 → badge shows "99+"',
    (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const NotificationsState(unreadCount: 150));

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      expect(find.text('99+'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-notif-bell-5: badge is reactive to unreadCount changes without '
    'recreating the widget (cubit lifecycle mirrors @lazySingleton usage)',
    (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const NotificationsState(unreadCount: 0));

      final streamController = StreamController<NotificationsState>();
      whenListen(
        cubit,
        streamController.stream,
        initialState: const NotificationsState(unreadCount: 0),
      );

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      expect(find.text('0'), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

      when(
        () => cubit.state,
      ).thenReturn(const NotificationsState(unreadCount: 5));
      streamController.add(const NotificationsState(unreadCount: 5));
      await tester.pump();
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);

      await streamController.close();
    },
  );
}
