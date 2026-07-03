// Parametrized test for the VehicleDocumentCubit<T> base contract.
//
// The base cubit is abstract; this file exercises the inherited contract
// through two concrete subclasses: SoatCubit and TecnomecanicaCubit.
// Both must honour: load() → loading → data/empty/error, and
// 404 (Right(null)) → empty.

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
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/delete_tecnomecanica_usecase.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/get_tecnomecanica_usecase.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/save_tecnomecanica_usecase.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';

// ----- SOAT mocks -----

class MockGetSoatUseCase extends Mock implements GetSoatUseCase {}

class MockSaveSoatUseCase extends Mock implements SaveSoatUseCase {}

class MockDeleteSoatUseCase extends Mock implements DeleteSoatUseCase {}

// ----- RTM mocks -----

class MockGetTecnomecanicaUseCase extends Mock
    implements GetTecnomecanicaUseCase {}

class MockSaveTecnomecanicaUseCase extends Mock
    implements SaveTecnomecanicaUseCase {}

class MockDeleteTecnomecanicaUseCase extends Mock
    implements DeleteTecnomecanicaUseCase {}

// ----- Shared analytics mock -----

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeSoatModel extends Fake implements SoatModel {}

class FakeTecnomecanicaModel extends Fake implements TecnomecanicaModel {}

// --------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSoatModel());
    registerFallbackValue(FakeTecnomecanicaModel());
  });

  // ---------- Fixtures ----------

  final mockSoat = SoatModel(
    id: 'soat-x',
    vehicleId: 'v-1',
    policyNumber: 'POL-X',
    expiryDate: DateTime.now().add(const Duration(days: 90)),
  );

  final mockRtm = TecnomecanicaModel(
    id: 'rtm-x',
    vehicleId: 'v-1',
    cdaName: 'CDA X',
    startDate: DateTime.now().subtract(const Duration(days: 10)),
    expiryDate: DateTime.now().add(const Duration(days: 90)),
  );

  const vehicleId = 'v-1';
  const networkError = DomainException(message: 'Network error');

  // ---------- SoatCubit — base contract ----------

  group('VehicleDocumentCubit base contract — SoatCubit', () {
    late MockGetSoatUseCase mockGet;
    late MockSaveSoatUseCase mockSave;
    late MockDeleteSoatUseCase mockDelete;
    late MockAnalyticsService mockAnalytics;
    late SoatCubit cubit;

    setUp(() {
      mockGet = MockGetSoatUseCase();
      mockSave = MockSaveSoatUseCase();
      mockDelete = MockDeleteSoatUseCase();
      mockAnalytics = MockAnalyticsService();
      when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
      when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
      cubit = SoatCubit(mockGet, mockSave, mockDelete, mockAnalytics);
    });

    tearDown(() => cubit.close());

    blocTest<SoatCubit, ResultState<SoatModel>>(
      'base-soat-01: load() → loading → data when document exists',
      setUp: () {
        when(() => mockGet(vehicleId)).thenAnswer((_) async => Right(mockSoat));
      },
      build: () => cubit,
      act: (c) => c.load(vehicleId),
      expect: () => [
        const ResultState<SoatModel>.loading(),
        predicate<ResultState<SoatModel>>(
          (s) => s is Data<SoatModel> && s.data.id == 'soat-x',
        ),
      ],
    );

    blocTest<SoatCubit, ResultState<SoatModel>>(
      'base-soat-02: load() → loading → empty when 404 (Right(null))',
      setUp: () {
        when(
          () => mockGet(vehicleId),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => cubit,
      act: (c) => c.load(vehicleId),
      expect: () => [
        const ResultState<SoatModel>.loading(),
        const ResultState<SoatModel>.empty(),
      ],
    );

    blocTest<SoatCubit, ResultState<SoatModel>>(
      'base-soat-03: load() → loading → error on failure',
      setUp: () {
        when(
          () => mockGet(vehicleId),
        ).thenAnswer((_) async => const Left(networkError));
      },
      build: () => cubit,
      act: (c) => c.load(vehicleId),
      expect: () => [
        const ResultState<SoatModel>.loading(),
        predicate<ResultState<SoatModel>>(
          (s) => s is Error<SoatModel> && s.error.message == 'Network error',
        ),
      ],
    );
  });

  // ---------- TecnomecanicaCubit — base contract ----------

  group('VehicleDocumentCubit base contract — TecnomecanicaCubit', () {
    late MockGetTecnomecanicaUseCase mockGet;
    late MockSaveTecnomecanicaUseCase mockSave;
    late MockDeleteTecnomecanicaUseCase mockDelete;
    late MockAnalyticsService mockAnalytics;
    late TecnomecanicaCubit cubit;

    setUp(() {
      mockGet = MockGetTecnomecanicaUseCase();
      mockSave = MockSaveTecnomecanicaUseCase();
      mockDelete = MockDeleteTecnomecanicaUseCase();
      mockAnalytics = MockAnalyticsService();
      when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
      when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
      cubit = TecnomecanicaCubit(mockGet, mockSave, mockDelete, mockAnalytics);
    });

    tearDown(() => cubit.close());

    blocTest<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>(
      'base-rtm-01: load() → loading → data when document exists',
      setUp: () {
        when(() => mockGet(vehicleId)).thenAnswer((_) async => Right(mockRtm));
      },
      build: () => cubit,
      act: (c) => c.load(vehicleId),
      expect: () => [
        const ResultState<TecnomecanicaModel>.loading(),
        predicate<ResultState<TecnomecanicaModel>>(
          (s) => s is Data<TecnomecanicaModel> && s.data.id == 'rtm-x',
        ),
      ],
    );

    blocTest<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>(
      'base-rtm-02: load() → loading → empty when 404 (Right(null))',
      setUp: () {
        when(
          () => mockGet(vehicleId),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => cubit,
      act: (c) => c.load(vehicleId),
      expect: () => [
        const ResultState<TecnomecanicaModel>.loading(),
        const ResultState<TecnomecanicaModel>.empty(),
      ],
    );

    blocTest<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>(
      'base-rtm-03: load() → loading → error on failure',
      setUp: () {
        when(
          () => mockGet(vehicleId),
        ).thenAnswer((_) async => const Left(networkError));
      },
      build: () => cubit,
      act: (c) => c.load(vehicleId),
      expect: () => [
        const ResultState<TecnomecanicaModel>.loading(),
        predicate<ResultState<TecnomecanicaModel>>(
          (s) =>
              s is Error<TecnomecanicaModel> &&
              s.error.message == 'Network error',
        ),
      ],
    );
  });
}
