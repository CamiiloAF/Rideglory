// Unit tests for the vehicles feature use cases:
// AddVehicleUseCase, ArchiveVehicleUseCase, GetMyVehiclesUseCase,
// PermanentlyDeleteVehicleUseCase, SetMainVehicleUseCase,
// UnarchiveVehicleUseCase, UpdateVehicleUseCase.
//
// Happy path + at least one error case per use case.

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';
import 'package:rideglory/features/vehicles/domain/usecases/add_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/archive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/permanently_delete_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/unarchive_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

const _vehicle = VehicleModel(
  id: 'v1',
  name: 'Honda CB500',
  currentMileage: 5000,
);

void main() {
  late MockVehicleRepository mockRepository;

  setUp(() {
    mockRepository = MockVehicleRepository();
    registerFallbackValue(_vehicle);
  });

  group('GetMyVehiclesUseCase', () {
    test('delegates to repository.getMyVehicles and returns Right', () async {
      when(
        () => mockRepository.getMyVehicles(),
      ).thenAnswer((_) async => const Right([_vehicle]));

      final useCase = GetMyVehiclesUseCase(mockRepository);
      final result = await useCase();

      expect(result, const Right([_vehicle]));
      verify(() => mockRepository.getMyVehicles()).called(1);
    });

    test('returns Left when repository fails', () async {
      when(() => mockRepository.getMyVehicles()).thenAnswer(
        (_) async => const Left(DomainException(message: 'Error de red')),
      );

      final useCase = GetMyVehiclesUseCase(mockRepository);
      final result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'Error de red'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('AddVehicleUseCase', () {
    test('delegates to repository.addVehicle and returns Right', () async {
      when(
        () => mockRepository.addVehicle(_vehicle),
      ).thenAnswer((_) async => const Right(_vehicle));

      final useCase = AddVehicleUseCase(mockRepository);
      final result = await useCase(_vehicle);

      expect(result, const Right(_vehicle));
      verify(() => mockRepository.addVehicle(_vehicle)).called(1);
    });

    test('returns Left when repository fails', () async {
      when(() => mockRepository.addVehicle(_vehicle)).thenAnswer(
        (_) async => const Left(DomainException(message: 'No se pudo crear')),
      );

      final useCase = AddVehicleUseCase(mockRepository);
      final result = await useCase(_vehicle);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'No se pudo crear'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('UpdateVehicleUseCase', () {
    test('delegates to repository.updateVehicle and returns Right', () async {
      when(
        () => mockRepository.updateVehicle(_vehicle),
      ).thenAnswer((_) async => const Right(_vehicle));

      final useCase = UpdateVehicleUseCase(mockRepository);
      final result = await useCase(_vehicle);

      expect(result, const Right(_vehicle));
      verify(() => mockRepository.updateVehicle(_vehicle)).called(1);
    });

    test('returns Left when repository fails', () async {
      when(() => mockRepository.updateVehicle(_vehicle)).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'No se pudo actualizar')),
      );

      final useCase = UpdateVehicleUseCase(mockRepository);
      final result = await useCase(_vehicle);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'No se pudo actualizar'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('PermanentlyDeleteVehicleUseCase', () {
    test(
      'delegates to repository.permanentlyDeleteVehicle and returns Right',
      () async {
        when(
          () => mockRepository.permanentlyDeleteVehicle('v1'),
        ).thenAnswer((_) async => const Right(null));

        final useCase = PermanentlyDeleteVehicleUseCase(mockRepository);
        final result = await useCase('v1');

        expect(result.isRight(), isTrue);
        verify(
          () => mockRepository.permanentlyDeleteVehicle('v1'),
        ).called(1);
      },
    );

    test('returns Left when repository fails', () async {
      when(() => mockRepository.permanentlyDeleteVehicle('v1')).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'No se pudo eliminar')),
      );

      final useCase = PermanentlyDeleteVehicleUseCase(mockRepository);
      final result = await useCase('v1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'No se pudo eliminar'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('SetMainVehicleUseCase', () {
    test('delegates to repository.setMainVehicle and returns Right', () async {
      when(
        () => mockRepository.setMainVehicle('v1'),
      ).thenAnswer((_) async => const Right(_vehicle));

      final useCase = SetMainVehicleUseCase(mockRepository);
      final result = await useCase('v1');

      expect(result, const Right(_vehicle));
      verify(() => mockRepository.setMainVehicle('v1')).called(1);
    });

    test('returns Left when repository fails', () async {
      when(() => mockRepository.setMainVehicle('v1')).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'No se pudo asignar')),
      );

      final useCase = SetMainVehicleUseCase(mockRepository);
      final result = await useCase('v1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'No se pudo asignar'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('ArchiveVehicleUseCase', () {
    test(
      'copies isArchived=true and delegates to repository.updateVehicle',
      () async {
        VehicleModel? captured;
        when(() => mockRepository.updateVehicle(any())).thenAnswer((
          invocation,
        ) async {
          captured =
              invocation.positionalArguments.first as VehicleModel;
          return Right(captured!);
        });

        final useCase = ArchiveVehicleUseCase(mockRepository);
        final result = await useCase(_vehicle);

        expect(result.isRight(), isTrue);
        expect(captured, isNotNull);
        expect(captured!.isArchived, isTrue);
        expect(captured!.updatedAt, isNotNull);
      },
    );

    test('returns Left when repository fails', () async {
      when(() => mockRepository.updateVehicle(any())).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'No se pudo archivar')),
      );

      final useCase = ArchiveVehicleUseCase(mockRepository);
      final result = await useCase(_vehicle);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'No se pudo archivar'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('UnarchiveVehicleUseCase', () {
    test(
      'copies isArchived=false and delegates to repository.updateVehicle',
      () async {
        VehicleModel? captured;
        const archivedVehicle = VehicleModel(
          id: 'v1',
          name: 'Honda CB500',
          currentMileage: 5000,
          isArchived: true,
        );
        when(() => mockRepository.updateVehicle(any())).thenAnswer((
          invocation,
        ) async {
          captured =
              invocation.positionalArguments.first as VehicleModel;
          return Right(captured!);
        });

        final useCase = UnarchiveVehicleUseCase(mockRepository);
        final result = await useCase(archivedVehicle);

        expect(result.isRight(), isTrue);
        expect(captured, isNotNull);
        expect(captured!.isArchived, isFalse);
        expect(captured!.updatedAt, isNotNull);
      },
    );

    test('returns Left when repository fails', () async {
      when(() => mockRepository.updateVehicle(any())).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'No se pudo desarchivar')),
      );

      final useCase = UnarchiveVehicleUseCase(mockRepository);
      final result = await useCase(_vehicle);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'No se pudo desarchivar'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
