import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
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

final _vehicle1WithDate = VehicleModel(
  id: 'v1',
  name: 'Honda CB500',
  currentMileage: 12000,
  isMainVehicle: true,
  createdAt: DateTime(2024, 1, 1),
);

final _vehicle2WithDate = VehicleModel(
  id: 'v2',
  name: 'Yamaha MT-07',
  currentMileage: 5000,
  isMainVehicle: false,
  createdAt: DateTime(2024, 6, 1),
);

void main() {
  late MockGetMyVehiclesUseCase mockGetVehicles;
  late MockSetMainVehicleUseCase mockSetMain;
  late MockUpdateVehicleUseCase mockUpdateVehicle;
  late VehicleCubit vehicleCubit;

  setUp(() {
    mockGetVehicles = MockGetMyVehiclesUseCase();
    mockSetMain = MockSetMainVehicleUseCase();
    mockUpdateVehicle = MockUpdateVehicleUseCase();
    final mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    when(() => mockAnalytics.setUserProperty(any(), any()))
        .thenAnswer((_) async {});
    vehicleCubit = VehicleCubit(
      mockGetVehicles,
      mockSetMain,
      mockUpdateVehicle,
      mockAnalytics,
    );
  });

  tearDown(() {
    vehicleCubit.close();
  });

  group('VehicleCubit', () {
    test('TC-veh-1: initial state is ResultState.initial', () {
      expect(vehicleCubit.state, const ResultState<List<VehicleModel>>.initial());
    });

    group('fetchMyVehicles', () {
      blocTest<VehicleCubit, ResultState<List<VehicleModel>>>(
        'TC-veh-2: emits loading then data when use case returns vehicles',
        setUp: () {
          when(() => mockGetVehicles()).thenAnswer(
            (_) async => const Right([_vehicle1, _vehicle2]),
          );
        },
        build: () => vehicleCubit,
        act: (cubit) => cubit.fetchMyVehicles(),
        expect: () => [
          const ResultState<List<VehicleModel>>.loading(),
          isA<ResultState<List<VehicleModel>>>().having(
            (state) => state,
            'data state with 2 vehicles',
            predicate<ResultState<List<VehicleModel>>>(
              (state) =>
                  state is Data<List<VehicleModel>> &&
                  state.data.length == 2,
            ),
          ),
        ],
      );

      blocTest<VehicleCubit, ResultState<List<VehicleModel>>>(
        'TC-veh-3: emits loading then error when use case fails',
        setUp: () {
          when(() => mockGetVehicles()).thenAnswer(
            (_) async => const Left(
              DomainException(message: 'Error de red'),
            ),
          );
        },
        build: () => vehicleCubit,
        act: (cubit) => cubit.fetchMyVehicles(),
        expect: () => [
          const ResultState<List<VehicleModel>>.loading(),
          predicate<ResultState<List<VehicleModel>>>(
            (state) =>
                state is Error<List<VehicleModel>> &&
                state.error.message == 'Error de red',
          ),
        ],
      );

      blocTest<VehicleCubit, ResultState<List<VehicleModel>>>(
        'TC-veh-4: emits loading then empty when use case returns empty list',
        setUp: () {
          when(() => mockGetVehicles()).thenAnswer(
            (_) async => const Right([]),
          );
        },
        build: () => vehicleCubit,
        act: (cubit) => cubit.fetchMyVehicles(),
        expect: () => [
          const ResultState<List<VehicleModel>>.loading(),
          const ResultState<List<VehicleModel>>.empty(),
        ],
      );
    });

    group('currentVehicle', () {
      test('TC-veh-5: currentVehicle returns null when no vehicles loaded', () {
        expect(vehicleCubit.currentVehicle, isNull);
      });

      test('TC-veh-6: currentVehicle returns main vehicle after fetch', () async {
        when(() => mockGetVehicles()).thenAnswer(
          (_) async => const Right([_vehicle1, _vehicle2]),
        );
        await vehicleCubit.fetchMyVehicles();
        expect(vehicleCubit.currentVehicle?.id, 'v1');
      });
    });

    group('addVehicleLocally', () {
      blocTest<VehicleCubit, ResultState<List<VehicleModel>>>(
        'TC-veh-7: emits data with new vehicle appended',
        build: () => vehicleCubit,
        act: (cubit) => cubit.addVehicleLocally(_vehicle1),
        expect: () => [
          predicate<ResultState<List<VehicleModel>>>(
            (state) =>
                state is Data<List<VehicleModel>> &&
                state.data.any((v) => v.id == 'v1'),
          ),
        ],
      );
    });

    group('selectVehicle', () {
      test('TC-veh-9: selectVehicle changes currentVehicle', () async {
        when(() => mockGetVehicles()).thenAnswer(
          (_) async => const Right([_vehicle1, _vehicle2]),
        );
        await vehicleCubit.fetchMyVehicles();
        vehicleCubit.selectVehicle(_vehicle2);
        expect(vehicleCubit.currentVehicle?.id, 'v2');
      });
    });

    group('setMainVehicle', () {
      blocTest<VehicleCubit, ResultState<List<VehicleModel>>>(
        'TC-veh-10: emits data with updated main vehicle on success',
        setUp: () {
          when(() => mockGetVehicles()).thenAnswer(
            (_) async => const Right([_vehicle1, _vehicle2]),
          );
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
        },
        build: () => vehicleCubit,
        act: (cubit) async {
          await cubit.fetchMyVehicles();
          await cubit.setMainVehicle('v2');
        },
        verify: (cubit) {
          final state = cubit.state;
          if (state is Data<List<VehicleModel>>) {
            final mainVehicle = state.data.firstWhere((v) => v.isMainVehicle);
            expect(mainVehicle.id, 'v2');
          }
        },
      );
    });

    group('clearVehicles', () {
      blocTest<VehicleCubit, ResultState<List<VehicleModel>>>(
        'TC-veh-11: emits empty after clearVehicles',
        build: () {
          vehicleCubit.addVehicleLocally(_vehicle1);
          return vehicleCubit;
        },
        act: (cubit) => cubit.clearVehicles(),
        expect: () => [const ResultState<List<VehicleModel>>.empty()],
      );
    });

    group('archiveLocally', () {
      test('TC-veh-12: marks vehicle as archived (isArchived=true)', () {
        vehicleCubit.addVehicleLocally(_vehicle1WithDate);
        vehicleCubit.addVehicleLocally(_vehicle2WithDate);
        vehicleCubit.archiveLocally('v2');
        final state = vehicleCubit.state;
        expect(state, isA<Data<List<VehicleModel>>>());
        final data = (state as Data<List<VehicleModel>>).data;
        final v2 = data.firstWhere((v) => v.id == 'v2');
        expect(v2.isArchived, isTrue);
      });

      test(
        'TC-veh-13: archiveLocally on main vehicle promotes next active',
        () {
          vehicleCubit.addVehicleLocally(_vehicle1WithDate);
          vehicleCubit.addVehicleLocally(_vehicle2WithDate);

          // v1 is main; archive it → v2 should become main
          vehicleCubit.archiveLocally('v1');

          final state = vehicleCubit.state;
          expect(state, isA<Data<List<VehicleModel>>>());
          final data = (state as Data<List<VehicleModel>>).data;
          final newMain = data.firstWhere((v) => v.isMainVehicle);
          expect(newMain.id, 'v2');
        },
      );

      test('TC-veh-14: archived vehicle has isArchived=true in full list', () {
        vehicleCubit.addVehicleLocally(_vehicle1WithDate);
        vehicleCubit.addVehicleLocally(_vehicle2WithDate);

        vehicleCubit.archiveLocally('v2');

        final state = vehicleCubit.state;
        expect(state, isA<Data<List<VehicleModel>>>());
        final data = (state as Data<List<VehicleModel>>).data;
        // v1 is still active and main
        final v1 = data.firstWhere((v) => v.id == 'v1');
        expect(v1.isMainVehicle, isTrue);
        expect(v1.isArchived, isFalse);
        // v2 is archived
        final v2 = data.firstWhere((v) => v.id == 'v2');
        expect(v2.isArchived, isTrue);
        expect(v2.isMainVehicle, isFalse);
      });
    });

    group('unarchiveLocally', () {
      test(
        'TC-veh-15: unarchiveLocally restores isArchived=false without changing main',
        () {
          vehicleCubit.addVehicleLocally(_vehicle1WithDate);
          vehicleCubit.addVehicleLocally(_vehicle2WithDate);

          // archive v2, then unarchive
          vehicleCubit.archiveLocally('v2');
          vehicleCubit.unarchiveLocally('v2');

          final state = vehicleCubit.state;
          expect(state, isA<Data<List<VehicleModel>>>());
          final data = (state as Data<List<VehicleModel>>).data;
          final v2 = data.firstWhere((v) => v.id == 'v2');
          expect(v2.isArchived, isFalse);
          // v1 remains main
          final v1 = data.firstWhere((v) => v.id == 'v1');
          expect(v1.isMainVehicle, isTrue);
        },
      );

      test(
        'TC-veh-17: unarchiveLocally promotes vehicle to main when no active main exists',
        () {
          // Arrange: solo vehículo archivado, sin principal activo
          const archivedVehicle = VehicleModel(
            id: 'v-arch',
            name: 'Moto Archivada',
            currentMileage: 0,
            isArchived: true,
            isMainVehicle: false,
          );
          vehicleCubit.addVehicleLocally(archivedVehicle);

          // Act: desarchivar cuando no hay ningún principal activo
          vehicleCubit.unarchiveLocally('v-arch');

          // Assert: el vehículo queda activo Y como principal
          final state = vehicleCubit.state;
          expect(state, isA<Data<List<VehicleModel>>>());
          final data = (state as Data<List<VehicleModel>>).data;
          final vehicle = data.firstWhere((v) => v.id == 'v-arch');
          expect(vehicle.isArchived, isFalse);
          expect(
            vehicle.isMainVehicle,
            isTrue,
            reason: 'Al desarchivar sin ningún principal activo, el vehículo debe ser promovido a principal',
          );
        },
      );
    });

    group('_promoteNewMain (via archiveLocally)', () {
      test(
        'TC-veh-16: with null createdAt dates uses id tie-break asc',
        () {
          // Both vehicles have null createdAt → tie-break by id ascending
          const vehicleA = VehicleModel(
            id: 'a1',
            name: 'Alfa',
            currentMileage: 0,
            isMainVehicle: true,
          );
          const vehicleB = VehicleModel(
            id: 'b2',
            name: 'Beta',
            currentMileage: 0,
            isMainVehicle: false,
          );
          vehicleCubit.addVehicleLocally(vehicleA);
          vehicleCubit.addVehicleLocally(vehicleB);

          // Archive main (a1) → promotion by id asc → b2 becomes main
          vehicleCubit.archiveLocally('a1');

          final state = vehicleCubit.state;
          expect(state, isA<Data<List<VehicleModel>>>());
          final data = (state as Data<List<VehicleModel>>).data;
          final newMain = data.firstWhere((v) => v.isMainVehicle);
          expect(newMain.id, 'b2');
        },
      );
    });
  });
}
