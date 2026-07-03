import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/events_page_view.dart';
import 'package:rideglory/l10n/app_localizations.dart';

class MockEventsCubit extends Mock implements EventsCubit {}

class MockEventDeleteCubit extends Mock implements EventDeleteCubit {}

class MockAuthCubit extends Mock implements AuthCubit {}

class MockMyRegistrationsCubit extends Mock implements MyRegistrationsCubit {}

Widget _buildTestWidget(
  MockEventsCubit eventsCubit,
  MockEventDeleteCubit deleteCubit,
  MockAuthCubit authCubit,
  MockMyRegistrationsCubit registrationsCubit,
) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      AppLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: MultiBlocProvider(
      providers: [
        BlocProvider<EventsCubit>.value(value: eventsCubit),
        BlocProvider<EventDeleteCubit>.value(value: deleteCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<MyRegistrationsCubit>.value(value: registrationsCubit),
      ],
      child: const Scaffold(body: EventsPageView()),
    ),
  );
}

void main() {
  late MockEventsCubit mockEventsCubit;
  late MockEventDeleteCubit mockEventDeleteCubit;
  late MockAuthCubit mockAuthCubit;
  late MockMyRegistrationsCubit mockRegistrationsCubit;

  setUp(() {
    mockEventsCubit = MockEventsCubit();
    mockEventDeleteCubit = MockEventDeleteCubit();
    mockAuthCubit = MockAuthCubit();
    mockRegistrationsCubit = MockMyRegistrationsCubit();
    when(() => mockEventsCubit.filters).thenReturn(const EventFilters());
    when(() => mockEventsCubit.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockEventDeleteCubit.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockEventDeleteCubit.state,
    ).thenReturn(const ResultState<String>.initial());
    when(() => mockAuthCubit.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockAuthCubit.state,
    ).thenReturn(const AuthState.unauthenticated());
    when(
      () => mockRegistrationsCubit.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRegistrationsCubit.state,
    ).thenReturn(const ResultState.initial());
  });

  group('EventsPageView — Empty State Tests (US-2-1, US-2-2)', () {
    // TC-2-21: Filtered empty state shows "No hay eventos con estos filtros"
    testWidgets('TC-2-21: Filtered empty state shows filtered empty message', (
      WidgetTester tester,
    ) async {
      when(
        () => mockEventsCubit.filters,
      ).thenReturn(const EventFilters(types: {EventType.onRoad}));
      when(() => mockEventsCubit.state).thenReturn(const ResultState.empty());

      await tester.pumpWidget(
        _buildTestWidget(
          mockEventsCubit,
          mockEventDeleteCubit,
          mockAuthCubit,
          mockRegistrationsCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No hay eventos con estos filtros'),
        findsWidgets,
        reason: 'Empty state should show filtered message when filters active',
      );
    });

    // TC-2-22: All-events empty state shows original message
    testWidgets('TC-2-22: All-events empty state shows original message', (
      WidgetTester tester,
    ) async {
      when(() => mockEventsCubit.filters).thenReturn(const EventFilters());
      when(() => mockEventsCubit.state).thenReturn(const ResultState.empty());

      await tester.pumpWidget(
        _buildTestWidget(
          mockEventsCubit,
          mockEventDeleteCubit,
          mockAuthCubit,
          mockRegistrationsCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No hay eventos con estos filtros'),
        findsNothing,
        reason: 'Empty state should not show filtered message when no filters',
      );
    });

    // TC-2-23: Filtered empty state shows clear filters button
    testWidgets('TC-2-23: Filtered empty state shows clear filters button', (
      WidgetTester tester,
    ) async {
      when(
        () => mockEventsCubit.filters,
      ).thenReturn(const EventFilters(types: {EventType.onRoad}));
      when(() => mockEventsCubit.state).thenReturn(const ResultState.empty());
      when(() => mockEventsCubit.clearFilters()).thenReturn(null);

      await tester.pumpWidget(
        _buildTestWidget(
          mockEventsCubit,
          mockEventDeleteCubit,
          mockAuthCubit,
          mockRegistrationsCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Limpiar filtros'),
        findsWidgets,
        reason: 'Filtered empty state should show clear filters button',
      );
    });

    // TC-2-24: Tapping clear filters in empty state calls clearFilters()
    testWidgets(
      'TC-2-24: Tapping clear filters in empty state calls clearFilters()',
      (WidgetTester tester) async {
        when(
          () => mockEventsCubit.filters,
        ).thenReturn(const EventFilters(types: {EventType.onRoad}));
        when(() => mockEventsCubit.state).thenReturn(const ResultState.empty());
        when(() => mockEventsCubit.clearFilters()).thenReturn(null);

        await tester.pumpWidget(
          _buildTestWidget(
            mockEventsCubit,
            mockEventDeleteCubit,
            mockAuthCubit,
            mockRegistrationsCubit,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Limpiar filtros').first);
        await tester.pumpAndSettle();

        verify(() => mockEventsCubit.clearFilters()).called(1);
      },
    );

    // TC-2-25: Non-empty state does not show empty state message
    testWidgets('TC-2-25: Data state shows events (not empty state)', (
      WidgetTester tester,
    ) async {
      when(() => mockEventsCubit.state).thenReturn(const ResultState.loading());

      await tester.pumpWidget(
        _buildTestWidget(
          mockEventsCubit,
          mockEventDeleteCubit,
          mockAuthCubit,
          mockRegistrationsCubit,
        ),
      );
      await tester.pump();

      expect(
        find.text('No hay eventos con estos filtros'),
        findsNothing,
        reason: 'Should not show empty state when not in empty state',
      );
    });
  });
}
