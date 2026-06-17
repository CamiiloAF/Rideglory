import 'dart:async';

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
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/archive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/permanently_delete_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/unarchive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockVehicleCubit extends MockCubit<ResultState<List<VehicleModel>>>
    implements VehicleCubit {}

class MockPermanentlyDeleteVehicleUseCase extends Mock
    implements PermanentlyDeleteVehicleUseCase {}

class MockArchiveVehicleUseCase extends Mock implements ArchiveVehicleUseCase {}

class MockUnarchiveVehicleUseCase extends Mock
    implements UnarchiveVehicleUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _archivedVehicle = VehicleModel(
  id: 'v-arch',
  name: 'Yamaha MT-07',
  currentMileage: 5000,
  isArchived: true,
  isMainVehicle: false,
);

// ─── Test helper ─────────────────────────────────────────────────────────────

Widget _wrapWithRouter({
  required MockVehicleCubit vehicleCubit,
  required Widget Function(BuildContext) homeBuilder,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (ctx, _) => Scaffold(body: homeBuilder(ctx)),
        routes: [
          GoRoute(
            path: 'vehicles/edit',
            name: AppRoutes.editVehicle,
            builder: (ctx, state) =>
                const Scaffold(body: Text('edit-vehicle')),
          ),
          GoRoute(
            path: 'maintenances/create',
            name: AppRoutes.createMaintenance,
            builder: (ctx, state) =>
                const Scaffold(body: Text('create-maintenance')),
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    routerConfig: router,
    builder: (context, child) => BlocProvider<VehicleCubit>.value(
      value: vehicleCubit,
      child: child!,
    ),
  );
}

void main() {
  late MockVehicleCubit vehicleCubit;
  late MockPermanentlyDeleteVehicleUseCase deleteUseCase;
  late MockArchiveVehicleUseCase archiveUseCase;
  late MockUnarchiveVehicleUseCase unarchiveUseCase;
  late MockAnalyticsService analytics;

  setUp(() {
    vehicleCubit = MockVehicleCubit();
    deleteUseCase = MockPermanentlyDeleteVehicleUseCase();
    archiveUseCase = MockArchiveVehicleUseCase();
    unarchiveUseCase = MockUnarchiveVehicleUseCase();
    analytics = MockAnalyticsService();

    when(() => vehicleCubit.state).thenReturn(
      const ResultState<List<VehicleModel>>.initial(),
    );
    when(() => vehicleCubit.fetchMyVehicles()).thenAnswer((_) async {});
    when(() => analytics.logEvent(any())).thenAnswer((_) async {});
    when(() => analytics.logEvent(any(), any())).thenAnswer((_) async {});

    final getIt = GetIt.instance;
    if (getIt.isRegistered<VehicleActionCubit>()) {
      getIt.unregister<VehicleActionCubit>();
    }
    getIt.registerFactory<VehicleActionCubit>(
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
    final getIt = GetIt.instance;
    if (getIt.isRegistered<VehicleActionCubit>()) {
      getIt.unregister<VehicleActionCubit>();
    }
  });

  // ── Test A: diálogo destructivo aparece con danger style ──────────────────

  testWidgets(
    'TC-perm-A: tapping "Eliminar permanentemente" shows ConfirmationDialog with vehicle name',
    (tester) async {
      // The delete use case will never be called in this test — just confirm dialog appears
      await tester.pumpWidget(
        _wrapWithRouter(
          vehicleCubit: vehicleCubit,
          homeBuilder: (ctx) => ElevatedButton(
            onPressed: () =>
                GarageOptionsBottomSheet.show(ctx, _archivedVehicle),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the bottom sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The archived vehicle section should show "Eliminar permanentemente"
      expect(find.text('Eliminar permanentemente'), findsOneWidget);

      // Tap the permanent delete tile
      await tester.tap(find.text('Eliminar permanentemente'));
      await tester.pumpAndSettle();

      // ConfirmationDialog should appear with title and vehicle name in content
      expect(
        find.text('Eliminar vehículo permanentemente'),
        findsOneWidget,
      );
      expect(
        find.textContaining(_archivedVehicle.name),
        findsAtLeastNWidgets(1),
      );

      // Verify use case was NOT called yet (dialog is still open)
      verifyNever(() => deleteUseCase(any()));
    },
  );

  // ── Test B: guard anti doble-tap ──────────────────────────────────────────

  test(
    'TC-perm-B: guard anti doble-tap — use case called exactly once on concurrent calls',
    () async {
      // Use a Completer so the first call never completes during the test,
      // making the cubit stay in loading state for the second call.
      final completer = Completer<Either<DomainException, void>>();
      when(
        () => deleteUseCase(_archivedVehicle.id!),
      ).thenAnswer((_) => completer.future);

      final cubit = VehicleActionCubit(
        deleteUseCase,
        archiveUseCase,
        unarchiveUseCase,
        vehicleCubit,
        analytics,
      );

      // Fire two concurrent calls without awaiting the first
      unawaited(cubit.permanentlyDeleteVehicle(_archivedVehicle.id!));
      unawaited(cubit.permanentlyDeleteVehicle(_archivedVehicle.id!));

      // Allow microtasks to run
      await Future<void>.delayed(Duration.zero);

      // Complete the deferred future
      completer.complete(const Right(null));
      await Future<void>.delayed(Duration.zero);

      // The use case should have been called exactly once
      verify(() => deleteUseCase(_archivedVehicle.id!)).called(1);

      await cubit.close();
    },
  );

  // ── Test C: cancelar NO dispara permanentlyDeleteVehicle ─────────────────

  testWidgets(
    'TC-perm-C: cancelling the permanent delete dialog does NOT call the use case',
    (tester) async {
      await tester.pumpWidget(
        _wrapWithRouter(
          vehicleCubit: vehicleCubit,
          homeBuilder: (ctx) => ElevatedButton(
            onPressed: () =>
                GarageOptionsBottomSheet.show(ctx, _archivedVehicle),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the bottom sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap the permanent delete tile to open the confirmation dialog
      await tester.tap(find.text('Eliminar permanentemente'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Eliminar vehículo permanentemente'), findsOneWidget);

      // Tap the cancel button
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Use case must NOT have been called
      verifyNever(() => deleteUseCase(any()));
    },
  );
}
