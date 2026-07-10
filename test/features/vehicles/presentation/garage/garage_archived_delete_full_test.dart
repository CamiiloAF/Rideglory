// Widget test for QA checklist row 6.3 (vehicles_QA_CHECKLIST.md):
//
//   "Confirma la eliminación" → ... el vehículo desaparece de toda la UI
//   (incluida la sección 'Archivados').
//
// Previously, `vehicle_permanent_delete_flow_test.dart` only verified that
// `VehicleCubit.deleteLocally` was *called* with a mocked cubit — it never
// rendered the garage's "Archivados" section to confirm the vehicle
// actually disappears from it. This test uses a REAL `VehicleCubit` seeded
// with one active + one archived vehicle, renders the full
// `GarageVehiclesContent`, deletes the archived vehicle permanently through
// the real UI flow (bottom sheet → confirm dialog), and asserts it is gone
// from the "Archivados" section (which collapses to nothing once empty).

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_vehicle_list_result.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/archive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/permanently_delete_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/unarchive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart';
import 'package:rideglory/l10n/app_localizations.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockGetMyVehiclesUseCase extends Mock implements GetMyVehiclesUseCase {}

class MockSetMainVehicleUseCase extends Mock implements SetMainVehicleUseCase {}

class MockUpdateVehicleUseCase extends Mock implements UpdateVehicleUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockGetMaintenancesByVehicleIdUseCase extends Mock
    implements GetMaintenancesByVehicleIdUseCase {}

class MockPermanentlyDeleteVehicleUseCase extends Mock
    implements PermanentlyDeleteVehicleUseCase {}

class MockArchiveVehicleUseCase extends Mock implements ArchiveVehicleUseCase {}

class MockUnarchiveVehicleUseCase extends Mock
    implements UnarchiveVehicleUseCase {}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _mainVehicle = VehicleModel(
  id: 'v-main',
  name: 'Honda CB500X',
  currentMileage: 12000,
  isMainVehicle: true,
);

const _archivedVehicle = VehicleModel(
  id: 'v-arch',
  name: 'Kawasaki Ninja Archivada',
  currentMileage: 3000,
  isArchived: true,
);

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap(VehicleCubit vehicleCubit) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => BlocProvider<VehicleCubit>.value(
          value: vehicleCubit,
          child: GarageVehiclesContent(
            loadVehicles: () async {},
            onSelectVehicle: (_) {},
            onMaintenanceCreated: (_) {},
            onMaintenanceRefreshRequested: (_) {},
          ),
        ),
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
  setUpAll(() {
    registerFallbackValue(_archivedVehicle);
  });

  late VehicleCubit vehicleCubit;
  late MockPermanentlyDeleteVehicleUseCase deleteUseCase;

  setUp(() async {
    final getVehiclesUseCase = MockGetMyVehiclesUseCase();
    final setMainUseCase = MockSetMainVehicleUseCase();
    final updateVehicleUseCase = MockUpdateVehicleUseCase();
    final analytics = MockAnalyticsService();
    when(() => analytics.logEvent(any())).thenAnswer((_) async {});
    when(() => analytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(
      () => analytics.setUserProperty(any(), any()),
    ).thenAnswer((_) async {});

    vehicleCubit = VehicleCubit(
      getVehiclesUseCase,
      setMainUseCase,
      updateVehicleUseCase,
      analytics,
    );
    vehicleCubit.addVehicleLocally(_mainVehicle);
    vehicleCubit.addVehicleLocally(_archivedVehicle);

    final maintenancesUseCase = MockGetMaintenancesByVehicleIdUseCase();
    when(() => maintenancesUseCase.execute(any())).thenAnswer(
      (_) async => const Right(
        MaintenanceVehicleListResult(
          items: [],
          summary: MaintenanceListSummary(),
        ),
      ),
    );

    deleteUseCase = MockPermanentlyDeleteVehicleUseCase();
    when(
      () => deleteUseCase(_archivedVehicle.id!),
    ).thenAnswer((_) async => const Right(null));
    final archiveUseCase = MockArchiveVehicleUseCase();
    final unarchiveUseCase = MockUnarchiveVehicleUseCase();

    final gi = GetIt.instance;
    if (gi.isRegistered<GetMaintenancesByVehicleIdUseCase>()) {
      gi.unregister<GetMaintenancesByVehicleIdUseCase>();
    }
    if (gi.isRegistered<VehicleActionCubit>()) {
      gi.unregister<VehicleActionCubit>();
    }
    gi.registerFactory<GetMaintenancesByVehicleIdUseCase>(
      () => maintenancesUseCase,
    );
    gi.registerFactory<VehicleActionCubit>(
      () => VehicleActionCubit(
        deleteUseCase,
        archiveUseCase,
        unarchiveUseCase,
        vehicleCubit,
        analytics,
      ),
    );
  });

  tearDown(() {
    vehicleCubit.close();
    final gi = GetIt.instance;
    if (gi.isRegistered<GetMaintenancesByVehicleIdUseCase>()) {
      gi.unregister<GetMaintenancesByVehicleIdUseCase>();
    }
    if (gi.isRegistered<VehicleActionCubit>()) {
      gi.unregister<VehicleActionCubit>();
    }
  });

  testWidgets(
    'TC-arch-delete-1: permanently deleting an archived vehicle removes it '
    'from the "Archivados" section of the FULL garage (not just the cubit)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(vehicleCubit));
      await tester.pump();
      await tester.pump();

      // Expand the "Archivados" section (collapsed by default).
      await tester.tap(find.text('ARCHIVADOS'));
      await tester.pump();

      expect(find.text('Kawasaki Ninja Archivada'), findsOneWidget);

      // Open the options bottom sheet for the archived vehicle (more_vert
      // icon — distinct from the main card's more_horiz icon).
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar permanentemente'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar vehículo permanentemente'), findsOneWidget);

      // Confirm in the destructive ConfirmationDialog.
      await tester.tap(find.text('Eliminar permanentemente').last);
      await tester.pumpAndSettle();

      // The vehicle must be gone from the "Archivados" section — which
      // collapses entirely (SizedBox.shrink) since it becomes empty.
      expect(find.text('Kawasaki Ninja Archivada'), findsNothing);
      expect(find.text('ARCHIVADOS'), findsNothing);

      // The active vehicle is untouched.
      expect(find.text('Honda CB500X'), findsOneWidget);

      verify(() => deleteUseCase(_archivedVehicle.id!)).called(1);
    },
  );
}
