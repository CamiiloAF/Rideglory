import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/features/events/domain/model/ai_chat_turn.dart';

part 'ai_chat_turn_dto.g.dart';

// Pattern B exception (request-only DTO): AiChatTurn is a simple value object
// with no JSON deserialization need; this DTO is write-only (outbound request).
@JsonSerializable()
class AiChatTurnDto {
  const AiChatTurnDto({required this.role, required this.content});

  final String role;
  final String content;

  factory AiChatTurnDto.fromDomain(AiChatTurn turn) =>
      AiChatTurnDto(role: turn.role.name, content: turn.content);

  factory AiChatTurnDto.fromJson(Map<String, dynamic> json) =>
      _$AiChatTurnDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AiChatTurnDtoToJson(this);
}
