import 'package:json_annotation/json_annotation.dart';

import '../../domain/vehicle_option.dart';

part 'vehicle_option_dto.g.dart';

/// DTO de la fila mínima de `vehicles` que necesita mantenimiento: id,
/// nombre/modelo para mostrar, placa y odómetro.
@JsonSerializable()
class VehicleOptionDto {
  const VehicleOptionDto({
    required this.id,
    required this.name,
    required this.brand,
    this.model,
    this.licensePlate,
    required this.currentMileage,
    required this.isMain,
  });

  factory VehicleOptionDto.fromJson(Map<String, dynamic> json) =>
      _$VehicleOptionDtoFromJson(json);

  final String id;
  final String name;
  final String brand;
  final String? model;
  @JsonKey(name: 'license_plate')
  final String? licensePlate;
  @JsonKey(name: 'current_mileage')
  final int currentMileage;
  @JsonKey(name: 'is_main')
  final bool isMain;

  VehicleOption toDomain() {
    final modelLabel = model?.trim();
    final displayName = (modelLabel != null && modelLabel.isNotEmpty)
        ? '$brand $modelLabel'
        : name;
    final chipLabel = (modelLabel != null && modelLabel.isNotEmpty)
        ? modelLabel
        : name;
    return VehicleOption(
      id: id,
      displayName: displayName,
      chipLabel: chipLabel,
      licensePlate: licensePlate,
      currentMileage: currentMileage,
      isMain: isMain,
    );
  }
}
