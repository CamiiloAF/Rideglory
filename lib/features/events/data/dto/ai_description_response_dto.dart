import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/features/events/domain/model/ai_description_result.dart';

part 'ai_description_response_dto.g.dart';

// Pattern B exception (response DTO): extends AiDescriptionResult so domain
// model is reused directly; no toModel()/fromModel() needed.
@JsonSerializable()
class AiDescriptionResponseDto extends AiDescriptionResult {
  const AiDescriptionResponseDto({
    required super.markdown,
    required super.remainingGenerations,
    required super.isDescription,
  });

  factory AiDescriptionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AiDescriptionResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AiDescriptionResponseDtoToJson(this);
}
