import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/features/events/domain/model/ai_description_request.dart';

part 'ai_event_context_dto.g.dart';

// Pattern B exception (composite/request-only DTO): embedded inside
// AiDescriptionRequestDto; no 1:1 domain model.
@JsonSerializable(includeIfNull: false)
class AiEventContextDto {
  const AiEventContextDto({
    required this.title,
    required this.eventType,
    this.difficulty,
    this.startDate,
  });

  final String title;
  final String eventType;
  final String? difficulty;
  final String? startDate;

  factory AiEventContextDto.fromDomain(AiDescriptionRequest request) =>
      AiEventContextDto(
        title: request.title,
        eventType: request.eventType,
        difficulty: request.difficulty,
        startDate: request.startDate,
      );

  factory AiEventContextDto.fromJson(Map<String, dynamic> json) =>
      _$AiEventContextDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AiEventContextDtoToJson(this);
}
