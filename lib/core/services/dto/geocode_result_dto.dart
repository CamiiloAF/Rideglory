import 'package:json_annotation/json_annotation.dart';

part 'geocode_result_dto.g.dart';

@JsonSerializable()
class GeocodeResultDto {
  const GeocodeResultDto({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
  });

  final double latitude;
  final double longitude;
  final String? formattedAddress;

  factory GeocodeResultDto.fromJson(Map<String, dynamic> json) =>
      _$GeocodeResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GeocodeResultDtoToJson(this);
}
