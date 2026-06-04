// Unit tests — VehicleFormCubit SOAT path state
// Covers:
//   AC-3 / AC-5 (Issue #17): soatLocalPath is null when no SOAT was attached
//   AC-4  (Issue #17): soatLocalPath is set via setSoatFromLocalPath

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/image_storage_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/add_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';

class MockAddVehicleUseCase extends Mock implements AddVehicleUseCase {}

class MockUpdateVehicleUseCase extends Mock implements UpdateVehicleUseCase {}

class MockImageStorageService extends Mock implements ImageStorageService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

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

void main() {
  group('VehicleFormCubit — soatLocalPath state', () {
    test(
      'TC-vform-soat-1: initial state has soatLocalPath == null (no SOAT attached)',
      () {
        final cubit = _buildCubit();
        expect(cubit.state.soatLocalPath, isNull);
        cubit.close();
      },
    );

    blocTest<VehicleFormCubit, VehicleFormState>(
      'TC-vform-soat-2: setSoatFromLocalPath sets soatLocalPath in state',
      build: _buildCubit,
      act: (cubit) => cubit.setSoatFromLocalPath('/tmp/soat.jpg'),
      expect: () => [
        predicate<VehicleFormState>(
          (state) => state.soatLocalPath == '/tmp/soat.jpg',
        ),
      ],
    );

    blocTest<VehicleFormCubit, VehicleFormState>(
      'TC-vform-soat-3: clearSoatDocument resets soatLocalPath to null',
      build: _buildCubit,
      act: (cubit) {
        cubit.setSoatFromLocalPath('/tmp/soat.jpg');
        cubit.clearSoatDocument();
      },
      expect: () => [
        predicate<VehicleFormState>(
          (state) => state.soatLocalPath == '/tmp/soat.jpg',
        ),
        predicate<VehicleFormState>((state) => state.soatLocalPath == null),
      ],
    );

    test(
      'TC-vform-soat-4: isEditing is false for new vehicle (soatLocalPath is only used during creation)',
      () {
        final cubit = _buildCubit();
        cubit.initialize(); // no vehicle passed
        expect(cubit.state.isEditing, isFalse);
        cubit.close();
      },
    );

    test(
      'TC-vform-soat-5: isEditing is true when a vehicle is supplied (edit flow skips SOAT redirect)',
      () {
        final cubit = _buildCubit();
        cubit.initialize(
          vehicle: const VehicleModel(
            id: 'v1',
            name: 'Honda CB500',
            currentMileage: 5000,
          ),
        );
        expect(cubit.state.isEditing, isTrue);
        cubit.close();
      },
    );
  });
}
