import 'package:dartz/dartz.dart' show Right;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/archive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/permanently_delete_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/unarchive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockVehicleCubit extends MockCubit<ResultState<List<VehicleModel>>>
    implements VehicleCubit {}

class MockArchiveVehicleUseCase extends Mock implements ArchiveVehicleUseCase {}

class MockUnarchiveVehicleUseCase extends Mock
    implements UnarchiveVehicleUseCase {}

class MockPermanentlyDeleteVehicleUseCase extends Mock
    implements PermanentlyDeleteVehicleUseCase {}

class MockGetMyVehiclesUseCase extends Mock implements GetMyVehiclesUseCase {}

class MockSetMainVehicleUseCase extends Mock implements SetMainVehicleUseCase {}

class MockUpdateVehicleUseCase extends Mock implements UpdateVehicleUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// ─── Fallback values ─────────────────────────────────────────────────────────

class _FakeVehicleModel extends Fake implements VehicleModel {}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _activeVehicle = VehicleModel(
  id: 'v-active',
  name: 'Honda CB500',
  currentMileage: 10000,
  isArchived: false,
  isMainVehicle: false,
);

const _archivedVehicle = VehicleModel(
  id: 'v-archived',
  name: 'Yamaha MT-07',
  currentMileage: 5000,
  isArchived: true,
  isMainVehicle: false,
);

// ─── Test helper ─────────────────────────────────────────────────────────────

/// Wraps [child] in a GoRouter with stub routes so [context.pop()] and
/// [pushNamed] from GarageOptionsBottomSheet do not throw "no GoRouter".
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
            builder: (ctx, state) => const Scaffold(body: Text('edit-vehicle')),
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
    builder: (context, child) =>
        BlocProvider<VehicleCubit>.value(value: vehicleCubit, child: child!),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeVehicleModel());
  });

  late MockVehicleCubit vehicleCubit;
  late MockArchiveVehicleUseCase archiveUseCase;
  late MockUnarchiveVehicleUseCase unarchiveUseCase;
  late MockPermanentlyDeleteVehicleUseCase deleteUseCase;
  late MockAnalyticsService analytics;

  setUp(() {
    vehicleCubit = MockVehicleCubit();
    archiveUseCase = MockArchiveVehicleUseCase();
    unarchiveUseCase = MockUnarchiveVehicleUseCase();
    deleteUseCase = MockPermanentlyDeleteVehicleUseCase();
    analytics = MockAnalyticsService();

    when(
      () => vehicleCubit.state,
    ).thenReturn(const ResultState<List<VehicleModel>>.initial());
    when(() => analytics.logEvent(any())).thenAnswer((_) async {});
    when(() => analytics.logEvent(any(), any())).thenAnswer((_) async {});

    // Register factory in GetIt so bottom sheet can call getIt<VehicleActionCubit>()
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

  // ── TC-bs-1: confirmar archivado dispara archiveVehicle ───────────────────

  testWidgets(
    'TC-bs-1: confirming archive dialog calls archiveVehicle on VehicleActionCubit',
    (tester) async {
      // Stub archive use case to succeed so the cubit emits archiveSuccess
      when(() => archiveUseCase(_activeVehicle)).thenAnswer(
        (_) async => const Right(
          VehicleModel(
            id: 'v-active',
            name: 'Honda CB500',
            currentMileage: 10000,
            isArchived: true,
            isMainVehicle: false,
          ),
        ),
      );
      when(() => vehicleCubit.archiveLocally(any())).thenReturn(null);

      await tester.pumpWidget(
        _wrapWithRouter(
          vehicleCubit: vehicleCubit,
          homeBuilder: (ctx) => ElevatedButton(
            onPressed: () => GarageOptionsBottomSheet.show(ctx, _activeVehicle),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the bottom sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap "Archivar" option in the bottom sheet (the one with archive icon)
      final archiveTile = find.ancestor(
        of: find.byIcon(LucideIcons.archive),
        matching: find.byType(GestureDetector),
      );
      expect(archiveTile, findsWidgets);
      await tester.tap(archiveTile.first);
      await tester.pumpAndSettle();

      // ConfirmationDialog should appear — tap the confirm button (labeled "Archivar")
      // The modal shows a confirm button labeled vehicle_archiveConfirmButton = "Archivar"
      // There should now be a modal visible with "Archivar vehículo" title
      expect(find.text('Archivar vehículo'), findsOneWidget);

      // Tap the confirm button (last because the bottom sheet option also says "Archivar")
      await tester.tap(find.text('Archivar').last);
      await tester.pumpAndSettle();

      // Verify archiveVehicle was called via the use case
      verify(() => archiveUseCase(_activeVehicle)).called(1);

      // Fila 4.1: tras archiveSuccess, la app muestra el snackbar
      // "Vehículo archivado" (parentContext, no el sheetContext, que ya se
      // cerró) y sincroniza el cubit local.
      expect(find.text('Vehículo archivado'), findsOneWidget);
      // NOTA: archiveLocally se invoca 2 veces por diseño actual — una desde
      // VehicleActionCubit.archiveVehicle (línea 55) y otra desde el listener
      // de este bottom sheet (línea 58 de garage_options_bottom_sheet.dart).
      // Es una duplicación pre-existente (idempotente, no afecta el resultado
      // visible), no introducida por este test.
      verify(() => vehicleCubit.archiveLocally('v-active')).called(2);
    },
  );

  // ── TC-bs-2: cancelar NO dispara archiveVehicle ───────────────────────────

  testWidgets(
    'TC-bs-2: cancelling archive dialog does NOT call archiveVehicle',
    (tester) async {
      await tester.pumpWidget(
        _wrapWithRouter(
          vehicleCubit: vehicleCubit,
          homeBuilder: (ctx) => ElevatedButton(
            onPressed: () => GarageOptionsBottomSheet.show(ctx, _activeVehicle),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the bottom sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap "Archivar" option in the bottom sheet
      final archiveTile = find.ancestor(
        of: find.byIcon(LucideIcons.archive),
        matching: find.byType(GestureDetector),
      );
      expect(archiveTile, findsWidgets);
      await tester.tap(archiveTile.first);
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Archivar vehículo'), findsOneWidget);

      // Tap the cancel button
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Verify archiveVehicle was NOT called
      verifyNever(() => archiveUseCase(any()));
    },
  );

  // ── Fila 5.1: desarchivar muestra snackbar "Vehículo restaurado" ─────────

  testWidgets(
    'Fila 5.1: tapping "Restaurar" on an archived vehicle shows the '
    '"Vehículo restaurado" snackbar and syncs VehicleCubit.unarchiveLocally',
    (tester) async {
      when(() => unarchiveUseCase(_archivedVehicle)).thenAnswer(
        (_) async => const Right(
          VehicleModel(
            id: 'v-archived',
            name: 'Yamaha MT-07',
            currentMileage: 5000,
            isArchived: false,
            isMainVehicle: false,
          ),
        ),
      );
      when(() => vehicleCubit.unarchiveLocally(any())).thenReturn(null);

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

      // Open the bottom sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap "Restaurar" option (archiveRestore icon) — no confirmation dialog
      final unarchiveTile = find.ancestor(
        of: find.byIcon(LucideIcons.archiveRestore),
        matching: find.byType(GestureDetector),
      );
      expect(unarchiveTile, findsWidgets);
      await tester.tap(unarchiveTile.first);
      await tester.pumpAndSettle();

      verify(() => unarchiveUseCase(_archivedVehicle)).called(1);
      // NOTA: mismo patrón que archiveLocally — invocado 2 veces (una desde
      // VehicleActionCubit.unarchiveVehicle, otra desde el listener del
      // bottom sheet). Ver comentario en TC-bs-1.
      verify(() => vehicleCubit.unarchiveLocally('v-archived')).called(2);
      expect(find.text('Vehículo restaurado'), findsOneWidget);
    },
  );
}
