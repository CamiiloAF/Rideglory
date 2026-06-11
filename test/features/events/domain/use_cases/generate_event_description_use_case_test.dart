import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/events/domain/model/ai_chat_turn.dart';
import 'package:rideglory/features/events/domain/model/ai_description_request.dart';
import 'package:rideglory/features/events/domain/model/ai_description_result.dart';
import 'package:rideglory/features/events/domain/repository/ai_description_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/generate_event_description_use_case.dart';

class MockAiDescriptionRepository extends Mock
    implements AiDescriptionRepository {}

void main() {
  late MockAiDescriptionRepository mockRepository;
  late GenerateEventDescriptionUseCase useCase;

  const result = AiDescriptionResult(
    markdown: '## Descripción',
    remainingGenerations: 9,
    isDescription: true,
  );

  setUpAll(() {
    registerFallbackValue(
      const AiDescriptionRequest(
        title: '',
        eventType: '',
        city: '',
        history: [],
        userMessage: '',
      ),
    );
  });

  setUp(() {
    mockRepository = MockAiDescriptionRepository();
    useCase = GenerateEventDescriptionUseCase(mockRepository);
    when(() => mockRepository.generateDescription(any()))
        .thenAnswer((_) async => const Right(result));
  });

  List<AiChatTurn> buildHistory(int count) => List.generate(
        count,
        (index) => AiChatTurn(
          role: index.isEven ? AiChatRole.user : AiChatRole.model,
          content: 'mensaje $index',
        ),
      );

  group('history trim', () {
    test('passes history unchanged when ≤10 turns', () async {
      final history = buildHistory(10);
      final request = AiDescriptionRequest(
        title: 'Rodada',
        eventType: 'tourism',
        city: 'Bogotá',
        history: history,
        userMessage: 'Hola',
      );
      await useCase(request);

      final captured = verify(
        () => mockRepository.generateDescription(captureAny()),
      ).captured.single as AiDescriptionRequest;
      expect(captured.history.length, 10);
      expect(captured.history, history);
    });

    test('trims history to last 10 turns when >10', () async {
      final history = buildHistory(15);
      final request = AiDescriptionRequest(
        title: 'Rodada',
        eventType: 'tourism',
        city: 'Bogotá',
        history: history,
        userMessage: 'Hola',
      );
      await useCase(request);

      final captured = verify(
        () => mockRepository.generateDescription(captureAny()),
      ).captured.single as AiDescriptionRequest;
      expect(captured.history.length, 10);
      expect(captured.history, history.sublist(5));
    });

    test('delegates other fields unchanged', () async {
      const request = AiDescriptionRequest(
        title: 'Test title',
        eventType: 'off_road',
        city: 'Medellín',
        difficulty: 'Difícil',
        startDate: '2026-07-01',
        history: [],
        userMessage: 'Generar',
      );
      await useCase(request);

      final captured = verify(
        () => mockRepository.generateDescription(captureAny()),
      ).captured.single as AiDescriptionRequest;
      expect(captured.title, 'Test title');
      expect(captured.eventType, 'off_road');
      expect(captured.city, 'Medellín');
      expect(captured.difficulty, 'Difícil');
      expect(captured.startDate, '2026-07-01');
      expect(captured.userMessage, 'Generar');
    });
  });
}
