// Widget tests for HomeGarageSection.
//
// Verifies that the section renders the correct child widget based on
// VehicleCubit state without touching HomeCubit.loadHomeData.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/home/presentation/cubit/home_cubit.dart';
import 'package:rideglory/features/home/presentation/widgets/home_empty_garage_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_section.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockVehicleCubit extends MockCubit<ResultState<List<VehicleModel>>>
    implements VehicleCubit {}

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _mainVehicle = VehicleModel(
  id: 'v-main',
  name: 'BMW R1250GS',
  currentMileage: 12000,
  isMainVehicle: true,
);

const _otherVehicle = VehicleModel(
  id: 'v-other',
  name: 'Honda CB500',
  currentMileage: 5000,
  isMainVehicle: false,
);

const _archivedVehicle = VehicleModel(
  id: 'v-arch',
  name: 'Vehículo 33',
  currentMileage: 1000,
  isMainVehicle: false,
  isArchived: true,
);

// ─── Test helper ──────────────────────────────────────────────────────────────

Widget _wrap({required VehicleCubit vehicleCubit, HomeCubit? homeCubit}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<VehicleCubit>.value(value: vehicleCubit),
              if (homeCubit != null)
                BlocProvider<HomeCubit>.value(value: homeCubit),
            ],
            child: const SingleChildScrollView(child: HomeGarageSection()),
          ),
        ),
      ),
      GoRoute(
        name: AppRoutes.garage,
        path: AppRoutes.garage,
        builder: (_, _) => const Scaffold(body: SizedBox()),
      ),
      GoRoute(
        name: AppRoutes.createVehicle,
        path: '/vehicle/create',
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
  late MockVehicleCubit vehicleCubit;
  late MockHomeCubit homeCubit;

  setUp(() {
    vehicleCubit = MockVehicleCubit();
    homeCubit = MockHomeCubit();
    when(() => homeCubit.state).thenReturn(const HomeInitial());
  });

  // ── TC-garage-section-1: Initial state renders placeholder ────────────────

  testWidgets('TC-garage-section-1: VehicleCubit.initial → placeholder 200px, '
      'no HomeGarageCard, no HomeEmptyGarageCard', (tester) async {
    when(
      () => vehicleCubit.state,
    ).thenReturn(const ResultState<List<VehicleModel>>.initial());

    await tester.pumpWidget(_wrap(vehicleCubit: vehicleCubit));
    await tester.pump();

    expect(find.byType(HomeGarageCard), findsNothing);
    expect(find.byType(HomeEmptyGarageCard), findsNothing);
  });

  // ── TC-garage-section-2: Loading state renders placeholder ────────────────

  testWidgets('TC-garage-section-2: VehicleCubit.loading → placeholder, '
      'no HomeGarageCard, no HomeEmptyGarageCard', (tester) async {
    when(
      () => vehicleCubit.state,
    ).thenReturn(const ResultState<List<VehicleModel>>.loading());

    await tester.pumpWidget(_wrap(vehicleCubit: vehicleCubit));
    await tester.pump();

    expect(find.byType(HomeGarageCard), findsNothing);
    expect(find.byType(HomeEmptyGarageCard), findsNothing);
  });

  // ── TC-garage-section-3: Data with main vehicle renders HomeGarageCard ─────

  testWidgets(
    'TC-garage-section-3: VehicleCubit.data with isMainVehicle=true → '
    'HomeGarageCard with that vehicle',
    (tester) async {
      when(() => vehicleCubit.state).thenReturn(
        const ResultState<List<VehicleModel>>.data(
          data: [_mainVehicle, _otherVehicle],
        ),
      );

      await tester.pumpWidget(_wrap(vehicleCubit: vehicleCubit));
      await tester.pump();

      expect(find.byType(HomeGarageCard), findsOneWidget);
      expect(find.byType(HomeEmptyGarageCard), findsNothing);
      final card = tester.widget<HomeGarageCard>(find.byType(HomeGarageCard));
      expect(card.vehicle.id, equals(_mainVehicle.id));
    },
  );

  // ── TC-garage-section-4: Data without main vehicle uses first ─────────────

  testWidgets(
    'TC-garage-section-4: VehicleCubit.data with no isMainVehicle=true → '
    'HomeGarageCard with first vehicle',
    (tester) async {
      when(() => vehicleCubit.state).thenReturn(
        const ResultState<List<VehicleModel>>.data(data: [_otherVehicle]),
      );

      await tester.pumpWidget(_wrap(vehicleCubit: vehicleCubit));
      await tester.pump();

      expect(find.byType(HomeGarageCard), findsOneWidget);
      final card = tester.widget<HomeGarageCard>(find.byType(HomeGarageCard));
      expect(card.vehicle.id, equals(_otherVehicle.id));
    },
  );

  // ── TC-garage-section-5: Data([]) → HomeEmptyGarageCard ──────────────────

  testWidgets(
    'TC-garage-section-5: VehicleCubit.data([]) → HomeEmptyGarageCard',
    (tester) async {
      when(
        () => vehicleCubit.state,
      ).thenReturn(const ResultState<List<VehicleModel>>.data(data: []));

      await tester.pumpWidget(
        _wrap(vehicleCubit: vehicleCubit, homeCubit: homeCubit),
      );
      await tester.pump();

      expect(find.byType(HomeEmptyGarageCard), findsOneWidget);
      expect(find.byType(HomeGarageCard), findsNothing);
    },
  );

  testWidgets(
    'TC-garage-section-5b: VehicleCubit.empty → HomeEmptyGarageCard',
    (tester) async {
      when(
        () => vehicleCubit.state,
      ).thenReturn(const ResultState<List<VehicleModel>>.empty());

      await tester.pumpWidget(
        _wrap(vehicleCubit: vehicleCubit, homeCubit: homeCubit),
      );
      await tester.pump();

      expect(find.byType(HomeEmptyGarageCard), findsOneWidget);
      expect(find.byType(HomeGarageCard), findsNothing);
    },
  );

  // ── TC-garage-section-6: Reactivity without HomeCubit.loadHomeData ────────

  testWidgets(
    'TC-garage-section-6: emitting new VehicleCubit.data with different '
    'isMainVehicle=true updates UI without calling HomeCubit.loadHomeData',
    (tester) async {
      // Start: only _otherVehicle with no main — initial state
      when(() => vehicleCubit.state).thenReturn(
        const ResultState<List<VehicleModel>>.data(data: [_otherVehicle]),
      );

      final streamController =
          StreamController<ResultState<List<VehicleModel>>>();
      whenListen(
        vehicleCubit,
        streamController.stream,
        initialState: const ResultState<List<VehicleModel>>.data(
          data: [_otherVehicle],
        ),
      );

      await tester.pumpWidget(
        _wrap(vehicleCubit: vehicleCubit, homeCubit: homeCubit),
      );
      await tester.pump();

      // Initially shows _otherVehicle
      expect(find.byType(HomeGarageCard), findsOneWidget);
      final cardBefore = tester.widget<HomeGarageCard>(
        find.byType(HomeGarageCard),
      );
      expect(cardBefore.vehicle.id, equals(_otherVehicle.id));

      // Emit new state with _mainVehicle as main
      when(() => vehicleCubit.state).thenReturn(
        const ResultState<List<VehicleModel>>.data(
          data: [_otherVehicle, _mainVehicle],
        ),
      );
      streamController.add(
        const ResultState<List<VehicleModel>>.data(
          data: [_otherVehicle, _mainVehicle],
        ),
      );

      await tester.pumpAndSettle();
      await streamController.close();

      // Now should show _mainVehicle
      expect(find.byType(HomeGarageCard), findsOneWidget);
      final cardAfter = tester.widget<HomeGarageCard>(
        find.byType(HomeGarageCard),
      );
      expect(cardAfter.vehicle.id, equals(_mainVehicle.id));

      // HomeCubit.loadHomeData must NOT have been called
      verifyNever(() => homeCubit.loadHomeData());
    },
  );

  // ── TC-garage-section-7: todos archivados → HomeEmptyGarageCard ───────────

  testWidgets(
    'TC-garage-section-7: data con todos isArchived=true → HomeEmptyGarageCard, '
    'nunca HomeGarageCard',
    (tester) async {
      when(() => vehicleCubit.state).thenReturn(
        const ResultState<List<VehicleModel>>.data(data: [_archivedVehicle]),
      );

      await tester.pumpWidget(
        _wrap(vehicleCubit: vehicleCubit, homeCubit: homeCubit),
      );
      await tester.pump();

      expect(
        find.byType(HomeEmptyGarageCard),
        findsOneWidget,
        reason:
            'Con todos los vehículos archivados debe mostrarse el estado vacío',
      );
      expect(find.byType(HomeGarageCard), findsNothing);
    },
  );

  // ── TC-garage-section-8: principal archivado, activo sin main → usa activo ─

  testWidgets(
    'TC-garage-section-8: lista con un vehículo archivado (ex-principal) y uno '
    'activo → HomeGarageCard muestra el activo',
    (tester) async {
      const activeNoMain = VehicleModel(
        id: 'v-active',
        name: 'Yamaha MT-07',
        currentMileage: 3000,
        isMainVehicle: false,
        isArchived: false,
      );
      when(() => vehicleCubit.state).thenReturn(
        const ResultState<List<VehicleModel>>.data(
          data: [_archivedVehicle, activeNoMain],
        ),
      );

      await tester.pumpWidget(_wrap(vehicleCubit: vehicleCubit));
      await tester.pump();

      expect(find.byType(HomeGarageCard), findsOneWidget);
      final card = tester.widget<HomeGarageCard>(find.byType(HomeGarageCard));
      expect(
        card.vehicle.id,
        equals(activeNoMain.id),
        reason: 'El vehículo archivado no debe aparecer como principal en Home',
      );
    },
  );
}
