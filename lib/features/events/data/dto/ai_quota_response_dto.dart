import 'package:json_annotation/json_annotation.dart';

part 'ai_quota_response_dto.g.dart';

@JsonSerializable()
class AiQuotaResponseDto {
  const AiQuotaResponseDto({required this.descriptionRemaining});

  final int descriptionRemaining;

  factory AiQuotaResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AiQuotaResponseDtoFromJson(json);
}
