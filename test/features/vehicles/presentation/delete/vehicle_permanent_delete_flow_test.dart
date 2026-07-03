// Tests de sección 3 (flujo de confirmación exitosa) y 7B (error de red)
// del QA checklist de eliminación permanente de vehículos archivados.
//
// Complementa vehicle_permanent_delete_dialog_test.dart que cubre
// TC-perm-A (diálogo aparece), TC-perm-B (anti doble-tap) y TC-perm-C (cancelar).
//
// Estos tests cubren:
//   Sección 3: tras confirmar, VehicleCubit.deleteLocally es llamado y aparece
//              el snackbar verde de éxito.
//   Sección 7B: error de red → snackbar rojo + vehículo NO se elimina del cubit.

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

// ─── Fixture ─────────────────────────────────────────────────────────────────

const _archivedVehicle = VehicleModel(
  id: 'v-del-flow',
  name: 'Yamaha MT-07',
  currentMileage: 5000,
  isArchived: true,
  isMainVehicle: false,
);

// ─── Helper ──────────────────────────────────────────────────────────────────

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
            builder: (ctx, _) => const Scaffold(body: Text('edit')),
          ),
          GoRoute(
            path: 'maintenances/create',
            name: AppRoutes.createMaintenance,
            builder: (ctx, _) => const Scaffold(body: Text('maintenance')),
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
    builder: (context, child) =>
        BlocProvider<VehicleCubit>.value(value: vehicleCubit, child: child!),
  );
}

// ─── Setup compartido ─────────────────────────────────────────────────────────

late MockVehicleCubit vehicleCubit;
late MockPermanentlyDeleteVehicleUseCase deleteUseCase;
late MockArchiveVehicleUseCase archiveUseCase;
late MockUnarchiveVehicleUseCase unarchiveUseCase;
late MockAnalyticsService analytics;

void _setUp() {
  vehicleCubit = MockVehicleCubit();
  deleteUseCase = MockPermanentlyDeleteVehicleUseCase();
  archiveUseCase = MockArchiveVehicleUseCase();
  unarchiveUseCase = MockUnarchiveVehicleUseCase();
  analytics = MockAnalyticsService();

  when(
    () => vehicleCubit.state,
  ).thenReturn(const ResultState<List<VehicleModel>>.initial());
  when(() => vehicleCubit.deleteLocally(any())).thenReturn(null);
  when(() => analytics.logEvent(any())).thenAnswer((_) async {});
  when(() => analytics.logEvent(any(), any())).thenAnswer((_) async {});

  final gi = GetIt.instance;
  if (gi.isRegistered<VehicleActionCubit>())
    gi.unregister<VehicleActionCubit>();
  gi.registerFactory<VehicleActionCubit>(
    () => VehicleActionCubit(
      deleteUseCase,
      archiveUseCase,
      unarchiveUseCase,
      vehicleCubit,
      analytics,
    ),
  );
}

void _tearDown() {
  final gi = GetIt.instance;
  if (gi.isRegistered<VehicleActionCubit>())
    gi.unregister<VehicleActionCubit>();
}

/// Abre el bottom sheet del vehículo archivado, toca "Eliminar permanentemente"
/// y confirma en el diálogo destructivo.
Future<void> _openAndConfirmDelete(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Eliminar permanentemente'));
  await tester.pumpAndSettle();

  expect(find.text('Eliminar vehículo permanentemente'), findsOneWidget);

  // Tap el botón de confirmación (el último "Eliminar permanentemente" visible)
  await tester.tap(find.text('Eliminar permanentemente').last);
  await tester.pumpAndSettle();
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUp(_setUp);
  tearDown(_tearDown);

  // ── TC-3-2: tras confirmar, VehicleCubit.deleteLocally es llamado ─────────

  testWidgets(
    'TC-3-2: confirming delete calls VehicleCubit.deleteLocally with correct id',
    (tester) async {
      when(
        () => deleteUseCase(_archivedVehicle.id!),
      ).thenAnswer((_) async => const Right(null));

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

      await _openAndConfirmDelete(tester);

      verify(() => vehicleCubit.deleteLocally(_archivedVehicle.id!)).called(1);
    },
  );

  // ── TC-3-4: snackbar verde de éxito aparece tras confirmar ────────────────

  testWidgets('TC-3-4: confirming delete shows success snackbar (green)', (
    tester,
  ) async {
    when(
      () => deleteUseCase(_archivedVehicle.id!),
    ).thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(
      _wrapWithRouter(
        vehicleCubit: vehicleCubit,
        homeBuilder: (ctx) => ElevatedButton(
          onPressed: () => GarageOptionsBottomSheet.show(ctx, _archivedVehicle),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openAndConfirmDelete(tester);
    await tester.pump(); // deja que el snackbar aparezca

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Vehículo eliminado permanentemente'),
      findsOneWidget,
      reason: 'El snackbar de éxito debe mostrar el mensaje correcto',
    );
  });

  // ── TC-3-1: el diálogo se cierra tras confirmar ───────────────────────────

  testWidgets('TC-3-1: confirmation dialog closes after confirming delete', (
    tester,
  ) async {
    when(
      () => deleteUseCase(_archivedVehicle.id!),
    ).thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(
      _wrapWithRouter(
        vehicleCubit: vehicleCubit,
        homeBuilder: (ctx) => ElevatedButton(
          onPressed: () => GarageOptionsBottomSheet.show(ctx, _archivedVehicle),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openAndConfirmDelete(tester);

    expect(
      find.text('Eliminar vehículo permanentemente'),
      findsNothing,
      reason: 'El diálogo de confirmación debe cerrarse tras confirmar',
    );
  });

  // ── TC-7B: error de red → snackbar rojo, deleteLocally NO llamado ─────────

  testWidgets(
    'TC-7B: network error shows error snackbar and does NOT call deleteLocally',
    (tester) async {
      when(() => deleteUseCase(_archivedVehicle.id!)).thenAnswer(
        (_) async => const Left(
          DomainException(message: 'Error de conexión. Intenta de nuevo.'),
        ),
      );

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

      await _openAndConfirmDelete(tester);
      await tester.pump();

      // Snackbar de error aparece
      expect(find.byType(SnackBar), findsOneWidget);

      // El success message NO debe aparecer
      expect(
        find.text('Vehículo eliminado permanentemente'),
        findsNothing,
        reason: 'Con error de red NO debe aparecer snackbar de éxito',
      );

      // deleteLocally NO fue llamado (vehículo permanece en lista)
      verifyNever(() => vehicleCubit.deleteLocally(any()));
    },
  );

  // ── TC-7B-2: verificación cubit — use case con error no emite deleteSuccess

  test(
    'TC-7B-2: use case Left → cubit emits error state, not permanentDeleteSuccess',
    () async {
      when(() => deleteUseCase(_archivedVehicle.id!)).thenAnswer(
        (_) async => const Left(DomainException(message: 'Sin conexión')),
      );

      final cubit = VehicleActionCubit(
        deleteUseCase,
        archiveUseCase,
        unarchiveUseCase,
        vehicleCubit,
        analytics,
      );

      await cubit.permanentlyDeleteVehicle(_archivedVehicle.id!);

      final state = cubit.state;
      expect(state, isA<VehicleActionState>());
      // Debe ser un estado de error, no de éxito
      expect(
        state.maybeMap(
          permanentDeleteSuccess: (_) => true,
          orElse: () => false,
        ),
        isFalse,
        reason:
            'Con Left del use case el cubit NO debe emitir permanentDeleteSuccess',
      );
      expect(
        state.maybeMap(error: (_) => true, orElse: () => false),
        isTrue,
        reason: 'Con Left del use case el cubit debe emitir error state',
      );

      await cubit.close();
    },
  );
}
