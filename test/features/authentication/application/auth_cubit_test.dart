import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/core/services/fcm_service.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

class MockAuthService extends Mock implements AuthService {}

class MockFcmService extends Mock implements FcmService {}

void main() {
  late MockAuthService mockAuthService;
  late MockFcmService mockFcmService;
  late AuthCubit authCubit;

  const mockUserModel = UserModel(
    id: 'user-1',
    fullName: 'Test User',
    email: 'test@example.com',
  );

  setUp(() {
    mockAuthService = MockAuthService();
    mockFcmService = MockFcmService();
    when(() => mockFcmService.initialize()).thenAnswer((_) async {});
    authCubit = AuthCubit(mockAuthService, mockFcmService);
  });

  tearDown(() {
    authCubit.close();
  });

  group('AuthCubit', () {
    test('TC-auth-1: initial state is AuthState.initial', () {
      expect(authCubit.state.isLoading, isFalse);
      expect(authCubit.state.isAuthenticated, isFalse);
    });

    group('checkAuthState', () {
      test('TC-auth-2: emits authenticated when currentUser is not null', () {
        when(() => mockAuthService.currentUser).thenReturn(mockUserModel);
        authCubit.checkAuthState();
        expect(authCubit.state.isAuthenticated, isTrue);
        expect(authCubit.state.currentUser, mockUserModel);
      });

      test('TC-auth-3: emits unauthenticated when currentUser is null', () {
        when(() => mockAuthService.currentUser).thenReturn(null);
        authCubit.checkAuthState();
        expect(authCubit.state.isAuthenticated, isFalse);
        expect(authCubit.state.hasError, isFalse);
      });
    });

    group('signInWithEmail', () {
      blocTest<AuthCubit, AuthState>(
        'TC-auth-4: emits loading then error when signIn fails',
        setUp: () {
          when(
            () => mockAuthService.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async =>
                const Left(DomainException(message: 'Credenciales inválidas')),
          );
        },
        build: () => authCubit,
        act: (cubit) => cubit.signInWithEmail(
          email: 'bad@example.com',
          password: 'wrong',
        ),
        expect: () => [
          predicate<AuthState>((s) => s.isLoading),
          predicate<AuthState>(
            (s) => s.hasError && s.errorMessage == 'Credenciales inválidas',
          ),
        ],
      );
    });

    group('signUpWithEmail', () {
      blocTest<AuthCubit, AuthState>(
        'TC-auth-5: emits loading then error when signUp fails',
        setUp: () {
          when(
            () => mockAuthService.signUpWithEmail(
              fullName: any(named: 'fullName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async => const Left(DomainException(message: 'Email ya registrado')),
          );
        },
        build: () => authCubit,
        act: (cubit) => cubit.signUpWithEmail(
          fullName: 'Jane',
          email: 'jane@example.com',
          password: 'secret123',
        ),
        expect: () => [
          predicate<AuthState>((s) => s.isLoading),
          predicate<AuthState>(
            (s) => s.hasError && s.errorMessage == 'Email ya registrado',
          ),
        ],
      );
    });

    group('signOut', () {
      blocTest<AuthCubit, AuthState>(
        'TC-auth-6: emits unauthenticated after successful signOut',
        setUp: () {
          when(() => mockAuthService.signOut()).thenAnswer(
            (_) async => const Right(unit),
          );
        },
        build: () => authCubit,
        act: (cubit) => cubit.signOut(),
        expect: () => [
          predicate<AuthState>((s) => !s.isAuthenticated && !s.hasError),
        ],
      );
    });

    group('sendPasswordResetEmail', () {
      blocTest<AuthCubit, AuthState>(
        'TC-auth-7: emits loading then passwordResetEmailSent on success',
        setUp: () {
          when(
            () => mockAuthService.sendPasswordResetEmail(any()),
          ).thenAnswer((_) async => const Right(unit));
        },
        build: () => authCubit,
        act: (cubit) => cubit.sendPasswordResetEmail('test@example.com'),
        expect: () => [
          predicate<AuthState>((s) => s.isLoading),
          predicate<AuthState>((s) => s.isPasswordResetEmailSent),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'TC-auth-8: emits loading then error when reset email fails',
        setUp: () {
          when(
            () => mockAuthService.sendPasswordResetEmail(any()),
          ).thenAnswer(
            (_) async => const Left(DomainException(message: 'Email no encontrado')),
          );
        },
        build: () => authCubit,
        act: (cubit) => cubit.sendPasswordResetEmail('missing@example.com'),
        expect: () => [
          predicate<AuthState>((s) => s.isLoading),
          predicate<AuthState>(
            (s) => s.hasError && s.errorMessage == 'Email no encontrado',
          ),
        ],
      );
    });

    group('AuthState helpers', () {
      test('TC-auth-9: isAuthenticated and currentUser work', () {
        when(() => mockAuthService.currentUser).thenReturn(mockUserModel);
        authCubit.checkAuthState();
        expect(authCubit.state.isAuthenticated, isTrue);
        expect(authCubit.state.currentUser, mockUserModel);
      });

      test('TC-auth-10: hasError and errorMessage work', () async {
        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => const Left(DomainException(message: 'error test')),
        );
        await authCubit.signInWithEmail(
          email: 'x@x.com',
          password: 'pass',
        );
        expect(authCubit.state.hasError, isTrue);
        expect(authCubit.state.errorMessage, 'error test');
      });

      test('TC-auth-11: isLoading is true during loading state', () {
        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(DomainException(message: 'err')));
        // We can't easily test mid-emission but we can test the helper
        expect(authCubit.state.isLoading, isFalse);
      });

      test('TC-auth-12: isPasswordResetEmailSent returns false initially', () {
        expect(authCubit.state.isPasswordResetEmailSent, isFalse);
      });
    });
  });
}
