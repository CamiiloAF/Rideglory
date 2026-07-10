// Unit tests for VehicleActionCubit — unifies archive, unarchive and
// permanent delete. Replaced the old VehicleDeleteCubit (see
// docs/features/vehicles.md §4).

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/archive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/permanently_delete_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/unarchive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart';

class MockPermanentlyDeleteVehicleUseCase extends Mock
    implements PermanentlyDeleteVehicleUseCase {}

class MockArchiveVehicleUseCase extends Mock implements ArchiveVehicleUseCase {}

class MockUnarchiveVehicleUseCase extends Mock
    implements UnarchiveVehicleUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockGetMyVehiclesUseCase extends Mock implements GetMyVehiclesUseCase {}

class MockSetMainVehicleUseCase extends Mock implements SetMainVehicleUseCase {}

class MockUpdateVehicleUseCase extends Mock implements UpdateVehicleUseCase {}

const _vehicle = VehicleModel(
  id: 'v1',
  name: 'Honda CB500',
  currentMileage: 5000,
);

void main() {
  late MockPermanentlyDeleteVehicleUseCase mockPermanentlyDelete;
  late MockArchiveVehicleUseCase mockArchive;
  late MockUnarchiveVehicleUseCase mockUnarchive;
  late MockAnalyticsService mockAnalytics;
  late VehicleCubit vehicleCubit;
  late VehicleActionCubit actionCubit;

  setUp(() {
    mockPermanentlyDelete = MockPermanentlyDeleteVehicleUseCase();
    mockArchive = MockArchiveVehicleUseCase();
    mockUnarchive = MockUnarchiveVehicleUseCase();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    when(
      () => mockAnalytics.setUserProperty(any(), any()),
    ).thenAnswer((_) async {});

    vehicleCubit = VehicleCubit(
      MockGetMyVehiclesUseCase(),
      MockSetMainVehicleUseCase(),
      MockUpdateVehicleUseCase(),
      mockAnalytics,
    );
    vehicleCubit.addVehicleLocally(_vehicle);

    actionCubit = VehicleActionCubit(
      mockPermanentlyDelete,
      mockArchive,
      mockUnarchive,
      vehicleCubit,
      mockAnalytics,
    );
  });

  tearDown(() {
    actionCubit.close();
    vehicleCubit.close();
  });

  group('VehicleActionCubit', () {
    test('initial state is VehicleActionState.initial', () {
      expect(actionCubit.state, const VehicleActionState.initial());
    });

    group('permanentlyDeleteVehicle', () {
      blocTest<VehicleActionCubit, VehicleActionState>(
        'emits loading then permanentDeleteSuccess on success',
        setUp: () {
          when(
            () => mockPermanentlyDelete('v1'),
          ).thenAnswer((_) async => const Right(null));
        },
        build: () => actionCubit,
        act: (cubit) => cubit.permanentlyDeleteVehicle('v1'),
        expect: () => [
          const VehicleActionState.loading(),
          const VehicleActionState.permanentDeleteSuccess(deletedId: 'v1'),
        ],
        verify: (_) {
          verify(
            () => mockAnalytics.logEvent(any()),
          ).called(greaterThanOrEqualTo(1));
        },
      );

      blocTest<VehicleActionCubit, VehicleActionState>(
        'emits loading then error when use case fails',
        setUp: () {
          when(() => mockPermanentlyDelete('v1')).thenAnswer(
            (_) async =>
                const Left(DomainException(message: 'No se pudo eliminar')),
          );
        },
        build: () => actionCubit,
        act: (cubit) => cubit.permanentlyDeleteVehicle('v1'),
        expect: () => [
          const VehicleActionState.loading(),
          const VehicleActionState.error(message: 'No se pudo eliminar'),
        ],
      );
    });

    group('archiveVehicle', () {
      blocTest<VehicleActionCubit, VehicleActionState>(
        'emits loading then archiveSuccess and updates VehicleCubit locally',
        setUp: () {
          when(() => mockArchive(_vehicle)).thenAnswer(
            (_) async => Right(_vehicle.copyWith(isArchived: true)),
          );
        },
        build: () => actionCubit,
        act: (cubit) => cubit.archiveVehicle(_vehicle),
        expect: () => [
          const VehicleActionState.loading(),
          const VehicleActionState.archiveSuccess(archivedId: 'v1'),
        ],
        verify: (_) {
          final vehicle = vehicleCubit.availableVehicles.firstWhere(
            (v) => v.id == 'v1',
          );
          expect(vehicle.isArchived, isTrue);
        },
      );

      blocTest<VehicleActionCubit, VehicleActionState>(
        'emits loading then error when use case fails',
        setUp: () {
          when(() => mockArchive(_vehicle)).thenAnswer(
            (_) async =>
                const Left(DomainException(message: 'No se pudo archivar')),
          );
        },
        build: () => actionCubit,
        act: (cubit) => cubit.archiveVehicle(_vehicle),
        expect: () => [
          const VehicleActionState.loading(),
          const VehicleActionState.error(message: 'No se pudo archivar'),
        ],
      );
    });

    group('unarchiveVehicle', () {
      blocTest<VehicleActionCubit, VehicleActionState>(
        'emits loading then unarchiveSuccess and updates VehicleCubit locally',
        setUp: () {
          when(() => mockUnarchive(_vehicle)).thenAnswer(
            (_) async => Right(_vehicle.copyWith(isArchived: false)),
          );
        },
        build: () => actionCubit,
        act: (cubit) => cubit.unarchiveVehicle(_vehicle),
        expect: () => [
          const VehicleActionState.loading(),
          const VehicleActionState.unarchiveSuccess(unarchivedId: 'v1'),
        ],
        verify: (_) {
          final vehicle = vehicleCubit.availableVehicles.firstWhere(
            (v) => v.id == 'v1',
          );
          expect(vehicle.isArchived, isFalse);
        },
      );

      blocTest<VehicleActionCubit, VehicleActionState>(
        'emits loading then error when use case fails',
        setUp: () {
          when(() => mockUnarchive(_vehicle)).thenAnswer(
            (_) async => const Left(
              DomainException(message: 'No se pudo desarchivar'),
            ),
          );
        },
        build: () => actionCubit,
        act: (cubit) => cubit.unarchiveVehicle(_vehicle),
        expect: () => [
          const VehicleActionState.loading(),
          const VehicleActionState.error(message: 'No se pudo desarchivar'),
        ],
      );
    });

    group('reset', () {
      blocTest<VehicleActionCubit, VehicleActionState>(
        'emits initial state',
        setUp: () {
          when(
            () => mockPermanentlyDelete('v1'),
          ).thenAnswer((_) async => const Right(null));
        },
        build: () => actionCubit,
        act: (cubit) async {
          await cubit.permanentlyDeleteVehicle('v1');
          cubit.reset();
        },
        skip: 2,
        expect: () => [const VehicleActionState.initial()],
      );
    });
  });
}
