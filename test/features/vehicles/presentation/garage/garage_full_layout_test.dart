// Widget test for QA checklist row 7.1 (vehicles_QA_CHECKLIST.md):
//
//   "Abre el garage con al menos 1 vehículo principal, 1 'otro vehículo'
//    activo y 1 archivado" → se ve el header "Mi Garaje", la tarjeta
//    principal destacada, la lista de "Otros vehículos" y la sección
//    colapsable "Archivados" con el conteo correcto.
//
// Previously, `garage_archived_section_test.dart` only rendered the
// archived section in isolation. This test renders the FULL garage
// (`GaragePageView`) with one main vehicle, one other active vehicle and
// one archived vehicle simultaneously, and asserts every region of the
// layout is present at once.

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
import 'package:rideglory/features/maintenance/domain/model/maintenance_vehicle_list_result.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/archive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/permanently_delete_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/unarchive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/garage_page_view.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_archived_header.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_main_vehicle_card.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockVehicleCubit extends MockCubit<ResultState<List<VehicleModel>>>
    implements VehicleCubit {}

class MockGetMaintenancesByVehicleIdUseCase extends Mock
    implements GetMaintenancesByVehicleIdUseCase {}

class MockPermanentlyDeleteVehicleUseCase extends Mock
    implements PermanentlyDeleteVehicleUseCase {}

class MockArchiveVehicleUseCase extends Mock implements ArchiveVehicleUseCase {}

class MockUnarchiveVehicleUseCase extends Mock
    implements UnarchiveVehicleUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _mainVehicle = VehicleModel(
  id: 'v-main',
  name: 'Honda CB500X',
  brand: 'Honda',
  model: 'CB500X',
  year: 2022,
  currentMileage: 12000,
  isMainVehicle: true,
);

const _otherVehicle = VehicleModel(
  id: 'v-other',
  name: 'Yamaha MT-07',
  brand: 'Yamaha',
  model: 'MT-07',
  currentMileage: 5000,
  isMainVehicle: false,
);

const _archivedVehicle = VehicleModel(
  id: 'v-arch',
  name: 'Suzuki Archivada',
  currentMileage: 3000,
  isArchived: true,
);

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap(MockVehicleCubit vehicleCubit) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: AppRoutes.garage,
        builder: (_, _) => BlocProvider<VehicleCubit>.value(
          value: vehicleCubit,
          child: GaragePageView(loadVehicles: () async {}),
        ),
      ),
      GoRoute(
        name: AppRoutes.vehicleDetail,
        path: 'vehicles/detail',
        builder: (_, _) => const Scaffold(body: SizedBox()),
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
  );
}

void main() {
  late MockVehicleCubit vehicleCubit;
  late MockGetMaintenancesByVehicleIdUseCase maintenancesUseCase;

  setUp(() {
    vehicleCubit = MockVehicleCubit();
    maintenancesUseCase = MockGetMaintenancesByVehicleIdUseCase();

    when(() => vehicleCubit.state).thenReturn(
      const ResultState<List<VehicleModel>>.data(
        data: [_mainVehicle, _otherVehicle, _archivedVehicle],
      ),
    );

    when(() => maintenancesUseCase.execute(any())).thenAnswer(
      (_) async => const Right(
        MaintenanceVehicleListResult(
          items: [],
          summary: MaintenanceListSummary(),
        ),
      ),
    );

    final getIt = GetIt.instance;
    if (getIt.isRegistered<GetMaintenancesByVehicleIdUseCase>()) {
      getIt.unregister<GetMaintenancesByVehicleIdUseCase>();
    }
    getIt.registerFactory<GetMaintenancesByVehicleIdUseCase>(
      () => maintenancesUseCase,
    );

    if (getIt.isRegistered<VehicleActionCubit>()) {
      getIt.unregister<VehicleActionCubit>();
    }
    final mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    getIt.registerFactory<VehicleActionCubit>(
      () => VehicleActionCubit(
        MockPermanentlyDeleteVehicleUseCase(),
        MockArchiveVehicleUseCase(),
        MockUnarchiveVehicleUseCase(),
        vehicleCubit,
        mockAnalytics,
      ),
    );
  });

  tearDown(() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<GetMaintenancesByVehicleIdUseCase>()) {
      getIt.unregister<GetMaintenancesByVehicleIdUseCase>();
    }
    if (getIt.isRegistered<VehicleActionCubit>()) {
      getIt.unregister<VehicleActionCubit>();
    }
  });

  testWidgets(
    'TC-garage-1: full garage renders header, main card, other vehicles '
    'and archived section (with count) all together',
    (tester) async {
      await tester.pumpWidget(_wrap(vehicleCubit));
      await tester.pump();
      await tester.pump();

      // Header "Mi Garaje"
      expect(find.text('Mi Garaje'), findsOneWidget);

      // Main vehicle card destacada
      expect(find.byType(GarageMainVehicleCard), findsOneWidget);
      expect(find.text('Honda CB500X'), findsOneWidget);

      // "Otros vehículos" section
      expect(find.text('OTROS VEHÍCULOS'), findsOneWidget);
      expect(find.text('Yamaha MT-07'), findsOneWidget);

      // Scroll down to reveal the "Archivados" section (below the fold).
      await tester.scrollUntilVisible(
        find.text('ARCHIVADOS'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      // "Archivados" section with correct count, collapsed by default
      expect(find.text('ARCHIVADOS'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GarageArchivedHeader),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(find.text('Suzuki Archivada'), findsNothing);
    },
  );
}
