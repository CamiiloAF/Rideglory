import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/users/domain/repository/user_repository.dart';
import 'package:rideglory/features/users/domain/use_cases/delete_account_use_case.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockUserRepository;
  late DeleteAccountUseCase useCase;

  setUp(() {
    mockUserRepository = MockUserRepository();
    useCase = DeleteAccountUseCase(mockUserRepository);
  });

  test(
    'camino feliz — retorna Right(Nothing) y delega al repositorio',
    () async {
      when(
        () => mockUserRepository.deleteMyAccount(),
      ).thenAnswer((_) async => const Right(Nothing()));

      final result = await useCase();

      expect(result.isRight(), isTrue);
      verify(() => mockUserRepository.deleteMyAccount()).called(1);
    },
  );

  test(
    'camino de error — propaga el DomainException del repositorio',
    () async {
      const error = DomainException(message: 'No se pudo eliminar la cuenta');
      when(
        () => mockUserRepository.deleteMyAccount(),
      ).thenAnswer((_) async => const Left(error));

      final result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold((left) => expect(left, error), (_) => fail('Expected Left'));
    },
  );
}
