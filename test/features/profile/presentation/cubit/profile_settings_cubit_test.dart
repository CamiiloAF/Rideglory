import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/profile/domain/app_preferences_repository.dart';
import 'package:rideglory/features/profile/domain/profile.dart';
import 'package:rideglory/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:rideglory/features/profile/presentation/cubit/profile_settings_cubit.dart';
import 'package:rideglory/features/profile/presentation/cubit/profile_settings_state.dart';

class _MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class _MockAppPreferencesRepository extends Mock
    implements AppPreferencesRepository {}

const _profile = Profile(id: 'u1', email: 'rider@rideglory.co');

void main() {
  late _MockGetProfileUseCase getProfile;
  late _MockAppPreferencesRepository preferences;

  setUp(() {
    getProfile = _MockGetProfileUseCase();
    preferences = _MockAppPreferencesRepository();
  });

  blocTest<ProfileSettingsCubit, ProfileSettingsState>(
    'load emits profile data and reads both preferences via Either',
    setUp: () {
      when(
        () => preferences.getNotificationsEnabled(),
      ).thenAnswer((_) async => const Right(false));
      when(
        () => preferences.getAnalyticsEnabled(),
      ).thenAnswer((_) async => const Right(true));
      when(() => getProfile()).thenAnswer((_) async => const Right(_profile));
    },
    build: () => ProfileSettingsCubit(getProfile, preferences),
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProfileSettingsState(
        profile: ResultState.loading(),
        notificationsEnabled: true,
        analyticsEnabled: true,
      ),
      const ProfileSettingsState(
        profile: ResultState.data(data: _profile),
        notificationsEnabled: false,
        analyticsEnabled: true,
      ),
    ],
  );

  blocTest<ProfileSettingsCubit, ProfileSettingsState>(
    'setNotificationsEnabled keeps previous value when repository fails',
    setUp: () {
      when(() => preferences.setNotificationsEnabled(true)).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'preferences_unavailable')),
      );
    },
    build: () => ProfileSettingsCubit(getProfile, preferences),
    act: (cubit) => cubit.setNotificationsEnabled(true),
    expect: () => const <ProfileSettingsState>[],
  );

  blocTest<ProfileSettingsCubit, ProfileSettingsState>(
    'setNotificationsEnabled updates state when repository succeeds',
    setUp: () {
      when(
        () => preferences.setNotificationsEnabled(false),
      ).thenAnswer((_) async => const Right(unit));
    },
    build: () => ProfileSettingsCubit(getProfile, preferences),
    act: (cubit) => cubit.setNotificationsEnabled(false),
    expect: () => [
      ProfileSettingsState.initial().copyWith(notificationsEnabled: false),
    ],
  );
}
