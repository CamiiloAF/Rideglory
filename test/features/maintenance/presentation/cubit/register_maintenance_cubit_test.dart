import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/maintenance/domain/maintenance.dart';
import 'package:rideglory/features/maintenance/domain/maintenance_type_suggestion.dart';
import 'package:rideglory/features/maintenance/domain/register_maintenance_params.dart';
import 'package:rideglory/features/maintenance/domain/usecases/register_maintenance_use_case.dart';
import 'package:rideglory/features/maintenance/domain/usecases/update_maintenance_use_case.dart';
import 'package:rideglory/features/maintenance/domain/vehicle_option.dart';
import 'package:rideglory/features/maintenance/presentation/cubit/register_maintenance_cubit.dart';

class _MockRegisterMaintenanceUseCase extends Mock
    implements RegisterMaintenanceUseCase {}

class _MockUpdateMaintenanceUseCase extends Mock
    implements UpdateMaintenanceUseCase {}

void main() {
  late _MockRegisterMaintenanceUseCase register;
  late _MockUpdateMaintenanceUseCase update;

  const vehicle = VehicleOption(
    id: 'v1',
    displayName: 'Yamaha MT-03',
    chipLabel: 'MT-03',
    currentMileage: 8500,
    isMain: true,
  );

  setUpAll(() {
    registerFallbackValue(
      RegisterMaintenanceParams(
        vehicleId: 'v1',
        type: 'x',
        serviceDate: DateTime(2026),
        odometer: 0,
      ),
    );
  });

  setUp(() {
    register = _MockRegisterMaintenanceUseCase();
    update = _MockUpdateMaintenanceUseCase();
  });

  RegisterMaintenanceCubit buildCubit() =>
      RegisterMaintenanceCubit(register, update);

  test('start() prefills the odometer with the vehicle current mileage', () {
    final cubit = buildCubit()..start(vehicle);

    expect(cubit.state.vehicle, vehicle);
    expect(cubit.state.odometer, vehicle.currentMileage);
    expect(cubit.state.isEditing, isFalse);
  });

  test(
    'start() with an existing maintenance prefills every field as "other"',
    () {
      final existing = Maintenance(
        id: 'm1',
        vehicleId: 'v1',
        vehicleDisplayName: 'Yamaha MT-03',
        type: 'Cambio de aceite',
        serviceDate: DateTime(2026, 8, 12),
        odometer: 18450,
        workshop: 'Moto Repuestos JR',
        cost: 480000,
        nextOdometer: 26000,
      );

      final cubit = buildCubit()..start(vehicle, existing: existing);

      expect(cubit.state.isEditing, isTrue);
      expect(cubit.state.isOtherType, isTrue);
      expect(cubit.state.customType, 'Cambio de aceite');
      expect(cubit.state.odometer, 18450);
      expect(cubit.state.reminderEnabled, isTrue);
      expect(cubit.state.reminder?.everyKm, 7550);
    },
  );

  test(
    'canContinueStep1 requires a suggestion, or non-empty text for "other"',
    () {
      final cubit = buildCubit()..start(vehicle);
      expect(cubit.state.canContinueStep1, isFalse);

      cubit.selectTypeSuggestion(
        MaintenanceTypeSuggestion.oilChange,
        'Cambio de aceite y filtro',
      );
      expect(cubit.state.canContinueStep1, isTrue);

      cubit.selectTypeSuggestion(MaintenanceTypeSuggestion.other, 'Otro');
      expect(cubit.state.canContinueStep1, isFalse);

      cubit.updateCustomType('Cambio de bujías');
      expect(cubit.state.canContinueStep1, isTrue);
    },
  );

  test(
    'isBelowCurrentOdometer flags a mileage lower than the vehicle current one',
    () {
      final cubit = buildCubit()..start(vehicle);

      cubit.updateOdometer(8000);
      expect(cubit.state.isBelowCurrentOdometer, isTrue);

      cubit.updateOdometer(9000);
      expect(cubit.state.isBelowCurrentOdometer, isFalse);
    },
  );

  blocTest<RegisterMaintenanceCubit, dynamic>(
    'submit() registers a new maintenance and emits it as data on success',
    build: buildCubit,
    seed: () {
      final cubit = buildCubit();
      cubit.start(vehicle);
      cubit.selectTypeSuggestion(
        MaintenanceTypeSuggestion.oilChange,
        'Cambio de aceite y filtro',
      );
      cubit.updateOdometer(18450);
      cubit.updateServiceDate(DateTime(2026, 8, 12));
      return cubit.state;
    },
    setUp: () {
      when(() => register(any())).thenAnswer(
        (_) async => Right(
          Maintenance(
            id: 'm1',
            vehicleId: vehicle.id,
            vehicleDisplayName: vehicle.displayName,
            type: 'Cambio de aceite y filtro',
            serviceDate: DateTime(2026, 8, 12),
            odometer: 18450,
          ),
        ),
      );
    },
    act: (cubit) => cubit.submit(),
    verify: (cubit) {
      expect(cubit.state.submission.whenOrNull(data: (data) => data.id), 'm1');
      verify(() => register(any())).called(1);
      verifyNever(() => update(any(), any()));
    },
  );

  blocTest<RegisterMaintenanceCubit, dynamic>(
    'submit() with an editingId updates instead of registering',
    build: buildCubit,
    seed: () {
      final cubit = buildCubit();
      final existing = Maintenance(
        id: 'm1',
        vehicleId: vehicle.id,
        vehicleDisplayName: vehicle.displayName,
        type: 'Cambio de aceite',
        serviceDate: DateTime(2026, 8, 12),
        odometer: 18450,
      );
      cubit.start(vehicle, existing: existing);
      return cubit.state;
    },
    setUp: () {
      when(() => update(any(), any())).thenAnswer(
        (_) async => Right(
          Maintenance(
            id: 'm1',
            vehicleId: vehicle.id,
            vehicleDisplayName: vehicle.displayName,
            type: 'Cambio de aceite',
            serviceDate: DateTime(2026, 8, 12),
            odometer: 18450,
          ),
        ),
      );
    },
    act: (cubit) => cubit.submit(),
    verify: (cubit) {
      verify(() => update('m1', any())).called(1);
      verifyNever(() => register(any()));
    },
  );

  blocTest<RegisterMaintenanceCubit, dynamic>(
    'submit() emits an error result when the repository fails',
    build: buildCubit,
    seed: () {
      final cubit = buildCubit();
      cubit.start(vehicle);
      cubit.selectTypeSuggestion(
        MaintenanceTypeSuggestion.oilChange,
        'Cambio de aceite y filtro',
      );
      cubit.updateOdometer(18450);
      cubit.updateServiceDate(DateTime(2026, 8, 12));
      return cubit.state;
    },
    setUp: () {
      when(() => register(any())).thenAnswer(
        (_) async => const Left(DomainException(message: 'network_error')),
      );
    },
    act: (cubit) => cubit.submit(),
    verify: (cubit) {
      expect(
        cubit.state.submission.maybeWhen(
          error: (_) => true,
          orElse: () => false,
        ),
        isTrue,
      );
    },
  );
}
