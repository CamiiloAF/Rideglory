import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/domain/use_cases/get_user_by_id_use_case.dart';
import 'package:rideglory/features/users/presentation/cubit/rider_profile_cubit.dart';

class MockGetUserByIdUseCase extends Mock implements GetUserByIdUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

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
    final mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    riderProfileCubit = RiderProfileCubit(
      mockGetUserByIdUseCase,
      mockAnalytics,
    );
  });

  tearDown(() {
    riderProfileCubit.close();
  });

  group('RiderProfileCubit — GetUserByIdUseCase (US-2-3)', () {
    test('TC-2-11: Initial state is ResultState.initial', () {
      expect(riderProfileCubit.state, const ResultState<UserModel>.initial());
    });

    blocTest<RiderProfileCubit, ResultState<UserModel>>(
      'TC-2-12: fetchRiderProfile() emits loading then data on success',
      setUp: () {
        when(
          () => mockGetUserByIdUseCase('user-123'),
        ).thenAnswer((_) async => const Right(mockUser));
      },
      build: () => riderProfileCubit,
      act: (cubit) => cubit.fetchRiderProfile('user-123'),
      expect: () => [
        const ResultState<UserModel>.loading(),
        const ResultState.data(data: mockUser),
      ],
      verify: (cubit) {
        verify(() => mockGetUserByIdUseCase('user-123')).called(1);
      },
    );

    blocTest<RiderProfileCubit, ResultState<UserModel>>(
      'TC-2-13: fetchRiderProfile() emits loading then error on failure',
      setUp: () {
        when(() => mockGetUserByIdUseCase('user-not-found')).thenAnswer(
          (_) async => const Left(DomainException(message: 'User not found')),
        );
      },
      build: () => riderProfileCubit,
      act: (cubit) => cubit.fetchRiderProfile('user-not-found'),
      expect: () => [
        const ResultState<UserModel>.loading(),
        predicate<ResultState<UserModel>>(
          (state) =>
              state is Error<UserModel> &&
              state.error.message == 'User not found',
        ),
      ],
    );

    blocTest<RiderProfileCubit, ResultState<UserModel>>(
      'TC-2-14: fetchRiderProfile() calls GetUserByIdUseCase with correct userId',
      setUp: () {
        when(
          () => mockGetUserByIdUseCase('user-456'),
        ).thenAnswer((_) async => const Right(mockUser));
      },
      build: () => riderProfileCubit,
      act: (cubit) => cubit.fetchRiderProfile('user-456'),
      verify: (cubit) {
        verify(() => mockGetUserByIdUseCase('user-456')).called(1);
      },
    );

    blocTest<RiderProfileCubit, ResultState<UserModel>>(
      'TC-2-15: fetchRiderProfile() with network error emits error state',
      setUp: () {
        when(() => mockGetUserByIdUseCase('user-123')).thenAnswer(
          (_) async => const Left(DomainException(message: 'Network error')),
        );
      },
      build: () => riderProfileCubit,
      act: (cubit) => cubit.fetchRiderProfile('user-123'),
      expect: () => [
        const ResultState<UserModel>.loading(),
        predicate<ResultState<UserModel>>(
          (state) =>
              state is Error<UserModel> &&
              state.error.message == 'Network error',
        ),
      ],
    );

    blocTest<RiderProfileCubit, ResultState<UserModel>>(
      'TC-2-16: fetchRiderProfile() returns user with all required fields',
      setUp: () {
        when(
          () => mockGetUserByIdUseCase('user-123'),
        ).thenAnswer((_) async => const Right(mockUser));
      },
      build: () => riderProfileCubit,
      act: (cubit) => cubit.fetchRiderProfile('user-123'),
      verify: (cubit) {
        final state = cubit.state;
        if (state is Data<UserModel>) {
          expect(state.data.fullName, 'Juan Pérez');
          expect(state.data.email, 'juan@example.com');
          expect(state.data.id, 'user-123');
        }
      },
    );
  });
}
