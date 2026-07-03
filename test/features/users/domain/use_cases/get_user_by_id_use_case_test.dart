import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/domain/repository/user_repository.dart';
import 'package:rideglory/features/users/domain/use_cases/get_user_by_id_use_case.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockUserRepository;
  late GetUserByIdUseCase getUserByIdUseCase;

  const mockUser = UserModel(
    id: 'user-123',
    fullName: 'Juan Pérez',
    email: 'juan@example.com',
  );

  setUp(() {
    mockUserRepository = MockUserRepository();
    getUserByIdUseCase = GetUserByIdUseCase(mockUserRepository);
  });

  group('GetUserByIdUseCase — Unit Tests (US-2-3)', () {
    test('TC-2-34: calls repository with correct userId', () async {
      when(
        () => mockUserRepository.getUserById('user-123'),
      ).thenAnswer((_) async => const Right(mockUser));

      await getUserByIdUseCase('user-123');

      verify(() => mockUserRepository.getUserById('user-123')).called(1);
    });

    test('TC-2-35: returns user on success', () async {
      when(
        () => mockUserRepository.getUserById('user-123'),
      ).thenAnswer((_) async => const Right(mockUser));

      final result = await getUserByIdUseCase('user-123');

      expect(result, const Right(mockUser));
    });

    test('TC-2-36: returns error on failure', () async {
      const exception = DomainException(message: 'User not found');
      when(
        () => mockUserRepository.getUserById('user-not-found'),
      ).thenAnswer((_) async => const Left(exception));

      final result = await getUserByIdUseCase('user-not-found');

      expect(result, const Left(exception));
    });

    test('TC-2-37: returns correct user data', () async {
      when(
        () => mockUserRepository.getUserById('user-123'),
      ).thenAnswer((_) async => const Right(mockUser));

      final result = await getUserByIdUseCase('user-123');

      result.fold((_) => fail('Should return user, not error'), (user) {
        expect(user.id, 'user-123');
        expect(user.fullName, 'Juan Pérez');
        expect(user.email, 'juan@example.com');
      });
    });

    test('TC-2-38: is idempotent (multiple calls)', () async {
      when(
        () => mockUserRepository.getUserById('user-123'),
      ).thenAnswer((_) async => const Right(mockUser));

      final result1 = await getUserByIdUseCase('user-123');
      final result2 = await getUserByIdUseCase('user-123');

      expect(result1, result2);
    });
  });
}
