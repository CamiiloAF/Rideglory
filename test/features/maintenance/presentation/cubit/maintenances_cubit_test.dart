import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_user_list_aggregate.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart';

class MockGetMaintenanceListUseCase extends Mock
    implements GetMaintenanceListUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

final _scheduledMaintenance = MaintenanceModel(
  id: 'm1',
  vehicleId: 'v1',
  type: MaintenanceType.oilChange,
  mode: MaintenanceMode.scheduled,
  nextOdometer: 15000,
);

final _completedMaintenance = MaintenanceModel(
  id: 'm2',
  vehicleId: 'v1',
  type: MaintenanceType.brakeCheck,
  mode: MaintenanceMode.completed,
  serviceDate: DateTime(2025, 1, 15),
);

void main() {
  late MockGetMaintenanceListUseCase mockUseCase;
  late MaintenancesCubit cubit;

  setUp(() {
    mockUseCase = MockGetMaintenanceListUseCase();
    final mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    cubit = MaintenancesCubit(mockUseCase, mockAnalytics);
  });

  tearDown(() {
    cubit.close();
  });

  group('MaintenancesCubit', () {
    test('TC-maint-1: initial state is ResultState.initial', () {
      expect(cubit.state, const ResultState<List<MaintenanceModel>>.initial());
    });

    group('fetchMaintenances', () {
      blocTest<MaintenancesCubit, ResultState<List<MaintenanceModel>>>(
        'TC-maint-2: emits loading then data when use case returns maintenances',
        setUp: () {
          when(
            () => mockUseCase.execute(
              types: any(named: 'types'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            ),
          ).thenAnswer(
            (_) async => Right(
              MaintenanceUserListAggregate(
                items: [_scheduledMaintenance, _completedMaintenance],
                summariesByVehicleId: {},
              ),
            ),
          );
        },
        build: () => cubit,
        act: (c) => c.fetchMaintenances(),
        expect: () => [
          const ResultState<List<MaintenanceModel>>.loading(),
          predicate<ResultState<List<MaintenanceModel>>>(
            (state) =>
                state is Data<List<MaintenanceModel>> && state.data.length == 2,
          ),
        ],
      );

      blocTest<MaintenancesCubit, ResultState<List<MaintenanceModel>>>(
        'TC-maint-3: emits loading then error when use case fails',
        setUp: () {
          when(
            () => mockUseCase.execute(
              types: any(named: 'types'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            ),
          ).thenAnswer(
            (_) async =>
                const Left(DomainException(message: 'Error de servidor')),
          );
        },
        build: () => cubit,
        act: (c) => c.fetchMaintenances(),
        expect: () => [
          const ResultState<List<MaintenanceModel>>.loading(),
          predicate<ResultState<List<MaintenanceModel>>>(
            (state) =>
                state is Error<List<MaintenanceModel>> &&
                state.error.message == 'Error de servidor',
          ),
        ],
      );

      blocTest<MaintenancesCubit, ResultState<List<MaintenanceModel>>>(
        'TC-maint-4: emits loading then empty when list is empty',
        setUp: () {
          when(
            () => mockUseCase.execute(
              types: any(named: 'types'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            ),
          ).thenAnswer(
            (_) async => const Right(
              MaintenanceUserListAggregate(items: [], summariesByVehicleId: {}),
            ),
          );
        },
        build: () => cubit,
        act: (c) => c.fetchMaintenances(),
        expect: () => [
          const ResultState<List<MaintenanceModel>>.loading(),
          const ResultState<List<MaintenanceModel>>.empty(),
        ],
      );
    });

    group('addMaintenanceLocally', () {
      test(
        'TC-maint-5: adds maintenance to local list and emits data',
        () async {
          when(
            () => mockUseCase.execute(
              types: any(named: 'types'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            ),
          ).thenAnswer(
            (_) async => Right(
              MaintenanceUserListAggregate(
                items: [_completedMaintenance],
                summariesByVehicleId: {},
              ),
            ),
          );
          await cubit.fetchMaintenances();

          cubit.addMaintenanceLocally(_scheduledMaintenance);

          final state = cubit.state;
          expect(state, isA<Data<List<MaintenanceModel>>>());
          final data = (state as Data<List<MaintenanceModel>>).data;
          expect(data.any((m) => m.id == 'm1'), isTrue);
          expect(data.any((m) => m.id == 'm2'), isTrue);
        },
      );
    });

    group('deleteMaintenanceLocally', () {
      test(
        'TC-maint-6: removes maintenance from local list and emits data',
        () async {
          when(
            () => mockUseCase.execute(
              types: any(named: 'types'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            ),
          ).thenAnswer(
            (_) async => Right(
              MaintenanceUserListAggregate(
                items: [_scheduledMaintenance, _completedMaintenance],
                summariesByVehicleId: {},
              ),
            ),
          );
          await cubit.fetchMaintenances();
          cubit.deleteMaintenanceLocally('m1');

          final state = cubit.state;
          expect(state, isA<Data<List<MaintenanceModel>>>());
          final data = (state as Data<List<MaintenanceModel>>).data;
          expect(data.any((m) => m.id == 'm1'), isFalse);
          expect(data.length, 1);
        },
      );
    });

    group('updateSearchQuery', () {
      test('TC-maint-7: filters by search query', () async {
        when(
          () => mockUseCase.execute(
            types: any(named: 'types'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => Right(
            MaintenanceUserListAggregate(
              items: [_scheduledMaintenance, _completedMaintenance],
              summariesByVehicleId: {},
            ),
          ),
        );
        await cubit.fetchMaintenances();

        // Search for "aceite" which matches OIL_CHANGE label "Cambio de aceite"
        cubit.updateSearchQuery('aceite');
        final state = cubit.state;
        expect(state, isA<Data<List<MaintenanceModel>>>());
        final data = (state as Data<List<MaintenanceModel>>).data;
        expect(data.every((m) => m.type == MaintenanceType.oilChange), isTrue);
      });
    });

    group('MaintenanceModel.calculateStatus', () {
      test(
        'TC-maint-8: returns overdue when odometer exceeds nextOdometer',
        () {
          final maintenance = MaintenanceModel(
            type: MaintenanceType.oilChange,
            mode: MaintenanceMode.scheduled,
            nextOdometer: 10000,
          );
          final status = MaintenanceModel.calculateStatus(maintenance, 12000);
          expect(status, MaintenanceStatus.overdue);
        },
      );

      test(
        'TC-maint-9: returns null for completed maintenance (no status applies)',
        () {
          final maintenance = MaintenanceModel(
            type: MaintenanceType.brakeCheck,
            mode: MaintenanceMode.completed,
          );
          final status = MaintenanceModel.calculateStatus(maintenance, 5000);
          expect(status, isNull);
        },
      );
    });
  });
}
