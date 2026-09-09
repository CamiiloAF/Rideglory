import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/maintenance/domain/maintenance.dart';
import 'package:rideglory/features/maintenance/domain/maintenance_agenda_item.dart';
import 'package:rideglory/features/maintenance/domain/usecases/get_maintenances_use_case.dart';
import 'package:rideglory/features/maintenance/domain/usecases/get_vehicles_use_case.dart';
import 'package:rideglory/features/maintenance/domain/vehicle_option.dart';
import 'package:rideglory/features/maintenance/presentation/cubit/maintenance_cubit.dart';

class _MockGetVehiclesUseCase extends Mock implements GetVehiclesUseCase {}

class _MockGetMaintenancesUseCase extends Mock
    implements GetMaintenancesUseCase {}

void main() {
  late _MockGetVehiclesUseCase getVehicles;
  late _MockGetMaintenancesUseCase getMaintenances;

  const vehicle = VehicleOption(
    id: 'v1',
    displayName: 'Yamaha MT-03',
    chipLabel: 'MT-03',
    currentMileage: 18450,
    isMain: true,
  );

  final maintenance = Maintenance(
    id: 'm1',
    vehicleId: 'v1',
    vehicleDisplayName: 'Yamaha MT-03',
    type: 'Cambio de aceite',
    serviceDate: DateTime(2026, 8, 12),
    odometer: 18450,
  );

  setUp(() {
    getVehicles = _MockGetVehiclesUseCase();
    getMaintenances = _MockGetMaintenancesUseCase();
  });

  MaintenanceCubit buildCubit() =>
      MaintenanceCubit(getVehicles, getMaintenances);

  blocTest<MaintenanceCubit, dynamic>(
    'load() emits data for both vehicles and maintenances on success',
    build: () {
      when(() => getVehicles()).thenAnswer((_) async => const Right([vehicle]));
      when(
        () => getMaintenances(),
      ).thenAnswer((_) async => Right([maintenance]));
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.vehicleList, [vehicle]);
      expect(cubit.state.maintenanceList, [maintenance]);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.hasError, isFalse);
      expect(cubit.state.isEmpty, isFalse);
    },
  );

  blocTest<MaintenanceCubit, dynamic>(
    'load() surfaces an error when the vehicles request fails',
    build: () {
      when(
        () => getVehicles(),
      ).thenAnswer((_) async => const Left(DomainException(message: 'boom')));
      when(() => getMaintenances()).thenAnswer((_) async => const Right([]));
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.hasError, isTrue);
    },
  );

  blocTest<MaintenanceCubit, dynamic>(
    'isEmpty is true when there are no maintenances at all',
    build: () {
      when(() => getVehicles()).thenAnswer((_) async => const Right([vehicle]));
      when(() => getMaintenances()).thenAnswer((_) async => const Right([]));
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.isEmpty, isTrue);
    },
  );

  blocTest<MaintenanceCubit, dynamic>(
    'selectVehicle filters the maintenance list used to compute the agenda',
    build: () {
      when(() => getVehicles()).thenAnswer((_) async => const Right([vehicle]));
      when(
        () => getMaintenances(),
      ).thenAnswer((_) async => Right([maintenance]));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load();
      cubit.selectVehicle('other-vehicle');
    },
    verify: (cubit) {
      expect(cubit.state.selectedVehicleId, 'other-vehicle');
      expect(cubit.state.agendaItems, isEmpty);
    },
  );

  blocTest<MaintenanceCubit, dynamic>(
    'filterByStatus keeps only agenda items matching the chosen urgency',
    build: () {
      final overdueVehicle = vehicle.copyWith(currentMileage: 20000);
      final withReminder = maintenance.copyWith(nextOdometer: 19000);
      when(
        () => getVehicles(),
      ).thenAnswer((_) async => Right([overdueVehicle]));
      when(
        () => getMaintenances(),
      ).thenAnswer((_) async => Right([withReminder]));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load();
      cubit.filterByStatus(MaintenanceUrgency.upcoming);
    },
    verify: (cubit) {
      expect(cubit.state.agendaItems, isEmpty);
    },
  );
}
