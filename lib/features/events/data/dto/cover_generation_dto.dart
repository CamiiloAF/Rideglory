import 'package:json_annotation/json_annotation.dart';

part 'cover_generation_dto.g.dart';

@JsonSerializable()
class CoverGenerationDto {
  const CoverGenerationDto({
    required this.imageUrl,
    required this.source,
    required this.query,
  });

  final String imageUrl;
  final String source;
  final String query;

  factory CoverGenerationDto.fromJson(Map<String, dynamic> json) =>
      _$CoverGenerationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CoverGenerationDtoToJson(this);
}
