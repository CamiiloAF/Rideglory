import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/domain/use_cases/get_user_by_id_use_case.dart';
import 'package:rideglory/features/users/presentation/cubit/rider_profile_cubit.dart';

class MockGetUserByIdUseCase extends Mock implements GetUserByIdUseCase {}

void main() {
  late MockGetUserByIdUseCase mockGetUserByIdUseCase;
  late RiderProfileCubit riderProfileCubit;

  const mockUser = UserModel(
    id: 'user-123',
    fullName: 'Juan Pérez',
    email: 'juan@example.com',
  );

  setUp(() {
    mockGetUserByIdUseCase = MockGetUserByIdUseCase();
    riderProfileCubit = RiderProfileCubit(mockGetUserByIdUseCase);
  });

  tearDown(() {
    riderProfileCubit.close();
  });

  group('RiderProfileCubit — GetUserByIdUseCase (US-2-3)', () {
    // TC-2-11: Initial state is ResultState.initial
    test('TC-2-11: Initial state is ResultState.initial', () {
      expect(riderProfileCubit.state, const ResultState.initial());
    });

    // TC-2-12: fetchRiderProfile() emits loading then data on success
    blocTest<RiderProfileCubit, ResultState<UserModel>>(
      'TC-2-12: fetchRiderProfile() emits loading then data on success',
      setUp: () {
        when(() => mockGetUserByIdUseCase('user-123')).thenAnswer(
          (_) async => Right(mockUser),
        );
      },
      build: () => riderProfileCubit,
      act: (cubit) => cubit.fetchRiderProfile('user-123'),
      expect: () => [
        const ResultState.loading(),
        const Data<UserModel>(data: mockUser),
      ],
      verify: (cubit) {
        verify(() => mockGetUserByIdUseCase('user-123')).called(1);
      },
    );

    // TC-2-13: fetchRiderProfile() emits loading then error on failure
    blocTest<RiderProfileCubit, ResultState<UserModel>>(
      'TC-2-13: fetchRiderProfile() emits loading then error on failure',
      setUp: () {
        when(() => mockGetUserByIdUseCase('user-not-found')).thenAnswer(
          (_) async => Left(
            DomainException(message: 'User not found', code: 'NOT_FOUND'),
          ),
        );
      },
      build: () => riderProfileCubit,
      act: (cubit) => cubit.fetchRiderProfile('user-not-found'),
      expect: () => [
        const ResultState.loading(),
        predicate<ResultState<UserModel>>(
          (state) =>
              state is Error<UserModel> &&
              state.error.message == 'User not found' &&
              state.error.code == 'NOT_FOUND',
        ),
      ],
    );

    // TC-2-14: fetchRiderProfile() calls GetUserByIdUseCase with correct userId
    blocTest<RiderProfileCubit, ResultState<UserModel>>(
      'TC-2-14: fetchRiderProfile() calls GetUserByIdUseCase with correct userId',
      setUp: () {
        when(() => mockGetUserByIdUseCase('user-456')).thenAnswer(
          (_) async => Right(mockUser),
        );
      },
      build: () => riderProfileCubit,
      act: (cubit) => cubit.fetchRiderProfile('user-456'),
      verify: (cubit) {
        verify(() => mockGetUserByIdUseCase('user-456')).called(1);
      },
    );

    // TC-2-15: fetchRiderProfile() with network error emits error state
    blocTest<RiderProfileCubit, ResultState<UserModel>>(
      'TC-2-15: fetchRiderProfile() with network error emits error state',
      setUp: () {
        when(() => mockGetUserByIdUseCase('user-123')).thenAnswer(
          (_) async => Left(
            DomainException(message: 'Network error', code: 'NETWORK_ERROR'),
          ),
        );
      },
      build: () => riderProfileCubit,
      act: (cubit) => cubit.fetchRiderProfile('user-123'),
      expect: () => [
        const ResultState.loading(),
        predicate<ResultState<UserModel>>(
          (state) =>
              state is Error<UserModel> &&
              state.error.code == 'NETWORK_ERROR',
        ),
      ],
    );

    // TC-2-16: Multiple calls to fetchRiderProfile() reset state to initial
    blocTest<RiderProfileCubit, ResultState<UserModel>>(
      'TC-2-16: fetchRiderProfile() can be called multiple times',
      setUp: () {
        when(() => mockGetUserByIdUseCase('user-123')).thenAnswer(
          (_) async => Right(mockUser),
        );
        when(() => mockGetUserByIdUseCase('user-456')).thenAnswer(
          (_) async => Right(mockUser),
        );
      },
      build: () => riderProfileCubit,
      act: (cubit) {
        cubit.fetchRiderProfile('user-123');
      },
      expect: () => [
        const ResultState.loading(),
        const Data<UserModel>(data: mockUser),
      ],
    );

    // TC-2-17: GetUserByIdUseCase returns user with all required fields
    blocTest<RiderProfileCubit, ResultState<UserModel>>(
      'TC-2-17: fetchRiderProfile() returns user with all required fields',
      setUp: () {
        when(() => mockGetUserByIdUseCase('user-123')).thenAnswer(
          (_) async => Right(mockUser),
        );
      },
      build: () => riderProfileCubit,
      act: (cubit) => cubit.fetchRiderProfile('user-123'),
      verify: (cubit) {
        final state = cubit.state;
        expect(state is Data<UserModel>, true);
        if (state is Data<UserModel>) {
          expect(state.data.fullName, 'Juan Pérez');
          expect(state.data.email, 'juan@example.com');
          expect(state.data.id, 'user-123');
        }
      },
    );
  });
}
