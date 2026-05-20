import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/place_service.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart';
import 'package:rideglory/l10n/app_localizations.dart';

class MockEventsCubit extends Mock implements EventsCubit {}

class MockPlaceService extends Mock implements PlaceService {}

Widget _buildTestWidget(MockEventsCubit mockCubit) {
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
    home: BlocProvider<EventsCubit>.value(
      value: mockCubit,
      child: Builder(
        builder: (context) => Scaffold(
          body: EventFiltersBottomSheet(cubitContext: context),
        ),
      ),
    ),
  );
}

void main() {
  late MockEventsCubit mockEventsCubit;
  final getIt = GetIt.instance;

  setUp(() {
    if (!getIt.isRegistered<PlaceService>()) {
      final mockPlaceService = MockPlaceService();
      when(
        () => mockPlaceService.autocomplete(any(), any()),
      ).thenAnswer((_) async => []);
      getIt.registerSingleton<PlaceService>(mockPlaceService);
    }

    mockEventsCubit = MockEventsCubit();
    when(() => mockEventsCubit.filters).thenReturn(const EventFilters());
    when(() => mockEventsCubit.state).thenReturn(
      const ResultState<List<EventModel>>.data(data: []),
    );
    when(() => mockEventsCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() async {
    if (getIt.isRegistered<PlaceService>()) {
      await getIt.unregister<PlaceService>();
    }
  });

  group('EventFiltersBottomSheet — Filter Tests (US-2-1, US-2-2)', () {
    testWidgets(
      'TC-2-18: Clear filters button is hidden when no filters active',
      (WidgetTester tester) async {
        when(() => mockEventsCubit.filters).thenReturn(const EventFilters());

        await tester.pumpWidget(_buildTestWidget(mockEventsCubit));
        await tester.pump();

        expect(find.text('Limpiar filtros'), findsNothing);
      },
    );

    testWidgets(
      'TC-2-19: Clear filters button is visible when filters active',
      (WidgetTester tester) async {
        when(() => mockEventsCubit.filters).thenReturn(
          const EventFilters(city: 'Medellín'),
        );

        await tester.pumpWidget(_buildTestWidget(mockEventsCubit));
        await tester.pump();

        expect(find.text('Limpiar filtros'), findsWidgets);
      },
    );

    testWidgets(
      'TC-2-20: Tapping clear filters button calls clearFilters()',
      (WidgetTester tester) async {
        when(() => mockEventsCubit.filters).thenReturn(
          const EventFilters(city: 'Medellín'),
        );
        when(() => mockEventsCubit.clearFilters()).thenAnswer((_) async {});

        await tester.pumpWidget(_buildTestWidget(mockEventsCubit));
        await tester.pump();

        final clearButton = find.text('Limpiar filtros');
        expect(clearButton, findsWidgets);

        await tester.tap(clearButton.first);
        await tester.pumpAndSettle();

        verify(() => mockEventsCubit.clearFilters()).called(1);
      },
    );
  });
}
