import 'package:rideglory/features/events/domain/model/ai_chat_turn.dart';

class AiDescriptionRequest {
  const AiDescriptionRequest({
    required this.title,
    required this.eventType,
    required this.city,
    this.difficulty,
    this.startDate,
    required this.history,
    required this.userMessage,
  });

  final String title;
  final String eventType;
  final String city;
  final String? difficulty;
  final String? startDate;

  /// Chat history (already trimmed to ≤10 turns by the use case).
  final List<AiChatTurn> history;
  final String userMessage;
}
