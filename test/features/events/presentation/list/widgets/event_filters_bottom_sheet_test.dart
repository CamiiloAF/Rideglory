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

/// Hosts the sheet behind a button so it is presented through a real
/// `showModalBottomSheet` route (matching production), letting "Aplicar" pop
/// the sheet without tearing down the test's root route.
Widget _buildHost(MockEventsCubit mockCubit) {
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
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  EventFiltersBottomSheet.show(context: context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.pumpWidget(_buildHost(_currentCubit));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

late MockEventsCubit _currentCubit;

void main() {
  final getIt = GetIt.instance;

  setUpAll(() => registerFallbackValue(const EventFilters()));

  setUp(() {
    if (!getIt.isRegistered<PlaceService>()) {
      final mockPlaceService = MockPlaceService();
      when(
        () => mockPlaceService.autocomplete(any(), any()),
      ).thenAnswer((_) async => []);
      getIt.registerSingleton<PlaceService>(mockPlaceService);
    }

    _currentCubit = MockEventsCubit();
    when(() => _currentCubit.filters).thenReturn(const EventFilters());
    when(() => _currentCubit.state).thenReturn(
      const ResultState<List<EventModel>>.data(data: []),
    );
    when(() => _currentCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => _currentCubit.updateFilters(any())).thenReturn(null);
  });

  tearDown(() async {
    if (getIt.isRegistered<PlaceService>()) {
      await getIt.unregister<PlaceService>();
    }
  });

  group('EventFiltersBottomSheet — Filter Tests (US-2-1, US-2-2)', () {
    testWidgets(
      'TC-2-18: header "Limpiar todo" is always visible',
      (WidgetTester tester) async {
        when(() => _currentCubit.filters).thenReturn(const EventFilters());

        await _openSheet(tester);

        expect(find.text('Limpiar todo'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-2-19: tapping "Cancelar" closes the sheet without applying filters',
      (WidgetTester tester) async {
        when(() => _currentCubit.filters).thenReturn(const EventFilters());

        await _openSheet(tester);
        expect(find.text('Cancelar'), findsOneWidget);

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        // Sheet closed and no filter change was committed.
        expect(find.text('Cancelar'), findsNothing);
        verifyNever(() => _currentCubit.updateFilters(any()));
      },
    );

    testWidgets(
      'TC-2-20: tapping "Aplicar" commits filters via updateFilters()',
      (WidgetTester tester) async {
        when(() => _currentCubit.filters).thenReturn(const EventFilters());

        await _openSheet(tester);

        await tester.tap(find.text('Aplicar'));
        await tester.pumpAndSettle();

        verify(() => _currentCubit.updateFilters(any())).called(1);
      },
    );
  });
}
