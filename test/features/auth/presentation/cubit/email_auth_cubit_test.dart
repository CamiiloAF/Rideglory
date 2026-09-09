import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/auth/domain/auth_error_code.dart';
import 'package:rideglory/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:rideglory/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:rideglory/features/auth/presentation/cubit/email_auth_cubit.dart';

class _MockSignInWithEmailUseCase extends Mock
    implements SignInWithEmailUseCase {}

class _MockSignUpWithEmailUseCase extends Mock
    implements SignUpWithEmailUseCase {}

void main() {
  late _MockSignInWithEmailUseCase signIn;
  late _MockSignUpWithEmailUseCase signUp;

  setUp(() {
    signIn = _MockSignInWithEmailUseCase();
    signUp = _MockSignUpWithEmailUseCase();
  });

  blocTest<EmailAuthCubit, ResultState<Unit>>(
    'emits [loading, data] when sign in succeeds',
    setUp: () {
      when(
        () => signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(null));
    },
    build: () => EmailAuthCubit(signIn, signUp),
    act: (cubit) => cubit.signIn(email: 'qa1@gmail.com', password: 'Test123.'),
    expect: () => const [
      ResultState<Unit>.loading(),
      ResultState<Unit>.data(data: unit),
    ],
  );

  blocTest<EmailAuthCubit, ResultState<Unit>>(
    'emits [loading, error] when the credentials are invalid',
    setUp: () {
      when(
        () => signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          DomainException(message: AuthErrorCode.invalidCredentials),
        ),
      );
    },
    build: () => EmailAuthCubit(signIn, signUp),
    act: (cubit) => cubit.signIn(email: 'qa1@gmail.com', password: 'wrong'),
    expect: () => const [
      ResultState<Unit>.loading(),
      ResultState<Unit>.error(
        error: DomainException(message: AuthErrorCode.invalidCredentials),
      ),
    ],
  );

  blocTest<EmailAuthCubit, ResultState<Unit>>(
    'emits [loading, data] when sign up succeeds',
    setUp: () {
      when(
        () => signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
        ),
      ).thenAnswer((_) async => const Right(null));
    },
    build: () => EmailAuthCubit(signIn, signUp),
    act: (cubit) => cubit.signUp(
      email: 'nueva@correo.com',
      password: 'Test123.',
      fullName: 'Rider Nuevo',
    ),
    expect: () => const [
      ResultState<Unit>.loading(),
      ResultState<Unit>.data(data: unit),
    ],
  );
}
