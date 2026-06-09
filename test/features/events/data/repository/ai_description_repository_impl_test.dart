import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/ai_domain_exceptions.dart';
import 'package:rideglory/features/events/data/dto/ai_description_request_dto.dart';
import 'package:rideglory/features/events/data/dto/ai_description_response_dto.dart';
import 'package:rideglory/features/events/data/repository/ai_description_repository_impl.dart';
import 'package:rideglory/features/events/data/service/ai_description_service.dart';
import 'package:rideglory/features/events/domain/model/ai_description_request.dart';

class MockAiDescriptionService extends Mock implements AiDescriptionService {}

void main() {
  late MockAiDescriptionService mockService;
  late AiDescriptionRepositoryImpl repository;

  const request = AiDescriptionRequest(
    title: 'Test',
    eventType: 'tourism',
    city: 'Bogotá',
    history: [],
    userMessage: 'Hola',
  );

  setUpAll(() {
    registerFallbackValue(
      AiDescriptionRequestDto.fromDomain(request),
    );
  });

  setUp(() {
    mockService = MockAiDescriptionService();
    repository = AiDescriptionRepositoryImpl(mockService);
  });

  DioException _dioException({
    required int statusCode,
    required String errorCode,
  }) {
    return DioException(
      requestOptions: RequestOptions(path: '/ai/description'),
      response: Response(
        requestOptions: RequestOptions(path: '/ai/description'),
        statusCode: statusCode,
        data: {'error': errorCode},
      ),
    );
  }

  group('generateDescription error mapping', () {
    test('AC9 — 429 quota_exceeded_user → AiQuotaExceededUserException',
        () async {
      when(() => mockService.generateDescription(any())).thenThrow(
        _dioException(statusCode: 429, errorCode: 'quota_exceeded_user'),
      );

      final result = await repository.generateDescription(request);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, isA<AiQuotaExceededUserException>()),
        (_) => fail('Expected Left'),
      );
    });

    test('AC10 — 429 quota_exceeded_project → AiQuotaExceededProjectException',
        () async {
      when(() => mockService.generateDescription(any())).thenThrow(
        _dioException(
            statusCode: 429, errorCode: 'quota_exceeded_project'),
      );

      final result = await repository.generateDescription(request);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, isA<AiQuotaExceededProjectException>()),
        (_) => fail('Expected Left'),
      );
    });

    test('AC11 — 422 safety_blocked → AiSafetyBlockedException', () async {
      when(() => mockService.generateDescription(any())).thenThrow(
        _dioException(statusCode: 422, errorCode: 'safety_blocked'),
      );

      final result = await repository.generateDescription(request);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, isA<AiSafetyBlockedException>()),
        (_) => fail('Expected Left'),
      );
    });

    test('AC12 — any other DioException → AiNetworkErrorException', () async {
      when(() => mockService.generateDescription(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/ai/description'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await repository.generateDescription(request);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, isA<AiNetworkErrorException>()),
        (_) => fail('Expected Left'),
      );
    });

    test('success path returns Right with AiDescriptionResult', () async {
      when(() => mockService.generateDescription(any())).thenAnswer(
        (_) async => const AiDescriptionResponseDto(
          markdown: '## Test',
          remainingGenerations: 7,
          isDescription: true,
        ),
      );

      final result = await repository.generateDescription(request);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (value) {
          expect(value.markdown, '## Test');
          expect(value.remainingGenerations, 7);
        },
      );
    });
  });
}
