import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/profile/domain/use_cases/get_my_profile_use_case.dart';
import 'package:rideglory/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

// Mock the GetMyProfileUseCase
class MockGetMyProfileUseCase extends Mock implements GetMyProfileUseCase {}

void main() {
  group('ProfileCubit', () {
    late ProfileCubit profileCubit;
    late MockGetMyProfileUseCase mockGetMyProfileUseCase;

    setUp(() {
      mockGetMyProfileUseCase = MockGetMyProfileUseCase();
      profileCubit = ProfileCubit(mockGetMyProfileUseCase);
    });

    tearDown(() {
      profileCubit.close();
    });

    // TC-1-5: Initial state test
    test('initial state is ResultState.initial()', () {
      expect(profileCubit.state, isA<Initial>());
    });

    // TC-1-6: Loading and data state test
    blocTest<ProfileCubit, ResultState<UserModel>>(
      'emits [loading, data] when fetchProfile succeeds',
      build: () {
        final mockUser = UserModel(
          id: 'user123',
          fullName: 'Test User',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        when(() => mockGetMyProfileUseCase.call())
            .thenAnswer((_) async => Right(mockUser));
        return profileCubit;
      },
      act: (cubit) => cubit.fetchProfile(),
      expect: () => [
        isA<Loading<UserModel>>(),
        isA<Data<UserModel>>()
            .having((state) => state.data.email, 'email', 'test@example.com')
            .having((state) => state.data.fullName, 'fullName', 'Test User'),
      ],
    );

    // TC-1-8: Error state test
    blocTest<ProfileCubit, ResultState<UserModel>>(
      'emits [loading, error] when fetchProfile fails',
      build: () {
        final exception = DomainException(message: 'Network error');
        when(() => mockGetMyProfileUseCase.call())
            .thenAnswer((_) async => Left(exception));
        return profileCubit;
      },
      act: (cubit) => cubit.fetchProfile(),
      expect: () => [
        isA<Loading<UserModel>>(),
        isA<Error<UserModel>>()
            .having((state) => state.error.message, 'message', 'Network error'),
      ],
    );

    // Test reset functionality
    blocTest<ProfileCubit, ResultState<UserModel>>(
      'reset emits initial state',
      build: () {
        final mockUser = UserModel(
          id: 'user123',
          fullName: 'Test User',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        when(() => mockGetMyProfileUseCase.call())
            .thenAnswer((_) async => Right(mockUser));
        return profileCubit;
      },
      act: (cubit) async {
        await cubit.fetchProfile();
        cubit.reset();
      },
      expect: () => [
        isA<Loading<UserModel>>(),
        isA<Data<UserModel>>(),
        isA<Initial<UserModel>>(),
      ],
    );
  });
}
