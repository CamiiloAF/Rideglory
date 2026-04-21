import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/home/presentation/widgets/home_empty_events_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_event_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_events_section.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

void main() {
  testWidgets('shows empty card when events list is empty', (tester) async {
    await tester.pumpWidget(_testApp(child: const HomeEventsSection(events: [])));

    expect(find.byType(HomeEmptyEventsCard), findsOneWidget);
    expect(find.byType(HomeEventCard), findsNothing);
  });

  testWidgets('renders one HomeEventCard per event', (tester) async {
    final now = DateTime.now();
    final events = [
      _event(id: '1', startDate: now.add(const Duration(days: 1))),
      _event(id: '2', startDate: now.add(const Duration(days: 2))),
    ];

    await tester.pumpWidget(_testApp(child: HomeEventsSection(events: events)));

    expect(find.byType(HomeEventCard), findsNWidgets(2));
    expect(find.byType(HomeEmptyEventsCard), findsNothing);
  });

  testWidgets('navigates to event detail route when tapping card', (tester) async {
    final now = DateTime.now();
    final events = [_event(id: 'detail-id', startDate: now.add(const Duration(days: 1)))];
    final router = _buildRouter(HomeEventsSection(events: events));

    await tester.pumpWidget(_testRouterApp(router));

    await tester.tap(find.byType(HomeEventCard));
    await tester.pumpAndSettle();

    expect(find.text('Event detail page'), findsOneWidget);
  });
}

GoRouter _buildRouter(Widget home) {
  return GoRouter(
    initialLocation: '/test-home',
    routes: [
      GoRoute(
        path: '/test-home',
        builder: (context, state) => Scaffold(body: home),
      ),
      GoRoute(
        path: AppRoutes.eventDetail,
        name: AppRoutes.eventDetail,
        builder: (context, state) => const Scaffold(body: Text('Event detail page')),
      ),
    ],
  );
}

Widget _testApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      AppLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Widget _testRouterApp(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      AppLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

EventModel _event({required String id, required DateTime startDate}) {
  return EventModel(
    id: id,
    ownerId: 'owner',
    name: 'Event $id',
    description: 'Description',
    city: 'Medellin',
    startDate: startDate,
    difficulty: EventDifficulty.one,
    meetingPoint: 'Point A',
    destination: 'Point B',
    meetingTime: startDate,
    eventType: EventType.onRoad,
  );
}
