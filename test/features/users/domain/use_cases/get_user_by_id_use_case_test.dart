import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
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
    // TC-2-34: GetUserByIdUseCase calls repository with correct userId
    test(
      'TC-2-34: GetUserByIdUseCase calls repository with correct userId',
      () async {
        when(() => mockUserRepository.getUserById('user-123')).thenAnswer(
          (_) async => Right(mockUser),
        );

        await getUserByIdUseCase('user-123');

        verify(() => mockUserRepository.getUserById('user-123')).called(1);
      },
    );

    // TC-2-35: GetUserByIdUseCase returns user on success
    test(
      'TC-2-35: GetUserByIdUseCase returns user on success',
      () async {
        when(() => mockUserRepository.getUserById('user-123')).thenAnswer(
          (_) async => Right(mockUser),
        );

        final result = await getUserByIdUseCase('user-123');

        expect(result, Right(mockUser));
      },
    );

    // TC-2-36: GetUserByIdUseCase returns error on failure
    test(
      'TC-2-36: GetUserByIdUseCase returns error on failure',
      () async {
        final exception = DomainException(
          message: 'User not found',
          code: 'NOT_FOUND',
        );
        when(() => mockUserRepository.getUserById('user-not-found'))
            .thenAnswer((_) async => Left(exception));

        final result = await getUserByIdUseCase('user-not-found');

        expect(result, Left(exception));
      },
    );

    // TC-2-37: GetUserByIdUseCase handles network error
    test(
      'TC-2-37: GetUserByIdUseCase handles network error',
      () async {
        final exception = DomainException(
          message: 'Network error',
          code: 'NETWORK_ERROR',
        );
        when(() => mockUserRepository.getUserById('user-123')).thenAnswer(
          (_) async => Left(exception),
        );

        final result = await getUserByIdUseCase('user-123');

        expect(result is Left, true);
        result.fold(
          (error) {
            expect(error.code, 'NETWORK_ERROR');
          },
          (_) => fail('Should return error, not success'),
        );
      },
    );

    // TC-2-38: GetUserByIdUseCase returns correct user data
    test(
      'TC-2-38: GetUserByIdUseCase returns user with correct data',
      () async {
        when(() => mockUserRepository.getUserById('user-123')).thenAnswer(
          (_) async => Right(mockUser),
        );

        final result = await getUserByIdUseCase('user-123');

        result.fold(
          (_) => fail('Should return user, not error'),
          (user) {
            expect(user.id, 'user-123');
            expect(user.fullName, 'Juan Pérez');
            expect(user.email, 'juan@example.com');
          },
        );
      },
    );

    // TC-2-39: GetUserByIdUseCase is idempotent (multiple calls)
    test(
      'TC-2-39: GetUserByIdUseCase is idempotent',
      () async {
        when(() => mockUserRepository.getUserById('user-123')).thenAnswer(
          (_) async => Right(mockUser),
        );

        final result1 = await getUserByIdUseCase('user-123');
        final result2 = await getUserByIdUseCase('user-123');

        expect(result1, result2);
      },
    );

    // TC-2-40: GetUserByIdUseCase with empty userId
    test(
      'TC-2-40: GetUserByIdUseCase handles empty userId',
      () async {
        final exception = DomainException(
          message: 'Invalid userId',
          code: 'INVALID_INPUT',
        );
        when(() => mockUserRepository.getUserById('')).thenAnswer(
          (_) async => Left(exception),
        );

        final result = await getUserByIdUseCase('');

        expect(result is Left, true);
      },
    );
  });
}
