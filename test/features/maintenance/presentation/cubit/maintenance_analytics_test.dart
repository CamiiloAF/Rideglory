// Analytics tests — Fase 9: Mantenimiento
// Verifica:
//   maintenance_added al guardar mantenimiento nuevo (add path).
//   maintenance_added incluye maintenance_type y maintenance_mode (no PII).
//   G2: sin kilometraje exacto, notas ni ids como parámetros.

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/add_maintenance_use_case.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/update_maintenance_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';

class MockAddMaintenanceUseCase extends Mock implements AddMaintenanceUseCase {}

class MockUpdateMaintenanceUseCase extends Mock
    implements UpdateMaintenanceUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeMaintenanceModel extends Fake implements MaintenanceModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMaintenanceModel());
  });

  late MockAddMaintenanceUseCase mockAdd;
  late MockUpdateMaintenanceUseCase mockUpdate;
  late MockAnalyticsService mockAnalytics;
  late MaintenanceFormCubit cubit;

  final completedMaintenance = MaintenanceModel(
    vehicleId: 'v1',
    type: MaintenanceType.oilChange,
    mode: MaintenanceMode.completed,
    serviceDate: DateTime(2026, 6, 1),
    odometerAtService: 15000,
  );

  setUp(() {
    mockAdd = MockAddMaintenanceUseCase();
    mockUpdate = MockUpdateMaintenanceUseCase();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    cubit = MaintenanceFormCubit(mockAdd, mockUpdate, mockAnalytics);
  });

  tearDown(() => cubit.close());

  group('MaintenanceFormCubit — analytics Fase 9', () {
    // TC-maint-a1: maintenance_added se emite al guardar nuevo mantenimiento
    test(
      'TC-maint-a1: saveMaintenance (add) exitoso → maintenance_added emitido',
      () async {
        when(
          () => mockAdd(
            any(),
            nextKmInterval: any(named: 'nextKmInterval'),
          ),
        ).thenAnswer((_) async => Right([completedMaintenance]));

        await cubit.saveMaintenance(completedMaintenance);

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.maintenanceAdded,
            any(),
          ),
        ).called(1);
      },
    );

    // TC-maint-a2: maintenance_added incluye maintenance_type con enum name
    test(
      'TC-maint-a2: maintenance_added contiene maintenance_type = oilChange',
      () async {
        when(
          () => mockAdd(
            any(),
            nextKmInterval: any(named: 'nextKmInterval'),
          ),
        ).thenAnswer((_) async => Right([completedMaintenance]));

        await cubit.saveMaintenance(completedMaintenance);

        final captured = verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.maintenanceAdded,
            captureAny(),
          ),
        ).captured;

        final params = captured.single as Map<String, Object>;
        expect(
          params[AnalyticsParams.maintenanceType],
          MaintenanceType.oilChange.name,
        );
      },
    );

    // TC-maint-a3: G2 — params no contienen notas ni kilometraje
    test(
      'TC-maint-a3: G2 — params de maintenance_added no contienen notas '
      'ni kilometraje exacto',
      () async {
        final maintenanceWithNotes = MaintenanceModel(
          vehicleId: 'v1',
          type: MaintenanceType.brakeCheck,
          mode: MaintenanceMode.completed,
          notes: 'Notas privadas del taller',
          odometerAtService: 99999,
          serviceDate: DateTime(2026, 6, 1),
        );

        when(
          () => mockAdd(
            any(),
            nextKmInterval: any(named: 'nextKmInterval'),
          ),
        ).thenAnswer((_) async => Right([maintenanceWithNotes]));

        await cubit.saveMaintenance(maintenanceWithNotes);

        final captured = verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.maintenanceAdded,
            captureAny(),
          ),
        ).captured;

        final params = captured.single as Map<String, Object>;

        // Notes and exact odometer must NOT appear as param values
        expect(params.values, isNot(contains('Notas privadas del taller')));
        expect(params.values, isNot(contains(99999)));
        expect(params.keys, isNot(contains('notes')));
        expect(params.keys, isNot(contains('odometer')));
      },
    );

    // TC-maint-a4: saveMaintenance con error (add) → maintenance_added NO emitido
    test(
      'TC-maint-a4: saveMaintenance (add) con error → maintenance_added NO emitido',
      () async {
        when(
          () => mockAdd(
            any(),
            nextKmInterval: any(named: 'nextKmInterval'),
          ),
        ).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Error de red')),
        );

        await cubit.saveMaintenance(completedMaintenance);

        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.maintenanceAdded, any()),
        );
      },
    );
  });
}
