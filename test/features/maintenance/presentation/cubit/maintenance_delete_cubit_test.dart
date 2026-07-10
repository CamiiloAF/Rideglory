// Tests de MaintenanceDeleteCubit: máquina de estados + analytics.
// Verifica:
//   deleteMaintenance exitoso emite loading -> success(deletedId) con el id correcto.
//   deleteMaintenance fallido emite loading -> error(message) legible.
//   maintenance_deleted se emite al borrar exitosamente (con maintenanceType correcto).
//   maintenance_deleted NO se emite si el use case falla.

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/delete_maintenance_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart';

class MockDeleteMaintenanceUseCase extends Mock
    implements DeleteMaintenanceUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeMaintenanceModel extends Fake implements MaintenanceModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMaintenanceModel());
  });

  late MockDeleteMaintenanceUseCase mockDelete;
  late MockAnalyticsService mockAnalytics;
  late MaintenanceDeleteCubit cubit;

  final maintenanceToDelete = MaintenanceModel(
    id: 'maint-99',
    vehicleId: 'v1',
    type: MaintenanceType.oilChange,
    mode: MaintenanceMode.completed,
    serviceDate: DateTime(2026, 6, 1),
  );

  setUp(() {
    mockDelete = MockDeleteMaintenanceUseCase();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    cubit = MaintenanceDeleteCubit(mockDelete, mockAnalytics);
  });

  tearDown(() => cubit.close());

  group('MaintenanceDeleteCubit — máquina de estados', () {
    // TC-maint-del-s1: borrado exitoso emite loading -> success(deletedId)
    blocTest<MaintenanceDeleteCubit, MaintenanceDeleteState>(
      'TC-maint-del-s1: deleteMaintenance exitoso emite '
      'loading y luego success con el deletedId correcto',
      build: () {
        when(
          () => mockDelete(any()),
        ).thenAnswer((_) async => const Right(Nothing()));
        return cubit;
      },
      act: (cubit) => cubit.deleteMaintenance(maintenanceToDelete),
      expect: () => [
        const MaintenanceDeleteState.loading(),
        const MaintenanceDeleteState.success(deletedId: 'maint-99'),
      ],
    );

    // TC-maint-del-s2: borrado fallido emite loading -> error(message)
    blocTest<MaintenanceDeleteCubit, MaintenanceDeleteState>(
      'TC-maint-del-s2: deleteMaintenance fallido emite '
      'loading y luego error con un mensaje legible',
      build: () {
        when(() => mockDelete(any())).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'No se pudo borrar')),
        );
        return cubit;
      },
      act: (cubit) => cubit.deleteMaintenance(maintenanceToDelete),
      expect: () => [
        const MaintenanceDeleteState.loading(),
        const MaintenanceDeleteState.error(message: 'No se pudo borrar'),
      ],
    );

    // TC-maint-del-s3: sin id emite error directamente, sin loading previo
    blocTest<MaintenanceDeleteCubit, MaintenanceDeleteState>(
      'TC-maint-del-s3: maintenance sin id emite error sin pasar por loading',
      build: () => cubit,
      act: (cubit) => cubit.deleteMaintenance(
        MaintenanceModel(
          vehicleId: 'v1',
          type: MaintenanceType.oilChange,
          mode: MaintenanceMode.completed,
          serviceDate: DateTime(2026, 6, 1),
        ),
      ),
      expect: () => [
        const MaintenanceDeleteState.error(message: 'Missing maintenance id'),
      ],
    );
  });

  group('MaintenanceDeleteCubit — analytics Fase 9', () {
    // TC-maint-del-a1: maintenance_deleted se emite al borrar exitosamente
    test(
      'TC-maint-del-a1: deleteMaintenance exitoso → maintenance_deleted emitido',
      () async {
        when(
          () => mockDelete(any()),
        ).thenAnswer((_) async => const Right(Nothing()));

        await cubit.deleteMaintenance(maintenanceToDelete);

        verify(
          () =>
              mockAnalytics.logEvent(AnalyticsEvents.maintenanceDeleted, any()),
        ).called(1);
      },
    );

    // TC-maint-del-a2: maintenance_deleted contiene maintenanceType correcto
    test('TC-maint-del-a2: maintenance_deleted contiene '
        'maintenance_type = oilChange', () async {
      when(
        () => mockDelete(any()),
      ).thenAnswer((_) async => const Right(Nothing()));

      await cubit.deleteMaintenance(maintenanceToDelete);

      final captured = verify(
        () => mockAnalytics.logEvent(
          AnalyticsEvents.maintenanceDeleted,
          captureAny(),
        ),
      ).captured;

      final params = captured.single as Map<String, Object>;
      expect(
        params[AnalyticsParams.maintenanceType],
        MaintenanceType.oilChange.name,
      );
    });

    // TC-maint-del-a3: maintenance_deleted NO se emite si el use case falla
    test(
      'TC-maint-del-a3: deleteMaintenance con error → maintenance_deleted NO emitido',
      () async {
        when(() => mockDelete(any())).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'No se pudo borrar')),
        );

        await cubit.deleteMaintenance(maintenanceToDelete);

        verifyNever(
          () =>
              mockAnalytics.logEvent(AnalyticsEvents.maintenanceDeleted, any()),
        );
      },
    );

    // TC-maint-del-a4: sin id → emite error, NO llama analytics
    test(
      'TC-maint-del-a4: maintenance sin id → emite error, maintenance_deleted NO emitido',
      () async {
        final maintenanceWithoutId = MaintenanceModel(
          vehicleId: 'v1',
          type: MaintenanceType.oilChange,
          mode: MaintenanceMode.completed,
          serviceDate: DateTime(2026, 6, 1),
        );

        await cubit.deleteMaintenance(maintenanceWithoutId);

        verifyNever(
          () =>
              mockAnalytics.logEvent(AnalyticsEvents.maintenanceDeleted, any()),
        );
        verifyNever(() => mockDelete(any()));
      },
    );
  });
}
