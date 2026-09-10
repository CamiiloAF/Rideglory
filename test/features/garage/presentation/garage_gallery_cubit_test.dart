import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/garage/domain/models/vehicle.dart';
import 'package:rideglory/features/garage/domain/usecases/archive_vehicle_usecase.dart';
import 'package:rideglory/features/garage/domain/usecases/delete_vehicle_usecase.dart';
import 'package:rideglory/features/garage/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/garage/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/garage/domain/usecases/unarchive_vehicle_usecase.dart';
import 'package:rideglory/features/garage/presentation/cubit/garage_gallery_cubit.dart';

class _MockGetVehiclesUseCase extends Mock implements GetVehiclesUseCase {}

class _MockArchiveVehicleUseCase extends Mock
    implements ArchiveVehicleUseCase {}

class _MockUnarchiveVehicleUseCase extends Mock
    implements UnarchiveVehicleUseCase {}

class _MockSetMainVehicleUseCase extends Mock
    implements SetMainVehicleUseCase {}

class _MockDeleteVehicleUseCase extends Mock implements DeleteVehicleUseCase {}

void main() {
  late _MockGetVehiclesUseCase getVehicles;
  late _MockArchiveVehicleUseCase archiveVehicle;
  late _MockUnarchiveVehicleUseCase unarchiveVehicle;
  late _MockSetMainVehicleUseCase setMainVehicle;
  late _MockDeleteVehicleUseCase deleteVehicle;

  const vehicle = Vehicle(
    id: 'v1',
    ownerId: 'owner-1',
    name: 'Yamaha MT-03',
    brand: 'Yamaha',
    model: 'MT-03',
    currentMileage: 18450,
    isMain: true,
  );

  setUp(() {
    getVehicles = _MockGetVehiclesUseCase();
    archiveVehicle = _MockArchiveVehicleUseCase();
    unarchiveVehicle = _MockUnarchiveVehicleUseCase();
    setMainVehicle = _MockSetMainVehicleUseCase();
    deleteVehicle = _MockDeleteVehicleUseCase();
  });

  GarageGalleryCubit buildCubit() {
    return GarageGalleryCubit(
      getVehicles,
      archiveVehicle,
      unarchiveVehicle,
      setMainVehicle,
      deleteVehicle,
    );
  }

  blocTest<GarageGalleryCubit, ResultState<List<Vehicle>>>(
    'emits [loading, data] when the repository returns vehicles',
    build: () {
      when(() => getVehicles()).thenAnswer((_) async => const Right([vehicle]));
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const ResultState<List<Vehicle>>.loading(),
      const ResultState<List<Vehicle>>.data(data: [vehicle]),
    ],
  );

  blocTest<GarageGalleryCubit, ResultState<List<Vehicle>>>(
    'emits [loading, empty] when the garage has no vehicles',
    build: () {
      when(() => getVehicles()).thenAnswer((_) async => const Right([]));
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const ResultState<List<Vehicle>>.loading(),
      const ResultState<List<Vehicle>>.empty(),
    ],
  );

  blocTest<GarageGalleryCubit, ResultState<List<Vehicle>>>(
    'emits [loading, error] when the repository fails',
    build: () {
      when(
        () => getVehicles(),
      ).thenAnswer((_) async => const Left(DomainException(message: 'boom')));
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const ResultState<List<Vehicle>>.loading(),
      const ResultState<List<Vehicle>>.error(
        error: DomainException(message: 'boom'),
      ),
    ],
  );
}
