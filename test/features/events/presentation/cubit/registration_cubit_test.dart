import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/event_vehicle_option.dart';
import 'package:rideglory/features/events/domain/register_for_event_params.dart';
import 'package:rideglory/features/events/domain/usecases/get_my_vehicles_for_event_use_case.dart';
import 'package:rideglory/features/events/domain/usecases/register_for_event_use_case.dart';
import 'package:rideglory/features/events/presentation/cubit/registration_cubit.dart';
import 'package:rideglory/features/events/presentation/cubit/registration_state.dart';
import 'package:rideglory/features/profile/domain/profile.dart';
import 'package:rideglory/features/profile/domain/usecases/get_profile_usecase.dart';

class _MockGetProfile extends Mock implements GetProfileUseCase {}

class _MockGetVehicles extends Mock implements GetMyVehiclesForEventUseCase {}

class _MockRegister extends Mock implements RegisterForEventUseCase {}

void main() {
  late _MockGetProfile getProfile;
  late _MockGetVehicles getVehicles;
  late _MockRegister register;

  setUpAll(() {
    registerFallbackValue(
      const RegisterForEventParams(
        eventId: '',
        fullName: '',
        phone: '',
        emergencyContactName: '',
        emergencyContactPhone: '',
        shareMedicalInfo: false,
        allowOrganizerContact: false,
        acceptsRisk: false,
        consentVersion: 'v1.0',
      ),
    );
  });

  const completeProfile = Profile(
    id: 'u1',
    email: 'qa1@gmail.com',
    fullName: 'QA Rider Uno',
    phone: '3001112233',
    emergencyContactName: 'Contacto QA',
    emergencyContactPhone: '3009998877',
  );

  const incompleteProfile = Profile(id: 'u1', email: 'qa1@gmail.com');

  setUp(() {
    getProfile = _MockGetProfile();
    getVehicles = _MockGetVehicles();
    register = _MockRegister();
  });

  RegistrationCubit buildCubit() =>
      RegistrationCubit(getProfile, getVehicles, register);

  blocTest<RegistrationCubit, RegistrationState>(
    'load() marks the profile as incomplete when required fields are missing',
    build: () {
      when(
        () => getProfile(),
      ).thenAnswer((_) async => const Right(incompleteProfile));
      when(() => getVehicles()).thenAnswer((_) async => const Right([]));
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.isProfileComplete, isFalse);
    },
  );

  blocTest<RegistrationCubit, RegistrationState>(
    'load() marks the profile as complete and preselects the first vehicle',
    build: () {
      when(
        () => getProfile(),
      ).thenAnswer((_) async => const Right(completeProfile));
      when(() => getVehicles()).thenAnswer(
        (_) async => const Right([
          EventVehicleOption(id: 'v1', name: 'La Negra', brand: 'Yamaha'),
        ]),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.isProfileComplete, isTrue);
      expect(cubit.state.selectedVehicleId, 'v1');
    },
  );

  blocTest<RegistrationCubit, RegistrationState>(
    'submit() does nothing when risk has not been accepted',
    build: () {
      when(
        () => getProfile(),
      ).thenAnswer((_) async => const Right(completeProfile));
      when(() => getVehicles()).thenAnswer((_) async => const Right([]));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.submit('event-1');
    },
    verify: (cubit) {
      verifyNever(() => register(any()));
    },
  );

  blocTest<RegistrationCubit, RegistrationState>(
    'submit() calls the use case once risk is accepted and profile is complete',
    build: () {
      when(
        () => getProfile(),
      ).thenAnswer((_) async => const Right(completeProfile));
      when(() => getVehicles()).thenAnswer((_) async => const Right([]));
      when(() => register(any())).thenAnswer((_) async => const Right(unit));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load();
      cubit.toggleAcceptsRisk(true);
      await cubit.submit('event-1');
    },
    verify: (cubit) {
      verify(() => register(any())).called(1);
      expect(cubit.state.submission, const ResultState.data(data: unit));
    },
  );
}
