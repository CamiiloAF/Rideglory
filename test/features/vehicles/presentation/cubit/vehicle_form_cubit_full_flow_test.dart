// Unit / widget tests — VehicleFormCubit full create/edit flow.
// Complements vehicle_form_cubit_soat_test.dart (which only covers the
// soatLocalPath slice). Covers:
//   - buildVehicleToSave(): specs, license plate, VIN, optional fields,
//     auto-unarchive when editing an archived vehicle.
//   - saveVehicle(): create/edit, image upload, error path.
//   - pendingManualSoat / pendingRtm storage (PendingRtm per
//     docs/features/vehicles.md §4 update).
//   - techReview document local path handling.
//   - reset().

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/image_storage_service.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/add_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';

class MockAddVehicleUseCase extends Mock implements AddVehicleUseCase {}

class MockUpdateVehicleUseCase extends Mock implements UpdateVehicleUseCase {}

class MockImageStorageService extends Mock implements ImageStorageService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeXFile extends Fake implements XFile {
  FakeXFile(this._path);
  final String _path;

  @override
  String get path => _path;
}

VehicleFormCubit _buildCubit({
  MockAddVehicleUseCase? addUseCase,
  MockUpdateVehicleUseCase? updateUseCase,
  MockImageStorageService? imageService,
}) {
  final mockAnalytics = MockAnalyticsService();
  when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
  when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
  return VehicleFormCubit(
    addUseCase ?? MockAddVehicleUseCase(),
    updateUseCase ?? MockUpdateVehicleUseCase(),
    imageService ?? MockImageStorageService(),
    mockAnalytics,
  );
}

/// Minimal [FormBuilder] wiring the form fields consumed by
/// [VehicleFormCubit.buildVehicleToSave], without pulling in the full
/// vehicle form widget tree (which requires additional DI-heavy cubits).
Widget _buildFormHost(
  GlobalKey<FormBuilderState> formKey,
  Map<String, dynamic> initialValue,
) {
  return MaterialApp(
    home: Scaffold(
      body: FormBuilder(
        key: formKey,
        initialValue: initialValue,
        child: Column(
          children: [
            FormBuilderTextField(name: VehicleFormFields.name),
            FormBuilderTextField(name: VehicleFormFields.brand),
            FormBuilderTextField(name: VehicleFormFields.model),
            FormBuilderTextField(name: VehicleFormFields.year),
            FormBuilderTextField(name: VehicleFormFields.currentMileage),
            FormBuilderTextField(name: VehicleFormFields.licensePlate),
            FormBuilderTextField(name: VehicleFormFields.vin),
            FormBuilderTextField(name: VehicleFormFields.color),
            FormBuilderTextField(name: VehicleFormFields.engine),
            FormBuilderTextField(name: VehicleFormFields.horsepower),
            FormBuilderTextField(name: VehicleFormFields.torque),
            FormBuilderTextField(name: VehicleFormFields.weight),
          ],
        ),
      ),
    ),
  );
}

const _fullFormValues = {
  VehicleFormFields.name: 'Honda CB500',
  VehicleFormFields.brand: 'Honda',
  VehicleFormFields.model: 'CB500',
  VehicleFormFields.year: '2020',
  VehicleFormFields.currentMileage: '15000',
  VehicleFormFields.licensePlate: 'ABC123',
  VehicleFormFields.vin: 'VIN000111',
  VehicleFormFields.color: 'Rojo',
  VehicleFormFields.engine: '500cc',
  VehicleFormFields.horsepower: '50hp',
  VehicleFormFields.torque: '40nm',
  VehicleFormFields.weight: '180kg',
};

const _emptyOptionalFormValues = {
  VehicleFormFields.name: 'Yamaha MT-07',
  VehicleFormFields.brand: 'Yamaha',
  VehicleFormFields.model: 'MT-07',
  VehicleFormFields.year: '2021',
  VehicleFormFields.currentMileage: '',
  VehicleFormFields.licensePlate: '',
  VehicleFormFields.vin: '',
  VehicleFormFields.color: '',
  VehicleFormFields.engine: '',
  VehicleFormFields.horsepower: '',
  VehicleFormFields.torque: '',
  VehicleFormFields.weight: '',
};

void main() {
  setUpAll(() {
    registerFallbackValue(
      const VehicleModel(name: 'fallback', currentMileage: 0),
    );
    registerFallbackValue(FakeXFile('/tmp/fallback.jpg'));
  });

  group('VehicleFormCubit — buildVehicleToSave', () {
    testWidgets(
      'TC-vform-1: builds a VehicleModel with specs, license plate and VIN filled in create mode',
      (tester) async {
        final cubit = _buildCubit();
        addTearDown(cubit.close);
        cubit.initialize();

        await tester.pumpWidget(_buildFormHost(cubit.formKey, _fullFormValues));
        await tester.pumpAndSettle();

        final vehicle = cubit.buildVehicleToSave();

        expect(vehicle, isNotNull);
        expect(vehicle!.id, isNull);
        expect(vehicle.name, 'Honda CB500');
        expect(vehicle.brand, 'Honda');
        expect(vehicle.model, 'CB500');
        expect(vehicle.year, 2020);
        expect(vehicle.currentMileage, 15000);
        expect(vehicle.licensePlate, 'ABC123');
        expect(vehicle.vin, 'VIN000111');
        expect(vehicle.color, 'Rojo');
        expect(vehicle.engine, '500cc');
        expect(vehicle.horsepower, '50hp');
        expect(vehicle.torque, '40nm');
        expect(vehicle.weight, '180kg');
        expect(vehicle.isArchived, isFalse);
        expect(vehicle.isMainVehicle, isFalse);
      },
    );

    testWidgets(
      'TC-vform-2: empty optional fields (plate, VIN, specs) become null',
      (tester) async {
        final cubit = _buildCubit();
        addTearDown(cubit.close);
        cubit.initialize();

        await tester.pumpWidget(
          _buildFormHost(cubit.formKey, _emptyOptionalFormValues),
        );
        await tester.pumpAndSettle();

        final vehicle = cubit.buildVehicleToSave();

        expect(vehicle, isNotNull);
        expect(vehicle!.currentMileage, 0);
        expect(vehicle.licensePlate, isNull);
        expect(vehicle.vin, isNull);
        expect(vehicle.color, isNull);
        expect(vehicle.engine, isNull);
        expect(vehicle.horsepower, isNull);
        expect(vehicle.torque, isNull);
        expect(vehicle.weight, isNull);
      },
    );

    testWidgets(
      'TC-vform-3: editing an archived vehicle auto-unarchives on save (isArchived=false)',
      (tester) async {
        final cubit = _buildCubit();
        addTearDown(cubit.close);
        const archivedVehicle = VehicleModel(
          id: 'v1',
          name: 'Honda CB500',
          currentMileage: 15000,
          isArchived: true,
          isMainVehicle: true,
        );
        cubit.initialize(vehicle: archivedVehicle);

        await tester.pumpWidget(_buildFormHost(cubit.formKey, _fullFormValues));
        await tester.pumpAndSettle();

        final vehicle = cubit.buildVehicleToSave();

        expect(vehicle, isNotNull);
        expect(vehicle!.id, 'v1');
        expect(vehicle.isArchived, isFalse);
        expect(vehicle.isMainVehicle, isTrue);
      },
    );
  });

  group('VehicleFormCubit — saveVehicle', () {
    const newVehicle = VehicleModel(name: 'Kawasaki Z900', currentMileage: 0);

    blocTest<VehicleFormCubit, VehicleFormState>(
      'TC-vform-4: create flow uploads the image and emits data with the saved vehicle',
      build: () {
        final imageService = MockImageStorageService();
        when(
          () => imageService.uploadImage(
            image: any(named: 'image'),
            storagePath: any(named: 'storagePath'),
          ),
        ).thenAnswer((_) async => 'https://example.com/cover.jpg');

        final addUseCase = MockAddVehicleUseCase();
        when(() => addUseCase(any())).thenAnswer(
          (invocation) async => Right(
            invocation.positionalArguments.first as VehicleModel,
          ),
        );

        return _buildCubit(addUseCase: addUseCase, imageService: imageService);
      },
      act: (cubit) =>
          cubit.saveVehicle(newVehicle, localImagePath: '/tmp/cover.jpg'),
      expect: () => [
        predicate<VehicleFormState>(
          (state) => state.vehicleResult is Loading<VehicleModel>,
        ),
        predicate<VehicleFormState>(
          (state) =>
              state.vehicleResult is Data<VehicleModel> &&
              (state.vehicleResult as Data<VehicleModel>).data.imageUrl ==
                  'https://example.com/cover.jpg',
        ),
      ],
    );

    blocTest<VehicleFormCubit, VehicleFormState>(
      'TC-vform-5: edit flow without a new local image keeps the existing remote imageUrl',
      build: () {
        final updateUseCase = MockUpdateVehicleUseCase();
        when(() => updateUseCase(any())).thenAnswer(
          (invocation) async => Right(
            invocation.positionalArguments.first as VehicleModel,
          ),
        );
        final cubit = _buildCubit(updateUseCase: updateUseCase);
        cubit.initialize(
          vehicle: const VehicleModel(
            id: 'v1',
            name: 'Honda CB500',
            currentMileage: 15000,
            imageUrl: 'https://example.com/existing.jpg',
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.saveVehicle(
        const VehicleModel(id: 'v1', name: 'Honda CB500', currentMileage: 16000),
      ),
      skip: 1,
      expect: () => [
        predicate<VehicleFormState>(
          (state) =>
              state.vehicleResult is Data<VehicleModel> &&
              (state.vehicleResult as Data<VehicleModel>).data.imageUrl ==
                  'https://example.com/existing.jpg',
        ),
      ],
    );

    blocTest<VehicleFormCubit, VehicleFormState>(
      'TC-vform-6: create flow emits error when the use case fails',
      build: () {
        final addUseCase = MockAddVehicleUseCase();
        when(() => addUseCase(any())).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'No se pudo crear')),
        );
        return _buildCubit(addUseCase: addUseCase);
      },
      act: (cubit) => cubit.saveVehicle(newVehicle),
      expect: () => [
        predicate<VehicleFormState>(
          (state) => state.vehicleResult is Loading<VehicleModel>,
        ),
        predicate<VehicleFormState>(
          (state) =>
              state.vehicleResult is Error<VehicleModel> &&
              (state.vehicleResult as Error<VehicleModel>).error.message ==
                  'No se pudo crear',
        ),
      ],
    );

    blocTest<VehicleFormCubit, VehicleFormState>(
      'TC-vform-7: create flow surfaces an image upload failure as an error state',
      build: () {
        final imageService = MockImageStorageService();
        when(
          () => imageService.uploadImage(
            image: any(named: 'image'),
            storagePath: any(named: 'storagePath'),
          ),
        ).thenThrow(
          const DomainException(message: 'No se pudo subir la imagen'),
        );
        return _buildCubit(imageService: imageService);
      },
      act: (cubit) =>
          cubit.saveVehicle(newVehicle, localImagePath: '/tmp/cover.jpg'),
      expect: () => [
        predicate<VehicleFormState>(
          (state) => state.vehicleResult is Loading<VehicleModel>,
        ),
        predicate<VehicleFormState>(
          (state) =>
              state.vehicleResult is Error<VehicleModel> &&
              (state.vehicleResult as Error<VehicleModel>).error.message ==
                  'No se pudo subir la imagen',
        ),
      ],
    );
  });

  group('VehicleFormCubit — pending SOAT / RTM / tech review', () {
    blocTest<VehicleFormCubit, VehicleFormState>(
      'TC-vform-8: storePendingManualSoat / clearPendingManualSoat',
      build: _buildCubit,
      act: (cubit) {
        cubit.storePendingManualSoat(
          PendingManualSoat(
            insurer: 'Sura',
            startDate: DateTime(2026, 1, 1),
            expiryDate: DateTime(2027, 1, 1),
          ),
        );
        cubit.clearPendingManualSoat();
      },
      expect: () => [
        predicate<VehicleFormState>(
          (state) => state.pendingManualSoat?.insurer == 'Sura',
        ),
        predicate<VehicleFormState>((state) => state.pendingManualSoat == null),
      ],
    );

    blocTest<VehicleFormCubit, VehicleFormState>(
      'TC-vform-9: storePendingRtm / clearPendingRtm',
      build: _buildCubit,
      act: (cubit) {
        cubit.storePendingRtm(
          PendingRtm(
            cdaName: 'CDA Bogotá',
            startDate: DateTime(2026, 1, 1),
            expiryDate: DateTime(2027, 1, 1),
          ),
        );
        cubit.clearPendingRtm();
      },
      expect: () => [
        predicate<VehicleFormState>(
          (state) => state.pendingRtm?.cdaName == 'CDA Bogotá',
        ),
        predicate<VehicleFormState>((state) => state.pendingRtm == null),
      ],
    );

    blocTest<VehicleFormCubit, VehicleFormState>(
      'TC-vform-10: pickTechReviewDocument sets techReviewLocalPath from the picker',
      build: () {
        final imageService = MockImageStorageService();
        when(
          () => imageService.pickImageFromGallery(),
        ).thenAnswer((_) async => FakeXFile('/tmp/rtm.jpg'));
        return _buildCubit(imageService: imageService);
      },
      act: (cubit) => cubit.pickTechReviewDocument(),
      expect: () => [
        predicate<VehicleFormState>(
          (state) => state.techReviewLocalPath == '/tmp/rtm.jpg',
        ),
      ],
    );

    blocTest<VehicleFormCubit, VehicleFormState>(
      'TC-vform-11: clearTechReviewDocument resets techReviewLocalPath to null',
      build: () {
        final imageService = MockImageStorageService();
        when(
          () => imageService.pickImageFromGallery(),
        ).thenAnswer((_) async => FakeXFile('/tmp/rtm.jpg'));
        return _buildCubit(imageService: imageService);
      },
      act: (cubit) async {
        await cubit.pickTechReviewDocument();
        cubit.clearTechReviewDocument();
      },
      skip: 1,
      expect: () => [
        predicate<VehicleFormState>((state) => state.techReviewLocalPath == null),
      ],
    );
  });

  group('VehicleFormCubit — reset', () {
    blocTest<VehicleFormCubit, VehicleFormState>(
      'TC-vform-12: reset clears vehicleResult, vehicle and localImagePath',
      build: _buildCubit,
      seed: () => VehicleFormState(
        vehicleResult: const ResultState.data(
          data: VehicleModel(id: 'v1', name: 'Honda', currentMileage: 100),
        ),
        vehicle: const VehicleModel(id: 'v1', name: 'Honda', currentMileage: 100),
        localImagePath: '/tmp/cover.jpg',
      ),
      act: (cubit) => cubit.reset(),
      expect: () => [
        predicate<VehicleFormState>(
          (state) =>
              state.vehicleResult is Initial<VehicleModel> &&
              state.vehicle == null &&
              state.localImagePath == null,
        ),
      ],
    );
  });
}
