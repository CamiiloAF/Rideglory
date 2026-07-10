// Unit tests for VehicleMaintenancesCubit (garage/detail vehicle
// maintenance list). Covers fetch, local mutation helpers and the
// lastCompleted/nextScheduled derived getters.

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_vehicle_list_result.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';
import 'package:rideglory/features/vehicles/presentation/garage/cubit/vehicle_maintenances_cubit.dart';

class MockGetMaintenancesByVehicleIdUseCase extends Mock
    implements GetMaintenancesByVehicleIdUseCase {}

final _completedOld = MaintenanceModel(
  id: 'm1',
  vehicleId: 'v1',
  type: MaintenanceType.oilChange,
  mode: MaintenanceMode.completed,
  serviceDate: DateTime(2026, 1, 1),
);

final _completedNew = MaintenanceModel(
  id: 'm2',
  vehicleId: 'v1',
  type: MaintenanceType.brakeCheck,
  mode: MaintenanceMode.completed,
  serviceDate: DateTime(2026, 6, 1),
);

final _scheduledFar = MaintenanceModel(
  id: 'm3',
  vehicleId: 'v1',
  type: MaintenanceType.tireChange,
  mode: MaintenanceMode.scheduled,
  nextDate: DateTime(2027, 1, 1),
);

final _scheduledSoon = MaintenanceModel(
  id: 'm4',
  vehicleId: 'v1',
  type: MaintenanceType.chainSprocket,
  mode: MaintenanceMode.scheduled,
  nextDate: DateTime(2026, 8, 1),
);

void main() {
  late MockGetMaintenancesByVehicleIdUseCase mockUseCase;
  late VehicleMaintenancesCubit cubit;

  setUp(() {
    mockUseCase = MockGetMaintenancesByVehicleIdUseCase();
    cubit = VehicleMaintenancesCubit(mockUseCase);
  });

  tearDown(() {
    cubit.close();
  });

  group('VehicleMaintenancesCubit', () {
    test('initial state is ResultState.initial', () {
      expect(cubit.state, const ResultState<List<MaintenanceModel>>.initial());
    });

    group('fetchMaintenances', () {
      blocTest<VehicleMaintenancesCubit, ResultState<List<MaintenanceModel>>>(
        'emits loading then data sorted by service/created date desc',
        setUp: () {
          when(() => mockUseCase.execute('v1')).thenAnswer(
            (_) async => Right(
              MaintenanceVehicleListResult(
                items: [_completedOld, _completedNew],
                summary: const MaintenanceListSummary(),
              ),
            ),
          );
        },
        build: () => cubit,
        act: (cubit) => cubit.fetchMaintenances('v1'),
        expect: () => [
          const ResultState<List<MaintenanceModel>>.loading(),
          predicate<ResultState<List<MaintenanceModel>>>(
            (state) =>
                state is Data<List<MaintenanceModel>> &&
                state.data.first.id == 'm2',
          ),
        ],
      );

      blocTest<VehicleMaintenancesCubit, ResultState<List<MaintenanceModel>>>(
        'emits loading then empty when the vehicle has no maintenance records',
        setUp: () {
          when(() => mockUseCase.execute('v1')).thenAnswer(
            (_) async => const Right(
              MaintenanceVehicleListResult(
                items: [],
                summary: MaintenanceListSummary(),
              ),
            ),
          );
        },
        build: () => cubit,
        act: (cubit) => cubit.fetchMaintenances('v1'),
        expect: () => [
          const ResultState<List<MaintenanceModel>>.loading(),
          const ResultState<List<MaintenanceModel>>.empty(),
        ],
      );

      blocTest<VehicleMaintenancesCubit, ResultState<List<MaintenanceModel>>>(
        'emits loading then error when the use case fails',
        setUp: () {
          when(() => mockUseCase.execute('v1')).thenAnswer(
            (_) async =>
                const Left(DomainException(message: 'No se pudo consultar')),
          );
        },
        build: () => cubit,
        act: (cubit) => cubit.fetchMaintenances('v1'),
        expect: () => [
          const ResultState<List<MaintenanceModel>>.loading(),
          predicate<ResultState<List<MaintenanceModel>>>(
            (state) =>
                state is Error<List<MaintenanceModel>> &&
                state.error.message == 'No se pudo consultar',
          ),
        ],
      );
    });

    group('lastCompleted / nextScheduled', () {
      test(
        'lastCompleted returns the most recent completed record',
        () async {
          when(() => mockUseCase.execute('v1')).thenAnswer(
            (_) async => Right(
              MaintenanceVehicleListResult(
                items: [_completedOld, _completedNew],
                summary: const MaintenanceListSummary(),
              ),
            ),
          );
          await cubit.fetchMaintenances('v1');

          expect(cubit.lastCompleted?.id, 'm2');
        },
      );

      test(
        'nextScheduled returns the most urgent scheduled record',
        () async {
          when(() => mockUseCase.execute('v1')).thenAnswer(
            (_) async => Right(
              MaintenanceVehicleListResult(
                items: [_scheduledFar, _scheduledSoon],
                summary: const MaintenanceListSummary(),
              ),
            ),
          );
          await cubit.fetchMaintenances('v1');

          expect(cubit.nextScheduled?.id, 'm4');
        },
      );

      test('lastCompleted is null when state is not data', () {
        expect(cubit.lastCompleted, isNull);
      });
    });

    group('addMaintenanceLocally', () {
      blocTest<VehicleMaintenancesCubit, ResultState<List<MaintenanceModel>>>(
        'appends and re-sorts when state is data',
        build: () => cubit,
        seed: () => ResultState.data(data: [_completedOld]),
        act: (cubit) => cubit.addMaintenanceLocally(
          _completedNew,
          vehicleId: 'v1',
        ),
        expect: () => [
          predicate<ResultState<List<MaintenanceModel>>>(
            (state) =>
                state is Data<List<MaintenanceModel>> &&
                state.data.length == 2 &&
                state.data.first.id == 'm2',
          ),
        ],
      );

      blocTest<VehicleMaintenancesCubit, ResultState<List<MaintenanceModel>>>(
        'emits data with single item when state was empty',
        build: () => cubit,
        seed: () => const ResultState.empty(),
        act: (cubit) => cubit.addMaintenanceLocally(
          _completedNew,
          vehicleId: 'v1',
        ),
        expect: () => [
          predicate<ResultState<List<MaintenanceModel>>>(
            (state) =>
                state is Data<List<MaintenanceModel>> &&
                state.data.single.id == 'm2',
          ),
        ],
      );
    });

    group('updateMaintenanceLocally', () {
      blocTest<VehicleMaintenancesCubit, ResultState<List<MaintenanceModel>>>(
        'replaces the matching record by id',
        build: () => cubit,
        seed: () => ResultState.data(data: [_completedOld]),
        act: (cubit) {
          final updated = MaintenanceModel(
            id: 'm1',
            vehicleId: 'v1',
            type: MaintenanceType.oilChange,
            mode: MaintenanceMode.completed,
            serviceDate: DateTime(2026, 1, 1),
            notes: 'updated notes',
          );
          cubit.updateMaintenanceLocally(updated);
        },
        expect: () => [
          predicate<ResultState<List<MaintenanceModel>>>(
            (state) =>
                state is Data<List<MaintenanceModel>> &&
                state.data.single.notes == 'updated notes',
          ),
        ],
      );
    });

    group('deleteMaintenanceLocally', () {
      blocTest<VehicleMaintenancesCubit, ResultState<List<MaintenanceModel>>>(
        'removes the matching record and emits empty when list becomes empty',
        build: () => cubit,
        seed: () => ResultState.data(data: [_completedOld]),
        act: (cubit) => cubit.deleteMaintenanceLocally('m1'),
        expect: () => [const ResultState<List<MaintenanceModel>>.empty()],
      );

      blocTest<VehicleMaintenancesCubit, ResultState<List<MaintenanceModel>>>(
        'removes the matching record and keeps data when others remain',
        build: () => cubit,
        seed: () => ResultState.data(data: [_completedOld, _completedNew]),
        act: (cubit) => cubit.deleteMaintenanceLocally('m1'),
        expect: () => [
          predicate<ResultState<List<MaintenanceModel>>>(
            (state) =>
                state is Data<List<MaintenanceModel>> &&
                state.data.single.id == 'm2',
          ),
        ],
      );
    });
  });
}
