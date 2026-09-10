import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/garage/domain/repository/garage_repository.dart';
import 'package:rideglory/features/garage/domain/usecases/archive_vehicle_usecase.dart';
import 'package:rideglory/features/garage/domain/usecases/create_vehicle_usecase.dart';
import 'package:rideglory/features/garage/domain/usecases/delete_vehicle_usecase.dart';
import 'package:rideglory/features/garage/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/garage/domain/usecases/unarchive_vehicle_usecase.dart';
import 'package:rideglory/features/garage/domain/usecases/update_vehicle_usecase.dart';
import 'package:rideglory/features/garage/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/garage/presentation/cubit/vehicle_form_state.dart';

class _MockCreateVehicleUseCase extends Mock implements CreateVehicleUseCase {}

class _MockUpdateVehicleUseCase extends Mock implements UpdateVehicleUseCase {}

class _MockSetMainVehicleUseCase extends Mock
    implements SetMainVehicleUseCase {}

class _MockArchiveVehicleUseCase extends Mock
    implements ArchiveVehicleUseCase {}

class _MockUnarchiveVehicleUseCase extends Mock
    implements UnarchiveVehicleUseCase {}

class _MockDeleteVehicleUseCase extends Mock implements DeleteVehicleUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const VehicleInput(brand: 'Yamaha', model: 'MT-03', currentMileage: 0),
    );
  });

  VehicleFormCubit buildCubit() {
    return VehicleFormCubit(
      _MockCreateVehicleUseCase(),
      _MockUpdateVehicleUseCase(),
      _MockSetMainVehicleUseCase(),
      _MockArchiveVehicleUseCase(),
      _MockUnarchiveVehicleUseCase(),
      _MockDeleteVehicleUseCase(),
    );
  }

  group('plate step', () {
    blocTest<VehicleFormCubit, VehicleFormState>(
      'moves to the details step when the plate has a valid motorcycle format',
      build: buildCubit,
      act: (cubit) {
        cubit.plateChanged('abc12d');
        cubit.continueFromPlate();
      },
      expect: () => [
        isA<VehicleFormState>().having(
          (state) => state.plate,
          'plate',
          'ABC12D',
        ),
        isA<VehicleFormState>().having(
          (state) => state.step,
          'step',
          VehicleFormStep.details,
        ),
      ],
    );

    blocTest<VehicleFormCubit, VehicleFormState>(
      'flags an invalid plate format and stays on the plate step',
      build: buildCubit,
      act: (cubit) {
        cubit.plateChanged('ab123');
        cubit.continueFromPlate();
      },
      expect: () => [
        isA<VehicleFormState>().having(
          (state) => state.plate,
          'plate',
          'AB123',
        ),
        isA<VehicleFormState>().having(
          (state) => state.plateInvalid,
          'plateInvalid',
          true,
        ),
      ],
      verify: (cubit) => expect(cubit.state.step, VehicleFormStep.plate),
    );
  });
}
