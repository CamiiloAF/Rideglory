import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/shared/models/address_location.dart';

part 'place_suggestion_dto.g.dart';

@JsonSerializable()
class PlaceSuggestionDto {
  const PlaceSuggestionDto({
    required this.name,
    this.placeId,
    this.latitude,
    this.longitude,
  });

  final String name;
  @JsonKey(name: 'placeId')
  final String? placeId;
  final double? latitude;
  final double? longitude;

  AddressLocation? get location => latitude != null && longitude != null
      ? AddressLocation(latitude: latitude!, longitude: longitude!, label: name)
      : null;

  factory PlaceSuggestionDto.fromJson(Map<String, dynamic> json) =>
      _$PlaceSuggestionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceSuggestionDtoToJson(this);
}
