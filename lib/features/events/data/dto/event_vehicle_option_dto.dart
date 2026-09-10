import 'package:json_annotation/json_annotation.dart';

import '../../domain/event_vehicle_option.dart';

part 'event_vehicle_option_dto.g.dart';

@JsonSerializable()
class EventVehicleOptionDto {
  const EventVehicleOptionDto({
    required this.id,
    required this.name,
    required this.brand,
    this.model,
    this.licensePlate,
  });

  factory EventVehicleOptionDto.fromJson(Map<String, dynamic> json) =>
      _$EventVehicleOptionDtoFromJson(json);

  final String id;
  final String name;
  final String brand;
  final String? model;
  @JsonKey(name: 'license_plate')
  final String? licensePlate;

  EventVehicleOption toDomain({String? imageUrl}) => EventVehicleOption(
    id: id,
    name: name,
    brand: brand,
    model: model,
    licensePlate: licensePlate,
    imageUrl: imageUrl,
  );
}
