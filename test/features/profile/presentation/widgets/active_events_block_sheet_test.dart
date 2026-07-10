// Widget tests for ActiveEventsBlockSheet in isolation: shows the blocking
// event's name (AC3) and its CTA navigates to AppRoutes.myEvents (AC3).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/profile/presentation/widgets/active_events_block_sheet.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

EventModel _buildEvent(String name) {
  return EventModel(
    ownerId: 'owner-1',
    name: name,
    description: 'desc',
    startDate: DateTime(2026, 8, 1),
    difficulty: EventDifficulty.one,
    meetingTime: DateTime(2026, 8, 1, 8),
    eventType: EventType.onRoad,
    state: EventState.scheduled,
  );
}

void main() {
  Widget buildTestApp(VoidCallback onOpenSheet) {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          name: AppRoutes.home,
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: onOpenSheet,
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/events/mine',
          name: AppRoutes.myEvents,
          builder: (context, state) =>
              const Scaffold(body: Text('my-events-screen')),
        ),
      ],
    );

    return MaterialApp.router(
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      routerConfig: router,
    );
  }

  testWidgets('muestra el nombre del primer evento bloqueante', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      buildTestApp(() {}),
    );

    final elementFinder = find.byType(ElevatedButton);
    capturedContext = tester.element(elementFinder);

    ActiveEventsBlockSheet.show(
      context: capturedContext,
      activeEvents: [_buildEvent('Rodada al Nevado')],
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Rodada al Nevado'), findsOneWidget);
  });

  testWidgets('el CTA navega a AppRoutes.myEvents', (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(buildTestApp(() {}));

    final elementFinder = find.byType(ElevatedButton);
    capturedContext = tester.element(elementFinder);

    ActiveEventsBlockSheet.show(
      context: capturedContext,
      activeEvents: [_buildEvent('Rodada al Nevado')],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver mis eventos'));
    await tester.pumpAndSettle();

    expect(find.text('my-events-screen'), findsOneWidget);
  });
}
