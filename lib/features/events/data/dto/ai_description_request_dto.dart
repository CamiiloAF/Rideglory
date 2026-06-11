import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/features/events/data/dto/ai_chat_turn_dto.dart';
import 'package:rideglory/features/events/data/dto/ai_event_context_dto.dart';
import 'package:rideglory/features/events/domain/model/ai_description_request.dart';

part 'ai_description_request_dto.g.dart';

// Pattern B exception (request-only DTO): no domain model counterpart —
// this is the outbound API payload for POST /ai/description.
@JsonSerializable(explicitToJson: true)
class AiDescriptionRequestDto {
  const AiDescriptionRequestDto({
    required this.eventContext,
    required this.history,
    required this.userMessage,
  });

  final AiEventContextDto eventContext;
  final List<AiChatTurnDto> history;
  final String userMessage;

  factory AiDescriptionRequestDto.fromDomain(AiDescriptionRequest request) =>
      AiDescriptionRequestDto(
        eventContext: AiEventContextDto.fromDomain(request),
        history: request.history
            .map(AiChatTurnDto.fromDomain)
            .toList(growable: false),
        userMessage: request.userMessage,
      );

  factory AiDescriptionRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AiDescriptionRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AiDescriptionRequestDtoToJson(this);
}
