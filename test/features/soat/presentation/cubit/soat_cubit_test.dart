import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
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
  late MockAnalyticsService mockAnalytics;
  late SoatCubit soatCubit;

  final mockSoat = SoatModel(
    id: 'soat-1',
    vehicleId: 'vehicle-1',
    policyNumber: 'POL-001',
    insurer: 'Sura',
    expiryDate: DateTime.now().add(const Duration(days: 90)),
  );

  // SOAT sin id — representa creación nueva
  final newSoat = SoatModel(
    id: '',
    vehicleId: 'vehicle-1',
    policyNumber: 'POL-NEW',
    insurer: 'Mapfre',
    expiryDate: DateTime.now().add(const Duration(days: 180)),
  );

  const vehicleId = 'vehicle-1';

  setUp(() {
    mockGetSoatUseCase = MockGetSoatUseCase();
    mockSaveSoatUseCase = MockSaveSoatUseCase();
    mockDeleteSoatUseCase = MockDeleteSoatUseCase();
    mockAnalytics = MockAnalyticsService();
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

  group('SoatCubit — analytics Fase 9', () {
    // TC-soat-a1: save con SOAT con id no vacío → soat_updated emitido
    test(
      'TC-soat-a1: save con soat.id no vacío (edición) → soat_updated emitido',
      () async {
        when(
          () => mockSaveSoatUseCase(
            vehicleId: vehicleId,
            soat: any(named: 'soat'),
          ),
        ).thenAnswer((_) async => Right(mockSoat));

        await soatCubit.save(vehicleId: vehicleId, soat: mockSoat);

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.soatUpdated, any()),
        ).called(1);
      },
    );

    // TC-soat-a2: save con SOAT con id no vacío → soat_manual_saved NO emitido
    test(
      'TC-soat-a2: save con soat.id no vacío → soat_manual_saved NO emitido',
      () async {
        when(
          () => mockSaveSoatUseCase(
            vehicleId: vehicleId,
            soat: any(named: 'soat'),
          ),
        ).thenAnswer((_) async => Right(mockSoat));

        await soatCubit.save(vehicleId: vehicleId, soat: mockSoat);

        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.soatManualSaved, any()),
        );
      },
    );

    // TC-soat-a3: save con SOAT con id vacío (creación) → soat_manual_saved emitido
    test(
      'TC-soat-a3: save con soat.id vacío (creación) → soat_manual_saved emitido',
      () async {
        when(
          () => mockSaveSoatUseCase(
            vehicleId: vehicleId,
            soat: any(named: 'soat'),
          ),
        ).thenAnswer((_) async => Right(newSoat));

        await soatCubit.save(vehicleId: vehicleId, soat: newSoat);

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.soatManualSaved, any()),
        ).called(1);
      },
    );

    // TC-soat-a4: save con SOAT con id vacío → soat_updated NO emitido
    test(
      'TC-soat-a4: save con soat.id vacío → soat_updated NO emitido',
      () async {
        when(
          () => mockSaveSoatUseCase(
            vehicleId: vehicleId,
            soat: any(named: 'soat'),
          ),
        ).thenAnswer((_) async => Right(newSoat));

        await soatCubit.save(vehicleId: vehicleId, soat: newSoat);

        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.soatUpdated, any()),
        );
      },
    );

    // TC-soat-a5: delete exitoso → soat_deleted emitido
    test(
      'TC-soat-a5: delete exitoso → soat_deleted emitido',
      () async {
        when(
          () => mockDeleteSoatUseCase(vehicleId),
        ).thenAnswer((_) async => const Right(unit));

        await soatCubit.delete(vehicleId);

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.soatDeleted),
        ).called(1);
      },
    );

    // TC-soat-a6: delete con error → soat_deleted NO emitido
    test(
      'TC-soat-a6: delete con error → soat_deleted NO emitido',
      () async {
        when(() => mockDeleteSoatUseCase(vehicleId)).thenAnswer(
          (_) async => const Left(DomainException(message: 'Borrado fallido')),
        );

        await soatCubit.delete(vehicleId);

        verifyNever(() => mockAnalytics.logEvent(AnalyticsEvents.soatDeleted));
      },
    );

    // TC-soat-a7: save con error → ni soat_updated ni soat_manual_saved emitidos
    test(
      'TC-soat-a7: save con error → ningún evento analytics emitido',
      () async {
        when(
          () => mockSaveSoatUseCase(
            vehicleId: vehicleId,
            soat: any(named: 'soat'),
          ),
        ).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Guardado fallido')),
        );

        await soatCubit.save(vehicleId: vehicleId, soat: mockSoat);

        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.soatUpdated, any()),
        );
        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.soatManualSaved, any()),
        );
      },
    );

    // TC-soat-a8: soat_updated incluye had_pdf param
    test(
      'TC-soat-a8: soat_updated incluye param ${AnalyticsParams.hadPdf}',
      () async {
        when(
          () => mockSaveSoatUseCase(
            vehicleId: vehicleId,
            soat: any(named: 'soat'),
          ),
        ).thenAnswer((_) async => Right(mockSoat));

        await soatCubit.save(vehicleId: vehicleId, soat: mockSoat);

        final captured = verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.soatUpdated,
            captureAny(),
          ),
        ).captured;

        final params = captured.single as Map<String, Object>;
        expect(params.containsKey(AnalyticsParams.hadPdf), isTrue);
      },
    );
  });
}
