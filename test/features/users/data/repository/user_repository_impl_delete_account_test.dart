// Tests de UserRepositoryImpl.deleteMyAccount — camino feliz y de error.
// Los demás métodos de UserRepositoryImpl (registerUser, getCurrentUser,
// getUserById) ya se cubren indirectamente vía tests de use case/DTO
// existentes; este archivo se enfoca en el método nuevo de esta fase.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/users/data/repository/user_repository_impl.dart';
import 'package:rideglory/features/users/data/service/user_service.dart';

class MockUserService extends Mock implements UserService {}

DioException _dioException() => DioException(
  requestOptions: RequestOptions(path: '/users/me'),
  type: DioExceptionType.connectionError,
);

void main() {
  late MockUserService mockService;
  late UserRepositoryImpl repository;

  setUp(() {
    mockService = MockUserService();
    repository = UserRepositoryImpl(mockService);
  });

  group('deleteMyAccount', () {
    test('camino feliz — retorna Right(Nothing)', () async {
      when(() => mockService.deleteMyAccount()).thenAnswer((_) async {});

      final result = await repository.deleteMyAccount();

      expect(result.isRight(), isTrue);
      verify(() => mockService.deleteMyAccount()).called(1);
    });

    test('camino de error — DioException retorna Left', () async {
      when(() => mockService.deleteMyAccount()).thenThrow(_dioException());

      final result = await repository.deleteMyAccount();

      expect(result.isLeft(), isTrue);
    });
  });
}
