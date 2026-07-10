// Widget tests for HomeEventsSection.
//
// Verifies that the events carousel section renders the correct child
// widget based on the `events` list passed in (empty state vs carousel).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/home/presentation/widgets/home_empty_events_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_event_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_events_section.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

final _mockEvent = EventModel(
  id: 'evt-1',
  ownerId: 'owner-1',
  name: 'Ruta del café',
  description: 'Paseo turístico',
  eventType: EventType.onRoad,
  difficulty: EventDifficulty.two,
  startDate: DateTime(2026, 6, 15),
  meetingTime: DateTime(2026, 6, 15, 7, 0),
  state: EventState.scheduled,
);

Widget _wrap({required List<EventModel> events}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: SingleChildScrollView(child: HomeEventsSection(events: events)),
        ),
      ),
      GoRoute(
        name: AppRoutes.events,
        path: '/events',
        builder: (_, _) => const Scaffold(body: SizedBox()),
      ),
      GoRoute(
        name: AppRoutes.eventDetail,
        path: '/events/detail',
        builder: (_, _) => const Scaffold(body: SizedBox()),
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
  // ── TC-events-section-1: events vacío → HomeEmptyEventsCard ────────────────

  testWidgets(
    'TC-events-section-1: events=[] → renders HomeEmptyEventsCard, no carousel',
    (tester) async {
      await tester.pumpWidget(_wrap(events: const []));
      await tester.pump();

      expect(find.byType(HomeEmptyEventsCard), findsOneWidget);
      expect(find.byType(HomeEventCard), findsNothing);
    },
  );

  // ── TC-events-section-2: events con datos → carrusel, no empty card ────────

  testWidgets('TC-events-section-2: events with data → renders carousel with '
      'HomeEventCard, no HomeEmptyEventsCard', (tester) async {
    await tester.pumpWidget(_wrap(events: [_mockEvent]));
    await tester.pump();

    expect(find.byType(HomeEventCard), findsOneWidget);
    expect(find.byType(HomeEmptyEventsCard), findsNothing);
  });
}
