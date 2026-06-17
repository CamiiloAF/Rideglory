import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/archive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/delete_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/unarchive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_archived_section.dart';
import 'package:rideglory/l10n/app_localizations.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockVehicleActionCubit extends MockCubit<VehicleActionState>
    implements VehicleActionCubit {}

class MockVehicleCubit extends MockCubit<ResultState<List<VehicleModel>>>
    implements VehicleCubit {}

class MockGetMyVehiclesUseCase extends Mock implements GetMyVehiclesUseCase {}

class MockSetMainVehicleUseCase extends Mock implements SetMainVehicleUseCase {}

class MockUpdateVehicleUseCase extends Mock implements UpdateVehicleUseCase {}

class MockDeleteVehicleUseCase extends Mock implements DeleteVehicleUseCase {}

class MockArchiveVehicleUseCase extends Mock implements ArchiveVehicleUseCase {}

class MockUnarchiveVehicleUseCase extends Mock
    implements UnarchiveVehicleUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _archivedVehicle = VehicleModel(
  id: 'v-arch',
  name: 'Honda Archivada',
  currentMileage: 5000,
  isArchived: true,
);

const _archivedVehicle2 = VehicleModel(
  id: 'v-arch2',
  name: 'Yamaha Archivada',
  currentMileage: 3000,
  isArchived: true,
);

// ─── Test helper ─────────────────────────────────────────────────────────────

Widget _wrap({
  required Widget child,
  required VehicleCubit vehicleCubit,
  required VehicleActionCubit actionCubit,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<VehicleCubit>.value(value: vehicleCubit),
          BlocProvider<VehicleActionCubit>.value(value: actionCubit),
        ],
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

void main() {
  late MockVehicleCubit vehicleCubit;
  late MockVehicleActionCubit actionCubit;

  setUp(() {
    vehicleCubit = MockVehicleCubit();
    actionCubit = MockVehicleActionCubit();

    when(() => vehicleCubit.state).thenReturn(
      const ResultState<List<VehicleModel>>.initial(),
    );
    when(() => actionCubit.state).thenReturn(
      const VehicleActionState.initial(),
    );

    // Register real VehicleActionCubit factory in GetIt for bottom sheet tests
    final getIt = GetIt.instance;
    if (getIt.isRegistered<VehicleActionCubit>()) {
      getIt.unregister<VehicleActionCubit>();
    }
    final mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    getIt.registerFactory<VehicleActionCubit>(
      () => VehicleActionCubit(
        MockDeleteVehicleUseCase(),
        MockArchiveVehicleUseCase(),
        MockUnarchiveVehicleUseCase(),
        vehicleCubit,
        mockAnalytics,
      ),
    );
  });

  tearDown(() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<VehicleActionCubit>()) {
      getIt.unregister<VehicleActionCubit>();
    }
  });

  // ── Test 1 ─────────────────────────────────────────────────────────────────

  testWidgets(
    'TC-arch-1: empty archivedVehicles renders SizedBox.shrink (nothing visible)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          vehicleCubit: vehicleCubit,
          actionCubit: actionCubit,
          child: const GarageArchivedSection(
            archivedVehicles: [],
            onRestoreTap: _noop,
          ),
        ),
      );
      await tester.pump();

      // No ARCHIVADOS text visible
      expect(find.text('ARCHIVADOS'), findsNothing);
    },
  );

  // ── Test 2 ─────────────────────────────────────────────────────────────────

  testWidgets(
    'TC-arch-2: with archived vehicles header shows correct count',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          vehicleCubit: vehicleCubit,
          actionCubit: actionCubit,
          child: const GarageArchivedSection(
            archivedVehicles: [_archivedVehicle, _archivedVehicle2],
            onRestoreTap: _noop,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ARCHIVADOS'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    },
  );

  // ── Test 3 ─────────────────────────────────────────────────────────────────

  testWidgets(
    'TC-arch-3: tapping header expands section and shows vehicle list',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          vehicleCubit: vehicleCubit,
          actionCubit: actionCubit,
          child: const GarageArchivedSection(
            archivedVehicles: [_archivedVehicle],
            onRestoreTap: _noop,
          ),
        ),
      );
      await tester.pump();

      // Initially collapsed — vehicle name not visible
      expect(find.text('Honda Archivada'), findsNothing);

      // Tap header to expand
      await tester.tap(find.text('ARCHIVADOS'));
      await tester.pump();

      // Now vehicle shows
      expect(find.text('Honda Archivada'), findsOneWidget);
    },
  );

  // ── Test 4 ─────────────────────────────────────────────────────────────────

  testWidgets(
    'TC-arch-4: tapping archived vehicle calls onRestoreTap',
    (tester) async {
      VehicleModel? tappedVehicle;

      await tester.pumpWidget(
        _wrap(
          vehicleCubit: vehicleCubit,
          actionCubit: actionCubit,
          child: GarageArchivedSection(
            archivedVehicles: const [_archivedVehicle],
            onRestoreTap: (v) => tappedVehicle = v,
          ),
        ),
      );
      await tester.pump();

      // Expand section
      await tester.tap(find.text('ARCHIVADOS'));
      await tester.pump();

      // Tap on the vehicle item
      await tester.tap(find.text('Honda Archivada'));
      await tester.pump();

      expect(tappedVehicle, equals(_archivedVehicle));
    },
  );

  // ── Test 5 ─────────────────────────────────────────────────────────────────

  testWidgets(
    'TC-arch-5: section shows count=1 badge for single archived vehicle',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          vehicleCubit: vehicleCubit,
          actionCubit: actionCubit,
          child: const GarageArchivedSection(
            archivedVehicles: [_archivedVehicle],
            onRestoreTap: _noop,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ARCHIVADOS'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    },
  );
}

void _noop(VehicleModel _) {}
