// Analytics tests — Fase 9: Vehículos
// Verifica:
//   has_vehicle user property se cableó tras fetchMyVehicles.
//   vehicle_set_main se emite tras setMainVehicle exitoso.
//   G2: valor de has_vehicle es solo '0' o '1', sin PII.

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

class MockGetMyVehiclesUseCase extends Mock implements GetMyVehiclesUseCase {}

class MockSetMainVehicleUseCase extends Mock implements SetMainVehicleUseCase {}

class MockUpdateVehicleUseCase extends Mock implements UpdateVehicleUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

const _vehicle1 = VehicleModel(
  id: 'v1',
  name: 'Honda CB500',
  currentMileage: 12000,
  isMainVehicle: true,
);

const _vehicle2 = VehicleModel(
  id: 'v2',
  name: 'Yamaha MT-07',
  currentMileage: 5000,
  isMainVehicle: false,
);

void main() {
  late MockGetMyVehiclesUseCase mockGetVehicles;
  late MockSetMainVehicleUseCase mockSetMain;
  late MockUpdateVehicleUseCase mockUpdateVehicle;
  late MockAnalyticsService mockAnalytics;
  late VehicleCubit cubit;

  setUp(() {
    mockGetVehicles = MockGetMyVehiclesUseCase();
    mockSetMain = MockSetMainVehicleUseCase();
    mockUpdateVehicle = MockUpdateVehicleUseCase();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    when(() => mockAnalytics.setUserProperty(any(), any()))
        .thenAnswer((_) async {});
    cubit = VehicleCubit(
      mockGetVehicles,
      mockSetMain,
      mockUpdateVehicle,
      mockAnalytics,
    );
  });

  tearDown(() => cubit.close());

  group('VehicleCubit — analytics Fase 9', () {
    // TC-veh-a1: has_vehicle='1' tras fetchMyVehicles con vehículos
    test(
      'TC-veh-a1: fetchMyVehicles con vehículos → setUserProperty has_vehicle=1',
      () async {
        when(() => mockGetVehicles())
            .thenAnswer((_) async => const Right([_vehicle1, _vehicle2]));

        await cubit.fetchMyVehicles();

        verify(
          () => mockAnalytics.setUserProperty(
            AnalyticsParams.userPropertyHasVehicle,
            '1',
          ),
        ).called(1);
      },
    );

    // TC-veh-a2: has_vehicle='0' tras fetchMyVehicles con lista vacía
    test(
      'TC-veh-a2: fetchMyVehicles con lista vacía → setUserProperty has_vehicle=0',
      () async {
        when(() => mockGetVehicles())
            .thenAnswer((_) async => const Right([]));

        await cubit.fetchMyVehicles();

        verify(
          () => mockAnalytics.setUserProperty(
            AnalyticsParams.userPropertyHasVehicle,
            '0',
          ),
        ).called(1);
      },
    );

    // TC-veh-a3: vehicle_set_main emitido tras setMainVehicle exitoso
    test(
      'TC-veh-a3: setMainVehicle exitoso → vehicle_set_main emitido',
      () async {
        when(() => mockGetVehicles())
            .thenAnswer((_) async => const Right([_vehicle1, _vehicle2]));
        when(() => mockSetMain('v2')).thenAnswer(
          (_) async => const Right(
            VehicleModel(
              id: 'v2',
              name: 'Yamaha MT-07',
              currentMileage: 5000,
              isMainVehicle: true,
            ),
          ),
        );

        await cubit.fetchMyVehicles();
        await cubit.setMainVehicle('v2');

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.vehicleSetMain),
        ).called(1);
      },
    );

    // TC-veh-a4: G2 — valor de has_vehicle es '0' o '1', nunca PII
    test(
      'TC-veh-a4: G2 — valor de has_vehicle es solo 0 o 1, sin PII',
      () async {
        when(() => mockGetVehicles())
            .thenAnswer((_) async => const Right([_vehicle1]));

        await cubit.fetchMyVehicles();

        final captured = verify(
          () => mockAnalytics.setUserProperty(
            AnalyticsParams.userPropertyHasVehicle,
            captureAny(),
          ),
        ).captured;

        expect(captured.single, anyOf('0', '1'));
      },
    );

    // TC-veh-a5: fetchMyVehicles con error → setUserProperty NO llamado
    test(
      'TC-veh-a5: fetchMyVehicles con error → setUserProperty NO emitido',
      () async {
        when(() => mockGetVehicles()).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Error de red')),
        );

        await cubit.fetchMyVehicles();

        verifyNever(
          () => mockAnalytics.setUserProperty(any(), any()),
        );
      },
    );
  });
}
