import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/profile/domain/profile.dart';
import 'package:rideglory/features/profile/domain/profile_error_code.dart';
import 'package:rideglory/features/profile/domain/rider_vehicle_preview.dart';
import 'package:rideglory/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:rideglory/features/profile/domain/usecases/get_rider_vehicle_previews_usecase.dart';
import 'package:rideglory/features/profile/presentation/cubit/profile_overview_cubit.dart';
import 'package:rideglory/features/profile/presentation/cubit/profile_overview_state.dart';

class _MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class _MockGetRiderVehiclePreviewsUseCase extends Mock
    implements GetRiderVehiclePreviewsUseCase {}

void main() {
  late _MockGetProfileUseCase getProfile;
  late _MockGetRiderVehiclePreviewsUseCase getVehicles;

  const profile = Profile(
    id: 'u1',
    email: 'qa1@gmail.com',
    fullName: 'QA Rider',
  );

  setUp(() {
    getProfile = _MockGetProfileUseCase();
    getVehicles = _MockGetRiderVehiclePreviewsUseCase();
  });

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'loads profile and vehicles independently: one can fail while the other succeeds',
    setUp: () {
      when(() => getProfile()).thenAnswer((_) async => const Right(profile));
      when(() => getVehicles()).thenAnswer(
        (_) async =>
            const Left(DomainException(message: ProfileErrorCode.unknown)),
      );
    },
    build: () => ProfileOverviewCubit(getProfile, getVehicles),
    act: (cubit) => cubit.load(),
    expect: () => const [
      ProfileOverviewState(
        profile: ResultState.loading(),
        vehicles: ResultState.loading(),
      ),
      ProfileOverviewState(
        profile: ResultState.data(data: profile),
        vehicles: ResultState.loading(),
      ),
      ProfileOverviewState(
        profile: ResultState.data(data: profile),
        vehicles: ResultState.error(
          error: DomainException(message: ProfileErrorCode.unknown),
        ),
      ),
    ],
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'emits empty vehicles when the garage has no motorcycles',
    setUp: () {
      when(() => getProfile()).thenAnswer((_) async => const Right(profile));
      when(
        () => getVehicles(),
      ).thenAnswer((_) async => const Right(<RiderVehiclePreview>[]));
    },
    build: () => ProfileOverviewCubit(getProfile, getVehicles),
    act: (cubit) => cubit.load(),
    skip: 1,
    expect: () => const [
      ProfileOverviewState(
        profile: ResultState.data(data: profile),
        vehicles: ResultState.loading(),
      ),
      ProfileOverviewState(
        profile: ResultState.data(data: profile),
        vehicles: ResultState.empty(),
      ),
    ],
  );
}
