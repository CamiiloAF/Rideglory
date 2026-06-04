import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/delete_tecnomecanica_usecase.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/get_tecnomecanica_usecase.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/save_tecnomecanica_usecase.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';

class MockGetTecnomecanicaUseCase extends Mock
    implements GetTecnomecanicaUseCase {}

class MockSaveTecnomecanicaUseCase extends Mock
    implements SaveTecnomecanicaUseCase {}

class MockDeleteTecnomecanicaUseCase extends Mock
    implements DeleteTecnomecanicaUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeTecnomecanicaModel extends Fake implements TecnomecanicaModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTecnomecanicaModel());
  });

  late MockGetTecnomecanicaUseCase mockGetUseCase;
  late MockSaveTecnomecanicaUseCase mockSaveUseCase;
  late MockDeleteTecnomecanicaUseCase mockDeleteUseCase;
  late MockAnalyticsService mockAnalytics;
  late TecnomecanicaCubit cubit;

  final existingRtm = TecnomecanicaModel(
    id: 'rtm-1',
    vehicleId: 'vehicle-1',
    certificateNumber: 'CDA-001',
    cdaName: 'CDA Test',
    expiryDate: DateTime.now().add(const Duration(days: 90)),
  );

  final newRtm = TecnomecanicaModel(
    id: '',
    vehicleId: 'vehicle-1',
    certificateNumber: 'CDA-NEW',
    cdaName: 'CDA Nuevo',
    expiryDate: DateTime.now().add(const Duration(days: 180)),
  );

  const vehicleId = 'vehicle-1';

  setUp(() {
    mockGetUseCase = MockGetTecnomecanicaUseCase();
    mockSaveUseCase = MockSaveTecnomecanicaUseCase();
    mockDeleteUseCase = MockDeleteTecnomecanicaUseCase();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    cubit = TecnomecanicaCubit(
      mockGetUseCase,
      mockSaveUseCase,
      mockDeleteUseCase,
      mockAnalytics,
    );
  });

  tearDown(() => cubit.close());

  group('TecnomecanicaCubit — load', () {
    blocTest<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>(
      'TC-cubit-01: load() emits loading then data when RTM exists',
      setUp: () {
        when(
          () => mockGetUseCase(vehicleId),
        ).thenAnswer((_) async => Right(existingRtm));
      },
      build: () => cubit,
      act: (c) => c.load(vehicleId),
      expect: () => [
        const ResultState<TecnomecanicaModel>.loading(),
        predicate<ResultState<TecnomecanicaModel>>(
          (state) =>
              state is Data<TecnomecanicaModel> &&
              state.data.certificateNumber == 'CDA-001',
        ),
      ],
    );

    blocTest<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>(
      'TC-cubit-02: load() emits empty when no RTM registered (404)',
      setUp: () {
        when(
          () => mockGetUseCase(vehicleId),
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
      'TC-cubit-03: load() emits error on network failure',
      setUp: () {
        when(() => mockGetUseCase(vehicleId)).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Error de conexión')),
        );
      },
      build: () => cubit,
      act: (c) => c.load(vehicleId),
      expect: () => [
        const ResultState<TecnomecanicaModel>.loading(),
        predicate<ResultState<TecnomecanicaModel>>(
          (state) =>
              state is Error<TecnomecanicaModel> &&
              state.error.message == 'Error de conexión',
        ),
      ],
    );
  });

  group('TecnomecanicaCubit — save', () {
    blocTest<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>(
      'TC-cubit-04: save() emits loading then data on success',
      setUp: () {
        when(
          () => mockSaveUseCase(
            vehicleId: vehicleId,
            tecnomecanica: any(named: 'tecnomecanica'),
          ),
        ).thenAnswer((_) async => Right(existingRtm));
      },
      build: () => cubit,
      act: (c) =>
          c.save(vehicleId: vehicleId, tecnomecanica: existingRtm),
      expect: () => [
        const ResultState<TecnomecanicaModel>.loading(),
        predicate<ResultState<TecnomecanicaModel>>(
          (state) =>
              state is Data<TecnomecanicaModel> && state.data.id == 'rtm-1',
        ),
      ],
    );

    blocTest<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>(
      'TC-cubit-05: save() emits error on failure',
      setUp: () {
        when(
          () => mockSaveUseCase(
            vehicleId: vehicleId,
            tecnomecanica: any(named: 'tecnomecanica'),
          ),
        ).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Guardado fallido')),
        );
      },
      build: () => cubit,
      act: (c) => c.save(vehicleId: vehicleId, tecnomecanica: existingRtm),
      expect: () => [
        const ResultState<TecnomecanicaModel>.loading(),
        predicate<ResultState<TecnomecanicaModel>>(
          (state) =>
              state is Error<TecnomecanicaModel> &&
              state.error.message == 'Guardado fallido',
        ),
      ],
    );
  });

  group('TecnomecanicaCubit — delete', () {
    blocTest<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>(
      'TC-cubit-06: delete() emits loading then empty on success',
      setUp: () {
        when(
          () => mockDeleteUseCase(vehicleId),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: () => cubit,
      act: (c) => c.delete(vehicleId),
      expect: () => [
        const ResultState<TecnomecanicaModel>.loading(),
        const ResultState<TecnomecanicaModel>.empty(),
      ],
    );

    blocTest<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>(
      'TC-cubit-07: delete() emits error on failure',
      setUp: () {
        when(() => mockDeleteUseCase(vehicleId)).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Borrado fallido')),
        );
      },
      build: () => cubit,
      act: (c) => c.delete(vehicleId),
      expect: () => [
        const ResultState<TecnomecanicaModel>.loading(),
        predicate<ResultState<TecnomecanicaModel>>(
          (state) =>
              state is Error<TecnomecanicaModel> &&
              state.error.message == 'Borrado fallido',
        ),
      ],
    );
  });

  group('TecnomecanicaCubit — analytics', () {
    test(
      'TC-cubit-a1: save con id no vacío (edición) → tecnomecanica_updated emitido',
      () async {
        when(
          () => mockSaveUseCase(
            vehicleId: vehicleId,
            tecnomecanica: any(named: 'tecnomecanica'),
          ),
        ).thenAnswer((_) async => Right(existingRtm));

        await cubit.save(vehicleId: vehicleId, tecnomecanica: existingRtm);

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.tecnomecanicaUpdated),
        ).called(1);
      },
    );

    test(
      'TC-cubit-a2: save con id vacío (creación) → tecnomecanica_manual_saved emitido',
      () async {
        when(
          () => mockSaveUseCase(
            vehicleId: vehicleId,
            tecnomecanica: any(named: 'tecnomecanica'),
          ),
        ).thenAnswer((_) async => Right(newRtm));

        await cubit.save(vehicleId: vehicleId, tecnomecanica: newRtm);

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.tecnomecanicaManualSaved),
        ).called(1);
      },
    );

    test(
      'TC-cubit-a3: save con id vacío → tecnomecanica_updated NO emitido',
      () async {
        when(
          () => mockSaveUseCase(
            vehicleId: vehicleId,
            tecnomecanica: any(named: 'tecnomecanica'),
          ),
        ).thenAnswer((_) async => Right(newRtm));

        await cubit.save(vehicleId: vehicleId, tecnomecanica: newRtm);

        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.tecnomecanicaUpdated),
        );
      },
    );

    test(
      'TC-cubit-a4: delete exitoso → tecnomecanica_deleted emitido',
      () async {
        when(
          () => mockDeleteUseCase(vehicleId),
        ).thenAnswer((_) async => const Right(unit));

        await cubit.delete(vehicleId);

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.tecnomecanicaDeleted),
        ).called(1);
      },
    );

    test(
      'TC-cubit-a5: save con error → ningún evento analytics emitido',
      () async {
        when(
          () => mockSaveUseCase(
            vehicleId: vehicleId,
            tecnomecanica: any(named: 'tecnomecanica'),
          ),
        ).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Guardado fallido')),
        );

        await cubit.save(vehicleId: vehicleId, tecnomecanica: existingRtm);

        verifyNever(
          () =>
              mockAnalytics.logEvent(AnalyticsEvents.tecnomecanicaUpdated),
        );
        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.tecnomecanicaManualSaved,
          ),
        );
      },
    );

    test(
      'TC-cubit-a6: delete con error → tecnomecanica_deleted NO emitido',
      () async {
        when(() => mockDeleteUseCase(vehicleId)).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Borrado fallido')),
        );

        await cubit.delete(vehicleId);

        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.tecnomecanicaDeleted),
        );
      },
    );

    test(
      'TC-cubit-a7: load exitoso → tecnomecanica_status_viewed emitido',
      () async {
        when(
          () => mockGetUseCase(vehicleId),
        ).thenAnswer((_) async => Right(existingRtm));

        await cubit.load(vehicleId);

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.tecnomecanicaStatusViewed,
            any(),
          ),
        ).called(1);
      },
    );

    test(
      'TC-cubit-a8: load con resultado vacío → tecnomecanica_status_viewed NO emitido',
      () async {
        when(
          () => mockGetUseCase(vehicleId),
        ).thenAnswer((_) async => const Right(null));

        await cubit.load(vehicleId);

        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.tecnomecanicaStatusViewed,
            any(),
          ),
        );
      },
    );
  });
}
