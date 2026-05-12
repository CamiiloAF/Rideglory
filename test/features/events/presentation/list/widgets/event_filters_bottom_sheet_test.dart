import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart';

class MockEventsCubit extends Mock implements EventsCubit {}

void main() {
  late MockEventsCubit mockEventsCubit;

  setUp(() {
    mockEventsCubit = MockEventsCubit();
    when(() => mockEventsCubit.filters).thenReturn(const EventFilters());
    when(() => mockEventsCubit.state).thenReturn(
      const ResultState.data(data: []),
    );
    when(() => mockEventsCubit.stream).thenAnswer((_) => Stream.empty());
  });

  group('EventFiltersBottomSheet — Filter Badge Tests (US-2-1, US-2-2)', () {
    // TC-2-18: Clear filters button is hidden when no filters active
    testWidgets(
      'TC-2-18: Clear filters button is hidden when no filters active',
      (WidgetTester tester) async {
        when(() => mockEventsCubit.filters).thenReturn(const EventFilters());

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<EventsCubit>.value(
              value: mockEventsCubit,
              child: const Scaffold(
                body: EventFiltersBottomSheet(),
              ),
            ),
          ),
        );

        expect(
          find.text('Limpiar filtros'),
          findsNothing,
          reason: 'Clear filters button should not be visible when no filters',
        );
      },
    );

    // TC-2-19: Clear filters button is visible when filters active
    testWidgets(
      'TC-2-19: Clear filters button is visible when filters active',
      (WidgetTester tester) async {
        when(() => mockEventsCubit.filters).thenReturn(
          const EventFilters(city: 'Medellín'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<EventsCubit>.value(
              value: mockEventsCubit,
              child: const Scaffold(
                body: EventFiltersBottomSheet(),
              ),
            ),
          ),
        );

        expect(
          find.text('Limpiar filtros'),
          findsWidgets,
          reason: 'Clear filters button should be visible when filters active',
        );
      },
    );

    // TC-2-20: Tapping clear filters button calls clearFilters()
    testWidgets(
      'TC-2-20: Tapping clear filters button calls clearFilters()',
      (WidgetTester tester) async {
        when(() => mockEventsCubit.filters).thenReturn(
          const EventFilters(city: 'Medellín'),
        );
        when(() => mockEventsCubit.clearFilters()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<EventsCubit>.value(
              value: mockEventsCubit,
              child: const Scaffold(
                body: EventFiltersBottomSheet(),
              ),
            ),
          ),
        );

        // Find and tap the clear filters button
        final clearButton = find.text('Limpiar filtros');
        expect(clearButton, findsWidgets);

        await tester.tap(clearButton.first);
        await tester.pumpAndSettle();

        verify(() => mockEventsCubit.clearFilters()).called(1);
      },
    );
  });
}
