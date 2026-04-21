import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/home/presentation/widgets/home_event_card.dart';
import 'package:rideglory/l10n/app_localizations.dart';

void main() {
  testWidgets('calls onTap callback when card is tapped', (tester) async {
    var tapped = false;
    final event = _event(name: 'Ruta dominical');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeEventCard(
            event: event,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(HomeEventCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('renders uppercase event name and details button label', (
    tester,
  ) async {
    final event = _event(name: 'evento nocturno');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: HomeEventCard(event: event, onTap: () {})),
      ),
    );

    expect(find.text('EVENTO NOCTURNO'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data?.toLowerCase().contains('detalle') ?? false),
      ),
      findsOneWidget,
    );
  });
}

EventModel _event({required String name}) {
  final date = DateTime(2026, 4, 22);
  return EventModel(
    id: 'event-id',
    ownerId: 'owner',
    name: name,
    description: 'desc',
    city: 'Medellin',
    startDate: date,
    difficulty: EventDifficulty.two,
    meetingPoint: 'A',
    destination: 'B',
    meetingTime: date,
    eventType: EventType.onRoad,
  );
}
