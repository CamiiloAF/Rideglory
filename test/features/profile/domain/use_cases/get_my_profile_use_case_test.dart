import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/profile/domain/use_cases/get_my_profile_use_case.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/domain/repository/user_repository.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockUserRepository;
  late GetMyProfileUseCase useCase;

  setUp(() {
    mockUserRepository = MockUserRepository();
    useCase = GetMyProfileUseCase(mockUserRepository);
  });

  group('GetMyProfileUseCase', () {
    test(
      'delega en UserRepository.getCurrentUser() y retorna Right(UserModel) '
      'cuando la carga es exitosa',
      () async {
        final mockUser = UserModel(
          id: 'user123',
          fullName: 'Test User',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(mockUser));

        final result = await useCase.call();

        expect(result, isA<Right<DomainException, UserModel>>());
        result.fold(
          (error) => fail('No debería retornar error'),
          (user) => expect(user.id, 'user123'),
        );
        verify(() => mockUserRepository.getCurrentUser()).called(1);
      },
    );

    test(
      'retorna Left(DomainException) cuando UserRepository.getCurrentUser() falla',
      () async {
        const exception = DomainException(message: 'Network error');
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => const Left(exception));

        final result = await useCase.call();

        expect(result, isA<Left<DomainException, UserModel>>());
        result.fold(
          (error) => expect(error.message, 'Network error'),
          (user) => fail('No debería retornar un usuario'),
        );
        verify(() => mockUserRepository.getCurrentUser()).called(1);
      },
    );
  });
}
