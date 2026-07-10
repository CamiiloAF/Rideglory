// Unit tests for VehicleRepositoryImpl.
// Covers: getMyVehicles, setMainVehicle, addVehicle, updateVehicle,
// permanentlyDeleteVehicle, uploadVehicleImage (Firebase Storage upload,
// mocked — never hits real Firebase), upsertSoat, getSoat.
// Happy path + at least one error case per method.

import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/data/dto/soat_dto.dart';
import 'package:rideglory/features/vehicles/data/dto/vehicle_dto.dart';
import 'package:rideglory/features/vehicles/data/repository/vehicle_repository_impl.dart';
import 'package:rideglory/features/vehicles/data/service/vehicle_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_soat_form_data.dart';

class MockVehicleService extends Mock implements VehicleService {}

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockReference extends Mock implements Reference {}

class MockTaskSnapshot extends Mock implements TaskSnapshot {}

/// [UploadTask] implements `Future<TaskSnapshot>` via `then`. Its real
/// constructors are private, so we hand-roll a [Fake] that satisfies the
/// `await` protocol by delegating to a real [Future].
class FakeUploadTask extends Fake implements UploadTask {
  FakeUploadTask(this._snapshot);

  final TaskSnapshot _snapshot;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(TaskSnapshot value) onValue, {
    Function? onError,
  }) {
    return Future.value(_snapshot).then(onValue, onError: onError);
  }
}

const _vehicle = VehicleDto(id: 'v1', name: 'Honda CB500', currentMileage: 5000);

final _soatFormData = VehicleSoatFormData(
  vehicleId: 'v1',
  insurer: 'Sura',
  startDate: DateTime(2026, 1, 1),
  expiryDate: DateTime(2027, 1, 1),
);

void main() {
  late MockVehicleService mockService;
  late MockFirebaseStorage mockStorage;
  late VehicleRepositoryImpl repository;

  setUp(() {
    mockService = MockVehicleService();
    mockStorage = MockFirebaseStorage();
    repository = VehicleRepositoryImpl(mockService, mockStorage);
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(File('/tmp/fallback.jpg'));
  });

  group('getMyVehicles', () {
    test('returns Right with the list of vehicles on success', () async {
      when(
        () => mockService.getMyVehicles(),
      ).thenAnswer((_) async => [_vehicle]);

      final result = await repository.getMyVehicles();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (vehicles) => expect(vehicles.single.id, 'v1'),
      );
    });

    test('returns Left when the service throws', () async {
      when(() => mockService.getMyVehicles()).thenThrow(Exception('boom'));

      final result = await repository.getMyVehicles();

      expect(result.isLeft(), isTrue);
    });
  });

  group('setMainVehicle', () {
    test('returns Right with the updated vehicle on success', () async {
      when(
        () => mockService.setMyMainVehicle('v1'),
      ).thenAnswer((_) async => _vehicle);

      final result = await repository.setMainVehicle('v1');

      expect(result, isA<Right<DomainException, VehicleModel>>());
    });

    test('returns Left when the service throws', () async {
      when(
        () => mockService.setMyMainVehicle('v1'),
      ).thenThrow(Exception('boom'));

      final result = await repository.setMainVehicle('v1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('addVehicle', () {
    const vehicleToAdd = VehicleModel(
      name: 'Yamaha MT-07',
      currentMileage: 0,
      brand: 'Yamaha',
    );

    test('builds request body and returns Right on success', () async {
      Map<String, dynamic>? capturedBody;
      when(() => mockService.createMyVehicle(any())).thenAnswer((
        invocation,
      ) async {
        capturedBody =
            invocation.positionalArguments.first as Map<String, dynamic>;
        return _vehicle;
      });

      final result = await repository.addVehicle(vehicleToAdd);

      expect(result.isRight(), isTrue);
      expect(capturedBody, isNotNull);
      expect(capturedBody!['name'], 'Yamaha MT-07');
      expect(capturedBody!['brand'], 'Yamaha');
      // null fields are removed from the request body.
      expect(capturedBody!.containsKey('licensePlate'), isFalse);
      expect(capturedBody!.containsKey('color'), isFalse);
      expect(capturedBody!.containsKey('isMainVehicle'), isFalse);
    });

    test('returns Left when the service throws', () async {
      when(() => mockService.createMyVehicle(any())).thenThrow(
        Exception('boom'),
      );

      final result = await repository.addVehicle(vehicleToAdd);

      expect(result.isLeft(), isTrue);
    });
  });

  group('updateVehicle', () {
    const vehicleToUpdate = VehicleModel(
      id: 'v1',
      name: 'Honda CB500',
      currentMileage: 6000,
    );

    test('delegates to service.updateVehicle and returns Right', () async {
      when(
        () => mockService.updateVehicle('v1', any()),
      ).thenAnswer((_) async => _vehicle);

      final result = await repository.updateVehicle(vehicleToUpdate);

      expect(result.isRight(), isTrue);
      verify(() => mockService.updateVehicle('v1', any())).called(1);
    });

    test('throws (wrapped) when vehicle id is null', () async {
      const vehicleWithoutId = VehicleModel(
        name: 'Sin id',
        currentMileage: 0,
      );

      expect(
        () => repository.updateVehicle(vehicleWithoutId),
        throwsA(isA<DomainException>()),
      );
    });

    test('returns Left when the service throws', () async {
      when(
        () => mockService.updateVehicle('v1', any()),
      ).thenThrow(Exception('boom'));

      final result = await repository.updateVehicle(vehicleToUpdate);

      expect(result.isLeft(), isTrue);
    });
  });

  group('permanentlyDeleteVehicle', () {
    test('returns Right(null) on success', () async {
      when(
        () => mockService.permanentlyDeleteVehicle('v1'),
      ).thenAnswer((_) async {});

      final result = await repository.permanentlyDeleteVehicle('v1');

      expect(result.isRight(), isTrue);
      verify(() => mockService.permanentlyDeleteVehicle('v1')).called(1);
    });

    test('returns Left when the service throws', () async {
      when(
        () => mockService.permanentlyDeleteVehicle('v1'),
      ).thenThrow(Exception('boom'));

      final result = await repository.permanentlyDeleteVehicle('v1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('uploadVehicleImage', () {
    test('uploads the file and returns Right with the download URL', () async {
      final rootRef = MockReference();
      final childRef = MockReference();
      final snapshot = MockTaskSnapshot();

      when(() => mockStorage.ref()).thenReturn(rootRef);
      when(
        () => rootRef.child('vehicles/v1/cover.jpg'),
      ).thenReturn(childRef);
      when(
        () => childRef.putFile(any()),
      ).thenAnswer((_) => FakeUploadTask(snapshot));
      when(() => snapshot.ref).thenReturn(childRef);
      when(
        () => childRef.getDownloadURL(),
      ).thenAnswer((_) async => 'https://example.com/cover.jpg');

      final result = await repository.uploadVehicleImage(
        vehicleId: 'v1',
        localImagePath: '/tmp/cover.jpg',
      );

      expect(result, const Right<DomainException, String>(
        'https://example.com/cover.jpg',
      ));
    });

    test('returns Left when the storage call throws', () async {
      final rootRef = MockReference();
      when(() => mockStorage.ref()).thenReturn(rootRef);
      when(
        () => rootRef.child(any()),
      ).thenThrow(Exception('storage unavailable'));

      final result = await repository.uploadVehicleImage(
        vehicleId: 'v1',
        localImagePath: '/tmp/cover.jpg',
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('upsertSoat', () {
    test('sends the JSON body and returns Right with form data', () async {
      when(
        () => mockService.upsertSoat('v1', any()),
      ).thenAnswer(
        (_) async => VehicleSoatFormDataDto(
          vehicleId: 'v1',
          startDate: DateTime(2026, 1, 1).toIso8601String(),
          expiryDate: DateTime(2027, 1, 1).toIso8601String(),
          insurer: 'Sura',
        ),
      );

      final result = await repository.upsertSoat(
        vehicleId: 'v1',
        soat: _soatFormData,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (formData) => expect(formData.insurer, 'Sura'),
      );
    });

    test('returns Left when the service throws', () async {
      when(
        () => mockService.upsertSoat('v1', any()),
      ).thenThrow(Exception('boom'));

      final result = await repository.upsertSoat(
        vehicleId: 'v1',
        soat: _soatFormData,
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('getSoat', () {
    test('returns Right with form data on success', () async {
      when(() => mockService.getSoat('v1')).thenAnswer(
        (_) async => VehicleSoatFormDataDto(
          vehicleId: 'v1',
          startDate: DateTime(2026, 1, 1).toIso8601String(),
          expiryDate: DateTime(2027, 1, 1).toIso8601String(),
          insurer: 'Sura',
        ),
      );

      final result = await repository.getSoat('v1');

      expect(result.isRight(), isTrue);
    });

    test('returns Left when the service throws', () async {
      when(() => mockService.getSoat('v1')).thenThrow(Exception('boom'));

      final result = await repository.getSoat('v1');

      expect(result.isLeft(), isTrue);
    });
  });
}
