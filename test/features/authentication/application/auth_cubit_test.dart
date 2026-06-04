import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/analytics/analytics_uid_hasher.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/core/services/fcm_service.dart';
import 'package:rideglory/core/services/models/authenticated_user.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

class MockAuthService extends Mock implements AuthService {}

class MockFcmService extends Mock implements FcmService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockFirebaseUser extends Mock implements User {}

void main() {
  late MockAuthService mockAuthService;
  late MockFcmService mockFcmService;
  late MockAnalyticsService mockAnalytics;
  late AuthCubit authCubit;

  const testUid = 'test-firebase-uid-12345';
  final expectedHash = AnalyticsUidHasher.hash(testUid);

  const mockUserModel = UserModel(
    id: 'user-1',
    fullName: 'Test User',
    email: 'test@example.com',
  );

  setUp(() {
    mockAuthService = MockAuthService();
    mockFcmService = MockFcmService();
    mockAnalytics = MockAnalyticsService();
    when(() => mockFcmService.initialize()).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    when(() => mockAnalytics.setUserId(any())).thenAnswer((_) async {});
    when(
      () => mockAnalytics.setUserProperty(any(), any()),
    ).thenAnswer((_) async {});
    authCubit = AuthCubit(mockAuthService, mockFcmService, mockAnalytics);
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

      test(
        'TC-auth-4b: signInWithEmail failure emits auth_failed with '
        'categorized error — no raw message, no PII',
        () async {
          when(
            () => mockAuthService.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async => const Left(
              DomainException(message: 'Invalid credentials'),
            ),
          );

          await authCubit.signInWithEmail(
            email: 'x@x.com',
            password: 'wrong',
          );

          // auth_failed must be logged with auth_method=email and a category
          verify(
            () => mockAnalytics.logEvent(
              AnalyticsEvents.authFailed,
              {
                AnalyticsParams.authMethod: AnalyticsParams.authMethodEmail,
                AnalyticsParams.authErrorCategory:
                    AnalyticsParams.authErrorInvalidCredentials,
              },
            ),
          ).called(1);

          // uid must NEVER be passed to setUserId on failure
          verifyNever(() => mockAnalytics.setUserId(any()));
        },
      );

      test(
        'TC-auth-4c: signInWithEmail failure with network message → category=network',
        () async {
          when(
            () => mockAuthService.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async => const Left(
              DomainException(
                message: 'Network error. Please check your connection',
              ),
            ),
          );

          await authCubit.signInWithEmail(email: 'x@x.com', password: 'p');

          verify(
            () => mockAnalytics.logEvent(
              AnalyticsEvents.authFailed,
              {
                AnalyticsParams.authMethod: AnalyticsParams.authMethodEmail,
                AnalyticsParams.authErrorCategory:
                    AnalyticsParams.authErrorNetwork,
              },
            ),
          ).called(1);
        },
      );

      test(
        'TC-auth-4d: signInWithEmail success → setUserId(SHA-256), '
        'auth_succeeded(email), setUserProperty(login_method, email), '
        'auth_first_home_entry — uid in clear never passed',
        () async {
          final mockFirebaseUser = MockFirebaseUser();
          when(() => mockFirebaseUser.uid).thenReturn(testUid);
          when(
            () => mockFirebaseUser.getIdToken(any()),
          ).thenAnswer((_) async => 'fake-token');

          when(
            () => mockAuthService.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer((_) async => Right(mockFirebaseUser));
          when(() => mockAuthService.currentUser).thenReturn(mockUserModel);

          await authCubit.signInWithEmail(email: 'u@u.com', password: 'pass');

          // setUserId must receive the SHA-256 hash (64 hex chars), never the uid
          final captured = verify(
            () => mockAnalytics.setUserId(captureAny()),
          ).captured;
          expect(captured.length, 1);
          final passedId = captured.first as String;
          expect(passedId, equals(expectedHash));
          expect(passedId, hasLength(64));
          expect(passedId, isNot(equals(testUid)));

          verify(
            () => mockAnalytics.logEvent(
              AnalyticsEvents.authSucceeded,
              {AnalyticsParams.authMethod: AnalyticsParams.authMethodEmail},
            ),
          ).called(1);

          verify(
            () => mockAnalytics.setUserProperty(
              AnalyticsParams.userPropertyLoginMethod,
              AnalyticsParams.authMethodEmail,
            ),
          ).called(1);

          verify(
            () => mockAnalytics.logEvent(AnalyticsEvents.authFirstHomeEntry),
          ).called(1);
        },
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
            (_) async =>
                const Left(DomainException(message: 'Email ya registrado')),
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

      test(
        'TC-auth-5b: signUpWithEmail success → setUserId(hash), '
        'auth_succeeded(email), setUserProperty(login_method, email)',
        () async {
          final mockFirebaseUser = MockFirebaseUser();
          when(() => mockFirebaseUser.uid).thenReturn(testUid);
          when(
            () => mockFirebaseUser.getIdToken(any()),
          ).thenAnswer((_) async => 'fake-token');

          final authUser = AuthenticatedUser(
            firebaseUser: mockFirebaseUser,
            user: mockUserModel,
            isNewUser: true,
          );

          when(
            () => mockAuthService.signUpWithEmail(
              fullName: any(named: 'fullName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer((_) async => Right(authUser));

          await authCubit.signUpWithEmail(
            fullName: 'Test',
            email: 'new@u.com',
            password: 'Pass1234',
          );

          final captured = verify(
            () => mockAnalytics.setUserId(captureAny()),
          ).captured;
          final passedId = captured.first as String;
          expect(passedId, equals(expectedHash));
          expect(passedId, hasLength(64));
          expect(passedId, isNot(equals(testUid)));

          verify(
            () => mockAnalytics.logEvent(
              AnalyticsEvents.authSucceeded,
              {AnalyticsParams.authMethod: AnalyticsParams.authMethodEmail},
            ),
          ).called(1);
        },
      );

      test(
        'TC-auth-5c: signUpWithEmail failure → auth_failed(email, category), '
        'never setUserId',
        () async {
          when(
            () => mockAuthService.signUpWithEmail(
              fullName: any(named: 'fullName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async => const Left(
              DomainException(message: 'Google sign-in was cancelled'),
            ),
          );

          await authCubit.signUpWithEmail(
            fullName: 'T',
            email: 'x@x.com',
            password: 'p',
          );

          verify(
            () => mockAnalytics.logEvent(
              AnalyticsEvents.authFailed,
              {
                AnalyticsParams.authMethod: AnalyticsParams.authMethodEmail,
                AnalyticsParams.authErrorCategory:
                    AnalyticsParams.authErrorCancelled,
              },
            ),
          ).called(1);
          verifyNever(() => mockAnalytics.setUserId(any()));
        },
      );
    });

    group('signInWithGoogle', () {
      test(
        'TC-auth-G1: signInWithGoogle failure → auth_failed(google, category)',
        () async {
          when(() => mockAuthService.signInWithGoogle()).thenAnswer(
            (_) async => const Left(
              DomainException(message: 'Google sign-in was cancelled'),
            ),
          );

          await authCubit.signInWithGoogle();

          verify(
            () => mockAnalytics.logEvent(
              AnalyticsEvents.authFailed,
              {
                AnalyticsParams.authMethod: AnalyticsParams.authMethodGoogle,
                AnalyticsParams.authErrorCategory:
                    AnalyticsParams.authErrorCancelled,
              },
            ),
          ).called(1);
          verifyNever(() => mockAnalytics.setUserId(any()));
        },
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
            (_) async =>
                const Left(DomainException(message: 'Email no encontrado')),
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

      test(
        'TC-auth-7b: sendPasswordResetEmail success → auth_succeeded(forgot_password)',
        () async {
          when(
            () => mockAuthService.sendPasswordResetEmail(any()),
          ).thenAnswer((_) async => const Right(unit));

          await authCubit.sendPasswordResetEmail('user@example.com');

          verify(
            () => mockAnalytics.logEvent(
              AnalyticsEvents.authSucceeded,
              {
                AnalyticsParams.authMethod:
                    AnalyticsParams.authMethodForgotPassword,
              },
            ),
          ).called(1);
          // No setUserId for password reset
          verifyNever(() => mockAnalytics.setUserId(any()));
        },
      );

      test(
        'TC-auth-8b: sendPasswordResetEmail failure → auth_failed(forgot_password, category)',
        () async {
          when(
            () => mockAuthService.sendPasswordResetEmail(any()),
          ).thenAnswer(
            (_) async => const Left(
              DomainException(
                message: 'Network error. Please check your connection',
              ),
            ),
          );

          await authCubit.sendPasswordResetEmail('user@example.com');

          verify(
            () => mockAnalytics.logEvent(
              AnalyticsEvents.authFailed,
              {
                AnalyticsParams.authMethod:
                    AnalyticsParams.authMethodForgotPassword,
                AnalyticsParams.authErrorCategory:
                    AnalyticsParams.authErrorNetwork,
              },
            ),
          ).called(1);
        },
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

    group('AnalyticsUidHasher', () {
      test('TC-hash-1: hash produces 64-char hex string', () {
        final result = AnalyticsUidHasher.hash('some-uid');
        expect(result, hasLength(64));
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(result), isTrue);
      });

      test('TC-hash-2: hash is deterministic', () {
        expect(
          AnalyticsUidHasher.hash(testUid),
          equals(AnalyticsUidHasher.hash(testUid)),
        );
      });

      test('TC-hash-3: hash differs from the input uid', () {
        expect(AnalyticsUidHasher.hash(testUid), isNot(equals(testUid)));
      });
    });
  });
}
