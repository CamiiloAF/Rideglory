import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/events_page_view.dart';

class MockEventsCubit extends Mock implements EventsCubit {}

void main() {
  late MockEventsCubit mockEventsCubit;

  setUp(() {
    mockEventsCubit = MockEventsCubit();
    when(() => mockEventsCubit.filters).thenReturn(const EventFilters());
    when(() => mockEventsCubit.stream).thenAnswer((_) => Stream.empty());
  });

  group('EventsPageView — Empty State Tests (US-2-1, US-2-2)', () {
    // TC-2-21: Filtered empty state shows "No hay eventos con estos filtros"
    testWidgets(
      'TC-2-21: Filtered empty state shows filtered empty message',
      (WidgetTester tester) async {
        when(() => mockEventsCubit.filters).thenReturn(
          const EventFilters(city: 'Medellín'),
        );
        when(() => mockEventsCubit.state).thenReturn(
          const ResultState.empty(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<EventsCubit>.value(
              value: mockEventsCubit,
              child: const Scaffold(
                body: EventsPageView(),
              ),
            ),
          ),
        );

        expect(
          find.text('No hay eventos con estos filtros'),
          findsWidgets,
          reason: 'Empty state should show filtered message when filters active',
        );
      },
    );

    // TC-2-22: All-events empty state shows original message
    testWidgets(
      'TC-2-22: All-events empty state shows original message',
      (WidgetTester tester) async {
        when(() => mockEventsCubit.filters).thenReturn(const EventFilters());
        when(() => mockEventsCubit.state).thenReturn(
          const ResultState.empty(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<EventsCubit>.value(
              value: mockEventsCubit,
              child: const Scaffold(
                body: EventsPageView(),
              ),
            ),
          ),
        );

        // Should show original empty state message
        // Note: The exact message depends on the implementation
        // but it should NOT be the filtered message
        expect(
          find.text('No hay eventos con estos filtros'),
          findsNothing,
          reason: 'Empty state should not show filtered message when no filters',
        );
      },
    );

    // TC-2-23: Filtered empty state shows clear filters button
    testWidgets(
      'TC-2-23: Filtered empty state shows clear filters button',
      (WidgetTester tester) async {
        when(() => mockEventsCubit.filters).thenReturn(
          const EventFilters(city: 'Medellín'),
        );
        when(() => mockEventsCubit.state).thenReturn(
          const ResultState.empty(),
        );
        when(() => mockEventsCubit.clearFilters()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<EventsCubit>.value(
              value: mockEventsCubit,
              child: const Scaffold(
                body: EventsPageView(),
              ),
            ),
          ),
        );

        expect(
          find.text('Limpiar filtros'),
          findsWidgets,
          reason: 'Filtered empty state should show clear filters button',
        );
      },
    );

    // TC-2-24: Tapping clear filters in empty state calls clearFilters()
    testWidgets(
      'TC-2-24: Tapping clear filters in empty state calls clearFilters()',
      (WidgetTester tester) async {
        when(() => mockEventsCubit.filters).thenReturn(
          const EventFilters(city: 'Medellín'),
        );
        when(() => mockEventsCubit.state).thenReturn(
          const ResultState.empty(),
        );
        when(() => mockEventsCubit.clearFilters()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<EventsCubit>.value(
              value: mockEventsCubit,
              child: const Scaffold(
                body: EventsPageView(),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Limpiar filtros'));
        await tester.pumpAndSettle();

        verify(() => mockEventsCubit.clearFilters()).called(1);
      },
    );

    // TC-2-25: Data state is not empty state
    testWidgets(
      'TC-2-25: Data state shows events (not empty state)',
      (WidgetTester tester) async {
        const mockEvent = EventModel(
          id: '1',
          name: 'Test Event',
          description: 'Test event',
          eventType: EventType.touring,
          difficulty: EventDifficulty.moderate,
          city: 'Medellín',
          startDate: '2026-05-20',
          endDate: '2026-05-20',
          state: EventState.scheduled,
          isFree: true,
          attendeesCount: 10,
          routeDistance: null,
        );

        when(() => mockEventsCubit.state).thenReturn(
          const ResultState.data(data: [mockEvent]),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<EventsCubit>.value(
              value: mockEventsCubit,
              child: const Scaffold(
                body: EventsPageView(),
              ),
            ),
          ),
        );

        expect(
          find.text('No hay eventos con estos filtros'),
          findsNothing,
          reason: 'Should not show empty state when events exist',
        );
      },
    );
  });
}
