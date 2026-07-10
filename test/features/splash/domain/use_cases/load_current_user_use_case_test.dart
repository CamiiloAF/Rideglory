import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/splash/domain/use_cases/load_current_user_use_case.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late LoadCurrentUserUseCase useCase;

  setUp(() {
    mockAuthService = MockAuthService();
    useCase = LoadCurrentUserUseCase(mockAuthService);
  });

  const user = UserModel(
    id: 'u1',
    email: 'rider@rideglory.com',
    fullName: 'Rider',
  );

  test('camino feliz — retorna el usuario cargado por AuthService', () async {
    when(
      () => mockAuthService.loadCurrentUser(),
    ).thenAnswer((_) async => const Right(user));

    final result = await useCase();

    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('Expected Right'),
      (loadedUser) => expect(loadedUser, user),
    );
  });

  test('sin sesión — retorna Right(null)', () async {
    when(
      () => mockAuthService.loadCurrentUser(),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase();

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('Expected Right'), (loadedUser) {
      expect(loadedUser, isNull);
    });
  });

  test('camino de error — propaga el Left de AuthService', () async {
    const error = DomainException(message: 'No se pudo cargar el usuario');
    when(
      () => mockAuthService.loadCurrentUser(),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, error),
      (_) => fail('Expected Left'),
    );
  });
}
