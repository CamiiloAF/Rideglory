// Widget tests for QA checklist rows 7.3 and 7.4 (vehicles_QA_CHECKLIST.md):
//
//   7.3 "Toca la tarjeta de un vehículo (principal u otro)" → navega al
//       detalle del vehículo (VehicleDetailPage) mostrando specs, último
//       mantenimiento, próximo programado y tarjetas de documentos
//       (SOAT/RTM).
//   7.4 "Vuelve del detalle al garage" → el garage hace refresh y refleja
//       cualquier cambio hecho en el detalle (ej. kilometraje actualizado).
//
// Uses a REAL VehicleCubit (only its use case dependencies are mocked) so
// that navigating garage → detail → back exercises the actual shared state
// that both screens read from, instead of a cubit mock that can't react to
// `updateMileage`.

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_vehicle_list_result.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_cubit.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/detail/vehicle_detail_page.dart';
import 'package:rideglory/features/vehicles/presentation/garage/cubit/vehicle_maintenances_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/garage_page_view.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockGetMyVehiclesUseCase extends Mock implements GetMyVehiclesUseCase {}

class MockSetMainVehicleUseCase extends Mock implements SetMainVehicleUseCase {}

class MockUpdateVehicleUseCase extends Mock implements UpdateVehicleUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockGetMaintenancesByVehicleIdUseCase extends Mock
    implements GetMaintenancesByVehicleIdUseCase {}

class MockSoatCubit extends MockCubit<ResultState<SoatModel>>
    implements SoatCubit {}

class MockTecnomecanicaCubit extends MockCubit<ResultState<TecnomecanicaModel>>
    implements TecnomecanicaCubit {}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _vehicleId = 'v-nav-detail-1';

const _vehicle = VehicleModel(
  id: _vehicleId,
  name: 'Kawasaki Versys',
  brand: 'Kawasaki',
  model: 'Versys 650',
  year: 2021,
  currentMileage: 8000,
  isMainVehicle: true,
);

final _lastCompleted = MaintenanceModel(
  id: 'm-last',
  vehicleId: _vehicleId,
  type: MaintenanceType.oilChange,
  mode: MaintenanceMode.completed,
  serviceDate: DateTime(2026, 5, 1),
  odometerAtService: 7500,
);

final _nextScheduled = MaintenanceModel(
  id: 'm-next',
  vehicleId: _vehicleId,
  type: MaintenanceType.brakeCheck,
  mode: MaintenanceMode.scheduled,
  nextDate: DateTime(2026, 12, 1),
  nextOdometer: 10000,
);

final _soatValid = SoatModel(
  id: 's-1',
  vehicleId: _vehicleId,
  expiryDate: DateTime.now().add(const Duration(days: 90)),
);

final _rtmValid = TecnomecanicaModel(
  id: 'r-1',
  vehicleId: _vehicleId,
  cdaName: 'CDA Test',
  startDate: DateTime.now().subtract(const Duration(days: 30)),
  expiryDate: DateTime.now().add(const Duration(days: 90)),
);

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap(VehicleCubit vehicleCubit) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: AppRoutes.garage,
        builder: (_, _) => GaragePageView(loadVehicles: () async {}),
      ),
      GoRoute(
        name: AppRoutes.vehicleDetail,
        path: '/vehicles/detail',
        builder: (_, state) =>
            VehicleDetailPage(vehicle: state.extra as VehicleModel),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    builder: (context, child) =>
        BlocProvider<VehicleCubit>.value(value: vehicleCubit, child: child!),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_vehicle);
  });

  late MockGetMyVehiclesUseCase getVehiclesUseCase;
  late MockSetMainVehicleUseCase setMainUseCase;
  late MockUpdateVehicleUseCase updateVehicleUseCase;
  late MockAnalyticsService analytics;
  late VehicleCubit vehicleCubit;
  late MockGetMaintenancesByVehicleIdUseCase maintenancesUseCase;
  late MockSoatCubit soatCubit;
  late MockTecnomecanicaCubit rtmCubit;

  setUp(() {
    getVehiclesUseCase = MockGetMyVehiclesUseCase();
    setMainUseCase = MockSetMainVehicleUseCase();
    updateVehicleUseCase = MockUpdateVehicleUseCase();
    analytics = MockAnalyticsService();
    when(() => analytics.logEvent(any())).thenAnswer((_) async {});
    when(() => analytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(
      () => analytics.setUserProperty(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => updateVehicleUseCase(any()),
    ).thenAnswer((_) async => const Right(_vehicle));

    vehicleCubit = VehicleCubit(
      getVehiclesUseCase,
      setMainUseCase,
      updateVehicleUseCase,
      analytics,
    );
    // Seed the cubit locally (equivalent to a first successful fetch) so it
    // is the single source of truth shared by both the garage and detail
    // screens, exactly like in the running app.
    vehicleCubit.addVehicleLocally(_vehicle);

    maintenancesUseCase = MockGetMaintenancesByVehicleIdUseCase();
    when(() => maintenancesUseCase.execute(_vehicleId)).thenAnswer(
      (_) async => Right(
        MaintenanceVehicleListResult(
          items: [_lastCompleted, _nextScheduled],
          summary: const MaintenanceListSummary(),
        ),
      ),
    );

    soatCubit = MockSoatCubit();
    rtmCubit = MockTecnomecanicaCubit();
    when(() => soatCubit.state).thenReturn(ResultState.data(data: _soatValid));
    when(() => rtmCubit.state).thenReturn(ResultState.data(data: _rtmValid));
    when(() => soatCubit.load(any())).thenAnswer((_) async {});
    when(() => rtmCubit.load(any())).thenAnswer((_) async {});

    final gi = GetIt.instance;
    if (gi.isRegistered<GetMaintenancesByVehicleIdUseCase>()) {
      gi.unregister<GetMaintenancesByVehicleIdUseCase>();
    }
    if (gi.isRegistered<VehicleMaintenancesCubit>()) {
      gi.unregister<VehicleMaintenancesCubit>();
    }
    if (gi.isRegistered<SoatCubit>()) gi.unregister<SoatCubit>();
    if (gi.isRegistered<TecnomecanicaCubit>()) {
      gi.unregister<TecnomecanicaCubit>();
    }
    gi.registerFactory<GetMaintenancesByVehicleIdUseCase>(
      () => maintenancesUseCase,
    );
    // Real VehicleMaintenancesCubit wired to the mocked use case, so
    // lastCompleted/nextScheduled derivation logic is exercised for real.
    gi.registerFactory<VehicleMaintenancesCubit>(
      () => VehicleMaintenancesCubit(maintenancesUseCase),
    );
    gi.registerFactory<SoatCubit>(() => soatCubit);
    gi.registerFactory<TecnomecanicaCubit>(() => rtmCubit);
  });

  tearDown(() {
    vehicleCubit.close();
    final gi = GetIt.instance;
    if (gi.isRegistered<GetMaintenancesByVehicleIdUseCase>()) {
      gi.unregister<GetMaintenancesByVehicleIdUseCase>();
    }
    if (gi.isRegistered<VehicleMaintenancesCubit>()) {
      gi.unregister<VehicleMaintenancesCubit>();
    }
    if (gi.isRegistered<SoatCubit>()) gi.unregister<SoatCubit>();
    if (gi.isRegistered<TecnomecanicaCubit>()) {
      gi.unregister<TecnomecanicaCubit>();
    }
  });

  testWidgets(
    'TC-nav-detail-1: tapping the vehicle card navigates to VehicleDetailPage '
    'and renders specs, last/next maintenance and SOAT/RTM cards',
    (tester) async {
      // Use a tall surface so the whole detail page (specs + maintenance +
      // SOAT/RTM cards) is laid out without needing to scroll a sliver list.
      await tester.binding.setSurfaceSize(const Size(800, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(vehicleCubit));
      await tester.pump();
      await tester.pump();

      // Starting point: on the garage, main vehicle card visible.
      expect(tester.takeException(), isNull);
      expect(find.text('Kawasaki Versys'), findsOneWidget);

      await tester.tap(find.text('Kawasaki Versys').first);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Navigated to the detail page.
      expect(find.byType(VehicleDetailPage), findsOneWidget);

      // Let the async maintenance fetch (VehicleMaintenancesCubit) resolve.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Specs card: brand/model/year present.
      expect(find.text('Kawasaki'), findsOneWidget);
      expect(find.text('Versys 650'), findsOneWidget);

      // SOAT / RTM document cards, both valid (section titles are rendered
      // uppercased via `.toUpperCase()` in VehicleDocumentCard).
      expect(find.text('DOCUMENTOS'), findsOneWidget);
      expect(find.text('TÉCNICO-MECÁNICA'), findsOneWidget);
      expect(find.text('Vigente'), findsNWidgets(2));

      // Last completed maintenance km ("7.500 km" — NumberFormat with dots).
      expect(find.textContaining('7.500 km'), findsOneWidget);
      // Next scheduled maintenance km.
      expect(find.textContaining('10.000 km'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-nav-detail-2: after updating mileage from the detail screen and '
    'going back, the garage main card reflects the new odometer value',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(vehicleCubit));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Kawasaki Versys').first);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VehicleDetailPage), findsOneWidget);

      // Simulate an odometer update coming from e.g. adding a maintenance,
      // via the SAME shared VehicleCubit both screens observe.
      await vehicleCubit.updateMileage(9500, vehicleId: _vehicleId);
      await tester.pump();
      await tester.pump();

      // Go back to the garage (VehicleDetailNav uses AppCircleIconButton.back
      // → Icons.arrow_back).
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(VehicleDetailPage), findsNothing);

      // Garage main card now shows the refreshed mileage.
      expect(find.textContaining('9,500 km'), findsOneWidget);
    },
  );
}
