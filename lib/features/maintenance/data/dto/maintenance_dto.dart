import 'package:json_annotation/json_annotation.dart';

import '../../domain/maintenance.dart';

part 'maintenance_dto.g.dart';

/// DTO de una fila de `maintenances`, con la moto embebida por el `select`
/// (`vehicles(name, brand, model)`) para no hacer una consulta por fila.
@JsonSerializable(explicitToJson: true)
class MaintenanceDto {
  const MaintenanceDto({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.serviceDate,
    required this.odometer,
    this.cost,
    this.workshop,
    this.notes,
    this.nextDate,
    this.nextOdometer,
    this.vehicle,
  });

  factory MaintenanceDto.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceDtoToJson(this);

  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final String type;
  @JsonKey(name: 'service_date')
  final DateTime serviceDate;
  final int odometer;
  final double? cost;
  final String? workshop;
  final String? notes;
  @JsonKey(name: 'next_date')
  final DateTime? nextDate;
  @JsonKey(name: 'next_odometer')
  final int? nextOdometer;
  @JsonKey(name: 'vehicles')
  final EmbeddedVehicleDto? vehicle;

  Maintenance toDomain() {
    return Maintenance(
      id: id,
      vehicleId: vehicleId,
      vehicleDisplayName: vehicle?.toDisplayName() ?? '',
      type: type,
      serviceDate: serviceDate,
      odometer: odometer,
      cost: cost,
      workshop: workshop,
      notes: notes,
      nextDate: nextDate,
      nextOdometer: nextOdometer,
    );
  }
}

@JsonSerializable()
class EmbeddedVehicleDto {
  const EmbeddedVehicleDto({
    required this.name,
    required this.brand,
    this.model,
  });

  factory EmbeddedVehicleDto.fromJson(Map<String, dynamic> json) =>
      _$EmbeddedVehicleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EmbeddedVehicleDtoToJson(this);

  final String name;
  final String brand;
  final String? model;

  String toDisplayName() {
    final modelLabel = model?.trim();
    if (modelLabel != null && modelLabel.isNotEmpty) {
      return '$brand $modelLabel';
    }
    return name;
  }
}
