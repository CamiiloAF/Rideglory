import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/auth/domain/auth_error_code.dart';
import 'package:rideglory/features/auth/domain/auth_repository.dart';
import 'package:rideglory/features/auth/domain/usecases/sign_in_with_email_usecase.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late SignInWithEmailUseCase useCase;

  setUp(() {
    repository = _MockAuthRepository();
    useCase = SignInWithEmailUseCase(repository);
  });

  test('delegates to the repository with the given credentials', () async {
    when(
      () => repository.signInWithEmail(
        email: 'qa1@gmail.com',
        password: 'Test123.',
      ),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase(email: 'qa1@gmail.com', password: 'Test123.');

    expect(result, const Right<DomainException, void>(null));
    verify(
      () => repository.signInWithEmail(
        email: 'qa1@gmail.com',
        password: 'Test123.',
      ),
    ).called(1);
  });

  test('propagates the domain exception on failure', () async {
    when(
      () => repository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const Left(
        DomainException(message: AuthErrorCode.invalidCredentials),
      ),
    );

    final result = await useCase(email: 'qa1@gmail.com', password: 'wrong');

    expect(
      result,
      const Left<DomainException, void>(
        DomainException(message: AuthErrorCode.invalidCredentials),
      ),
    );
  });
}
