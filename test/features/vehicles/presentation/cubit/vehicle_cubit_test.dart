import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

class MockGetMyVehiclesUseCase extends Mock implements GetMyVehiclesUseCase {}

class MockSetMainVehicleUseCase extends Mock implements SetMainVehicleUseCase {}

class MockUpdateVehicleUseCase extends Mock implements UpdateVehicleUseCase {}

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
  late VehicleCubit vehicleCubit;

  setUp(() {
    mockGetVehicles = MockGetMyVehiclesUseCase();
    mockSetMain = MockSetMainVehicleUseCase();
    mockUpdateVehicle = MockUpdateVehicleUseCase();
    vehicleCubit = VehicleCubit(
      mockGetVehicles,
      mockSetMain,
      mockUpdateVehicle,
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

    group('deleteVehicleLocally', () {
      blocTest<VehicleCubit, ResultState<List<VehicleModel>>>(
        'TC-veh-8: emits empty when last vehicle is deleted',
        seed: () {
          // Pre-seed by calling addVehicleLocally before act
          return const ResultState<List<VehicleModel>>.initial();
        },
        build: () {
          vehicleCubit.addVehicleLocally(_vehicle1);
          return vehicleCubit;
        },
        act: (cubit) => cubit.deleteVehicleLocally('v1'),
        expect: () => [const ResultState<List<VehicleModel>>.empty()],
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
  });
}
