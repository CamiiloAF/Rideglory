import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/notifications/maintenance_notification_scheduler.dart';
import 'package:rideglory/features/maintenance/domain/maintenance.dart';
import 'package:rideglory/features/maintenance/domain/maintenance_reminder.dart';
import 'package:rideglory/features/maintenance/domain/register_maintenance_params.dart';
import 'package:rideglory/features/maintenance/domain/usecases/delete_maintenance_use_case.dart';
import 'package:rideglory/features/maintenance/domain/usecases/get_maintenances_use_case.dart';
import 'package:rideglory/features/maintenance/domain/usecases/get_vehicles_use_case.dart';
import 'package:rideglory/features/maintenance/domain/usecases/update_maintenance_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/cubit/maintenance_detail_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/cubit/maintenance_detail_state.dart';

class _MockGetMaintenancesUseCase extends Mock
    implements GetMaintenancesUseCase {}

class _MockGetVehiclesUseCase extends Mock implements GetVehiclesUseCase {}

class _MockDeleteMaintenanceUseCase extends Mock
    implements DeleteMaintenanceUseCase {}

class _MockUpdateMaintenanceUseCase extends Mock
    implements UpdateMaintenanceUseCase {}

class _MockMaintenanceNotificationScheduler extends Mock
    implements MaintenanceNotificationScheduler {}

class _FakeRegisterMaintenanceParams extends Fake
    implements RegisterMaintenanceParams {}

final _maintenance = Maintenance(
  id: 'm1',
  vehicleId: 'v1',
  vehicleDisplayName: 'Mi moto',
  type: 'Cambio de aceite',
  serviceDate: DateTime(2026, 1, 1),
  odometer: 1000,
);

void main() {
  late _MockGetMaintenancesUseCase getMaintenances;
  late _MockGetVehiclesUseCase getVehicles;
  late _MockDeleteMaintenanceUseCase deleteMaintenance;
  late _MockUpdateMaintenanceUseCase updateMaintenance;
  late _MockMaintenanceNotificationScheduler notifications;

  setUpAll(() {
    registerFallbackValue(_FakeRegisterMaintenanceParams());
  });

  setUp(() {
    getMaintenances = _MockGetMaintenancesUseCase();
    getVehicles = _MockGetVehiclesUseCase();
    deleteMaintenance = _MockDeleteMaintenanceUseCase();
    updateMaintenance = _MockUpdateMaintenanceUseCase();
    notifications = _MockMaintenanceNotificationScheduler();
  });

  MaintenanceDetailCubit buildCubit() => MaintenanceDetailCubit(
    getMaintenances,
    getVehicles,
    deleteMaintenance,
    updateMaintenance,
    notifications,
  )..emit(MaintenanceDetailState(maintenance: _maintenance));

  blocTest<MaintenanceDetailCubit, dynamic>(
    'delete emits an error result when the use case fails, without cancelling the reminder',
    setUp: () {
      when(() => deleteMaintenance('m1')).thenAnswer(
        (_) async => const Left(DomainException(message: 'network_error')),
      );
    },
    build: buildCubit,
    act: (cubit) => cubit.delete(),
    verify: (cubit) {
      expect(cubit.state.deletion, isA<Error<Unit>>());
      verifyNever(() => notifications.cancel(any()));
    },
  );

  blocTest<MaintenanceDetailCubit, dynamic>(
    'updateReminder emits an error result when the use case fails',
    setUp: () {
      when(() => updateMaintenance('m1', any())).thenAnswer(
        (_) async => const Left(DomainException(message: 'network_error')),
      );
    },
    build: buildCubit,
    act: (cubit) =>
        cubit.updateReminder(const MaintenanceReminder(everyKm: 5000)),
    verify: (cubit) {
      expect(cubit.state.reminderUpdate, isA<Error<Unit>>());
    },
  );
}
