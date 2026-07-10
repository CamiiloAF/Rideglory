import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rideglory/core/config/api_remote_config.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/splash/domain/use_cases/load_current_user_use_case.dart';
import 'package:rideglory/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLoadCurrentUserUseCase extends Mock
    implements LoadCurrentUserUseCase {}

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLoadCurrentUserUseCase mockUseCase;
  late MockFirebaseRemoteConfig mockRemoteConfig;

  const user = UserModel(
    id: 'u1',
    email: 'rider@rideglory.com',
    fullName: 'Rider',
  );

  setUp(() async {
    // Marca el permiso de ubicación como ya solicitado para que
    // `requestOnceOnFirstSplashOpen` no intente llamar al canal de
    // permission_handler (no mockeado) durante el test.
    SharedPreferences.setMockInitialValues({
      'asked_location_permission_on_splash': true,
    });

    PackageInfo.setMockInitialValues(
      appName: 'Rideglory',
      packageName: 'com.rideglory.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    mockUseCase = MockLoadCurrentUserUseCase();
    mockRemoteConfig = MockFirebaseRemoteConfig();
    when(
      () => mockRemoteConfig.getString(ApiRemoteConfig.minRequiredVersionKey),
    ).thenReturn('');
  });

  SplashCubit buildCubit() => SplashCubit(mockUseCase, mockRemoteConfig);

  group('SplashCubit — camino feliz', () {
    blocTest<SplashCubit, SplashState>(
      'usuario cargado → SplashLoading seguido de SplashAuthenticated',
      setUp: () {
        when(
          () => mockUseCase(),
        ).thenAnswer((_) async => const Right(user));
      },
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      wait: const Duration(milliseconds: 1600),
      expect: () => [isA<SplashLoading>(), isA<SplashAuthenticated>()],
    );
  });

  group('SplashCubit — sin sesión', () {
    blocTest<SplashCubit, SplashState>(
      'sin usuario (Right(null)) → SplashLoading seguido de SplashUnauthenticated',
      setUp: () {
        when(
          () => mockUseCase(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      wait: const Duration(milliseconds: 1600),
      expect: () => [isA<SplashLoading>(), isA<SplashUnauthenticated>()],
    );
  });

  group('SplashCubit — error al cargar usuario', () {
    blocTest<SplashCubit, SplashState>(
      'use case retorna Left → SplashLoading seguido de SplashError con el mensaje',
      setUp: () {
        when(() => mockUseCase()).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'No se pudo cargar')),
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      wait: const Duration(milliseconds: 1600),
      expect: () => [
        isA<SplashLoading>(),
        predicate<SplashState>(
          (state) => state is SplashError && state.message == 'No se pudo cargar',
        ),
      ],
    );
  });

  group('SplashCubit — chequeo de force update', () {
    blocTest<SplashCubit, SplashState>(
      'versión instalada por debajo del mínimo requerido → SplashForceUpdate '
      'y no consulta al usuario actual',
      setUp: () {
        when(
          () => mockRemoteConfig.getString(
            ApiRemoteConfig.minRequiredVersionKey,
          ),
        ).thenReturn('2.0.0');
      },
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      wait: const Duration(milliseconds: 1600),
      expect: () => [isA<SplashLoading>(), isA<SplashForceUpdate>()],
      verify: (_) {
        verifyNever(() => mockUseCase());
      },
    );

    blocTest<SplashCubit, SplashState>(
      'versión instalada igual al mínimo requerido → no fuerza actualización',
      setUp: () {
        when(
          () => mockRemoteConfig.getString(
            ApiRemoteConfig.minRequiredVersionKey,
          ),
        ).thenReturn('1.0.0');
        when(
          () => mockUseCase(),
        ).thenAnswer((_) async => const Right(user));
      },
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      wait: const Duration(milliseconds: 1600),
      expect: () => [isA<SplashLoading>(), isA<SplashAuthenticated>()],
    );
  });

  group('SplashCubit — excepción inesperada', () {
    blocTest<SplashCubit, SplashState>(
      'el use case lanza una excepción → SplashLoading seguido de SplashError',
      setUp: () {
        when(() => mockUseCase()).thenThrow(Exception('boom'));
      },
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      wait: const Duration(milliseconds: 1600),
      expect: () => [
        isA<SplashLoading>(),
        predicate<SplashState>(
          (state) => state is SplashError && state.message.contains('boom'),
        ),
      ],
    );
  });
}
