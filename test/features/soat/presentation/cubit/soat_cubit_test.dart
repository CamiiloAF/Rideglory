import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/domain/usecases/delete_soat_usecase.dart';
import 'package:rideglory/features/soat/domain/usecases/get_soat_usecase.dart';
import 'package:rideglory/features/soat/domain/usecases/save_soat_usecase.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_cubit.dart';

class MockGetSoatUseCase extends Mock implements GetSoatUseCase {}

class MockSaveSoatUseCase extends Mock implements SaveSoatUseCase {}

class MockDeleteSoatUseCase extends Mock implements DeleteSoatUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeSoatModel extends Fake implements SoatModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSoatModel());
  });
  late MockGetSoatUseCase mockGetSoatUseCase;
  late MockSaveSoatUseCase mockSaveSoatUseCase;
  late MockDeleteSoatUseCase mockDeleteSoatUseCase;
  late SoatCubit soatCubit;

  final mockSoat = SoatModel(
    id: 'soat-1',
    vehicleId: 'vehicle-1',
    policyNumber: 'POL-001',
    insurer: 'Sura',
    expiryDate: DateTime.now().add(const Duration(days: 90)),
  );

  const vehicleId = 'vehicle-1';

  setUp(() {
    mockGetSoatUseCase = MockGetSoatUseCase();
    mockSaveSoatUseCase = MockSaveSoatUseCase();
    mockDeleteSoatUseCase = MockDeleteSoatUseCase();
    final mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    soatCubit = SoatCubit(
      mockGetSoatUseCase,
      mockSaveSoatUseCase,
      mockDeleteSoatUseCase,
      mockAnalytics,
    );
  });

  tearDown(() => soatCubit.close());

  group('SoatCubit — load (US-2-6)', () {
    // TC-2-27: load() with existing SOAT emits loading → data
    blocTest<SoatCubit, ResultState<SoatModel>>(
      'TC-2-27: load() emits loading then data when SOAT exists',
      setUp: () {
        when(
          () => mockGetSoatUseCase(vehicleId),
        ).thenAnswer((_) async => Right(mockSoat));
      },
      build: () => soatCubit,
      act: (cubit) => cubit.load(vehicleId),
      expect: () => [
        const ResultState<SoatModel>.loading(),
        predicate<ResultState<SoatModel>>(
          (state) =>
              state is Data<SoatModel> && state.data.policyNumber == 'POL-001',
        ),
      ],
    );

    // TC-2-28: load() with null SOAT (not found) emits loading → empty
    blocTest<SoatCubit, ResultState<SoatModel>>(
      'TC-2-28: load() emits empty when no SOAT registered',
      setUp: () {
        when(
          () => mockGetSoatUseCase(vehicleId),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => soatCubit,
      act: (cubit) => cubit.load(vehicleId),
      expect: () => [
        const ResultState<SoatModel>.loading(),
        const ResultState<SoatModel>.empty(),
      ],
    );

    // TC-2-29: load() on network error emits loading → error
    blocTest<SoatCubit, ResultState<SoatModel>>(
      'TC-2-29: load() emits error on network failure',
      setUp: () {
        when(() => mockGetSoatUseCase(vehicleId)).thenAnswer(
          (_) async => const Left(DomainException(message: 'Error de red')),
        );
      },
      build: () => soatCubit,
      act: (cubit) => cubit.load(vehicleId),
      expect: () => [
        const ResultState<SoatModel>.loading(),
        predicate<ResultState<SoatModel>>(
          (state) =>
              state is Error<SoatModel> &&
              state.error.message == 'Error de red',
        ),
      ],
    );
  });

  group('SoatCubit — save (US-2-6)', () {
    // TC-2-30: save() success returns true and emits data
    blocTest<SoatCubit, ResultState<SoatModel>>(
      'TC-2-30: save() returns true and emits data on success',
      setUp: () {
        when(
          () => mockSaveSoatUseCase(
            vehicleId: vehicleId,
            soat: any(named: 'soat'),
          ),
        ).thenAnswer((_) async => Right(mockSoat));
      },
      build: () => soatCubit,
      act: (cubit) => cubit.save(vehicleId: vehicleId, soat: mockSoat),
      expect: () => [
        const ResultState<SoatModel>.loading(),
        predicate<ResultState<SoatModel>>(
          (state) => state is Data<SoatModel> && state.data.id == 'soat-1',
        ),
      ],
      verify: (cubit) {
        verify(
          () => mockSaveSoatUseCase(
            vehicleId: vehicleId,
            soat: any(named: 'soat'),
          ),
        ).called(1);
      },
    );

    // TC-2-31: save() failure returns false and emits error
    blocTest<SoatCubit, ResultState<SoatModel>>(
      'TC-2-31: save() returns false and emits error on failure',
      setUp: () {
        when(
          () => mockSaveSoatUseCase(
            vehicleId: vehicleId,
            soat: any(named: 'soat'),
          ),
        ).thenAnswer(
          (_) async => const Left(DomainException(message: 'Guardado fallido')),
        );
      },
      build: () => soatCubit,
      act: (cubit) => cubit.save(vehicleId: vehicleId, soat: mockSoat),
      expect: () => [
        const ResultState<SoatModel>.loading(),
        predicate<ResultState<SoatModel>>(
          (state) =>
              state is Error<SoatModel> &&
              state.error.message == 'Guardado fallido',
        ),
      ],
    );
  });

  group('SoatCubit — delete', () {
    blocTest<SoatCubit, ResultState<SoatModel>>(
      'delete() returns true and emits loading then empty on success',
      setUp: () {
        when(
          () => mockDeleteSoatUseCase(vehicleId),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: () => soatCubit,
      act: (cubit) => cubit.delete(vehicleId),
      expect: () => [
        const ResultState<SoatModel>.loading(),
        const ResultState<SoatModel>.empty(),
      ],
      verify: (_) {
        verify(() => mockDeleteSoatUseCase(vehicleId)).called(1);
      },
    );

    blocTest<SoatCubit, ResultState<SoatModel>>(
      'delete() returns false and emits error on failure',
      setUp: () {
        when(() => mockDeleteSoatUseCase(vehicleId)).thenAnswer(
          (_) async => const Left(DomainException(message: 'Borrado fallido')),
        );
      },
      build: () => soatCubit,
      act: (cubit) => cubit.delete(vehicleId),
      expect: () => [
        const ResultState<SoatModel>.loading(),
        predicate<ResultState<SoatModel>>(
          (state) =>
              state is Error<SoatModel> &&
              state.error.message == 'Borrado fallido',
        ),
      ],
    );
  });
}
