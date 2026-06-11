// Cubit tests for AiDescriptionChatCubit
// AC15: initQuota calls GetDescriptionQuotaUseCase; sets remainingQuota on success;
//       sets isQuotaInitialized=true even on error
// AC16: after a successful sendMessage, state.remainingQuota == result.remainingGenerations
// CA7:  analytics events emitted on success / quota / safety / network

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/ai_domain_exceptions.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/domain/model/ai_chat_turn.dart';
import 'package:rideglory/features/events/domain/model/ai_description_request.dart';
import 'package:rideglory/features/events/domain/model/ai_description_result.dart';
import 'package:rideglory/features/events/domain/use_cases/generate_event_description_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_description_quota_use_case.dart';
import 'package:rideglory/features/events/presentation/form/cubit/ai_description_chat_cubit.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockGenerateEventDescriptionUseCase extends Mock
    implements GenerateEventDescriptionUseCase {}

class MockGetDescriptionQuotaUseCase extends Mock
    implements GetDescriptionQuotaUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeDomainException extends Fake implements DomainException {
  @override
  String get message => 'error';
}

class FakeAiDescriptionRequest extends Fake implements AiDescriptionRequest {}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late MockGenerateEventDescriptionUseCase mockGenerateUseCase;
  late MockGetDescriptionQuotaUseCase mockQuotaUseCase;
  late MockAnalyticsService mockAnalyticsService;
  late AiDescriptionChatCubit cubit;

  setUpAll(() {
    registerFallbackValue(FakeAiDescriptionRequest());
  });

  setUp(() {
    mockGenerateUseCase = MockGenerateEventDescriptionUseCase();
    mockQuotaUseCase = MockGetDescriptionQuotaUseCase();
    mockAnalyticsService = MockAnalyticsService();
    // logEvent returns a Future<void> — stub it to complete normally
    when(
      () => mockAnalyticsService.logEvent(any(), any()),
    ).thenAnswer((_) async {});
    cubit = AiDescriptionChatCubit(
      mockGenerateUseCase,
      mockQuotaUseCase,
      mockAnalyticsService,
    );
  });

  tearDown(() => cubit.close());

  group('AC15 — initQuota', () {
    test(
      'calls GetDescriptionQuotaUseCase and emits remainingQuota on success',
      () async {
        when(() => mockQuotaUseCase()).thenAnswer((_) async => const Right(5));

        await cubit.initQuota();

        expect(cubit.state.remainingQuota, 5);
        expect(cubit.state.isQuotaInitialized, isTrue);
        verify(() => mockQuotaUseCase()).called(1);
      },
    );

    test(
      'sets isQuotaInitialized=true but leaves remainingQuota null on use case error',
      () async {
        when(() => mockQuotaUseCase())
            .thenAnswer((_) async => Left(FakeDomainException()));

        await cubit.initQuota();

        expect(cubit.state.remainingQuota, isNull);
        expect(cubit.state.isQuotaInitialized, isTrue);
      },
    );
  });

  group('AC16 — sendMessage updates remainingQuota from result', () {
    const result = AiDescriptionResult(
      markdown: '## Descripción de prueba',
      remainingGenerations: 7,
      isDescription: true,
    );

    test(
      'after successful sendMessage, state.remainingQuota == result.remainingGenerations',
      () async {
        when(() => mockGenerateUseCase(any()))
            .thenAnswer((_) async => const Right(result));

        await cubit.sendMessage(
          userMessage: 'Genera una descripción',
          title: 'Rodada del Pacífico',
          eventType: 'tourism',
          city: 'Cali',
        );

        expect(
          cubit.state.remainingQuota,
          result.remainingGenerations,
          reason:
              'remainingQuota must be updated to result.remainingGenerations after success',
        );
        expect(cubit.state.sendResult, isA<Data<AiDescriptionResult>>());
      },
    );

    blocTest<AiDescriptionChatCubit, AiDescriptionChatState>(
      'emits history with user + model turns on success',
      build: () {
        when(() => mockGenerateUseCase(any()))
            .thenAnswer((_) async => const Right(result));
        return AiDescriptionChatCubit(
          mockGenerateUseCase,
          mockQuotaUseCase,
          mockAnalyticsService,
        );
      },
      act: (cubit) => cubit.sendMessage(
        userMessage: 'Genera',
        title: 'Test',
        eventType: 'tourism',
        city: 'Bogotá',
      ),
      expect: () => [
        isA<AiDescriptionChatState>().having(
          (s) => s.sendResult,
          'sendResult',
          isA<Loading<AiDescriptionResult>>(),
        ),
        isA<AiDescriptionChatState>()
            .having(
              (s) => s.remainingQuota,
              'remainingQuota',
              result.remainingGenerations,
            )
            .having(
              (s) => s.history.length,
              'history length',
              2,
            )
            .having(
              (s) => s.history.last.role,
              'last turn role',
              AiChatRole.model,
            ),
      ],
    );
  });

  // ─── CA7 — Analytics ──────────────────────────────────────────────────────

  group('CA7 — analytics: happy path → aiDescriptionGenerated', () {
    const result = AiDescriptionResult(
      markdown: '## Descripción',
      remainingGenerations: 5,
      isDescription: true,
    );

    test(
      'logEvent(aiDescriptionGenerated) called with aiTurnIndex == newHistory.length',
      () async {
        when(() => mockGenerateUseCase(any()))
            .thenAnswer((_) async => const Right(result));

        await cubit.sendMessage(
          userMessage: 'Genera',
          title: 'Test',
          eventType: 'tourism',
          city: 'Bogotá',
        );

        // After sendMessage: history = [userTurn, modelTurn] → length = 2
        verify(
          () => mockAnalyticsService.logEvent(
            AnalyticsEvents.aiDescriptionGenerated,
            {AnalyticsParams.aiTurnIndex: 2},
          ),
        ).called(1);
      },
    );
  });

  group('CA7 — analytics: AiQuotaExceededUserException → aiQuotaExceeded', () {
    test(
      'logEvent(aiQuotaExceeded) called with aiGenerationTypeDescription',
      () async {
        when(() => mockGenerateUseCase(any())).thenAnswer(
          (_) async => const Left(
            AiQuotaExceededUserException(
              message: 'Límite diario alcanzado.',
            ),
          ),
        );

        await cubit.sendMessage(
          userMessage: 'Genera',
          title: 'Test',
          eventType: 'tourism',
          city: 'Bogotá',
        );

        verify(
          () => mockAnalyticsService.logEvent(
            AnalyticsEvents.aiQuotaExceeded,
            {
              AnalyticsParams.aiGenerationType:
                  AnalyticsParams.aiGenerationTypeDescription,
              AnalyticsParams.aiErrorCode:
                  'AiQuotaExceededUserException',
            },
          ),
        ).called(1);
      },
    );
  });

  group(
    'CA7 — analytics: AiSafetyBlockedException → aiGenerationFailed',
    () {
      test(
        'logEvent(aiGenerationFailed) called with aiGenerationTypeDescription',
        () async {
          when(() => mockGenerateUseCase(any())).thenAnswer(
            (_) async => const Left(
              AiSafetyBlockedException(
                message: 'Bloqueado por filtros de seguridad.',
              ),
            ),
          );

          await cubit.sendMessage(
            userMessage: 'Genera',
            title: 'Test',
            eventType: 'tourism',
            city: 'Bogotá',
          );

          verify(
            () => mockAnalyticsService.logEvent(
              AnalyticsEvents.aiGenerationFailed,
              {
                AnalyticsParams.aiGenerationType:
                    AnalyticsParams.aiGenerationTypeDescription,
                AnalyticsParams.aiErrorCode: 'AiSafetyBlockedException',
              },
            ),
          ).called(1);
        },
      );
    },
  );

  group(
    'CA7 — analytics: AiNetworkErrorException → aiGenerationFailed',
    () {
      test(
        'logEvent(aiGenerationFailed) called with aiGenerationTypeDescription',
        () async {
          when(() => mockGenerateUseCase(any())).thenAnswer(
            (_) async => const Left(
              AiNetworkErrorException(
                message: 'No se pudo conectar con el servicio de IA.',
              ),
            ),
          );

          await cubit.sendMessage(
            userMessage: 'Genera',
            title: 'Test',
            eventType: 'tourism',
            city: 'Bogotá',
          );

          verify(
            () => mockAnalyticsService.logEvent(
              AnalyticsEvents.aiGenerationFailed,
              {
                AnalyticsParams.aiGenerationType:
                    AnalyticsParams.aiGenerationTypeDescription,
                AnalyticsParams.aiErrorCode: 'AiNetworkErrorException',
              },
            ),
          ).called(1);
        },
      );
    },
  );
}
