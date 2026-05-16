import 'package:json_annotation/json_annotation.dart';

enum MaintenanceType {
  @JsonValue('OIL_CHANGE')
  oilChange('Cambio de aceite'),
  @JsonValue('BRAKE_CHECK')
  brakeCheck('Revisión de frenos'),
  @JsonValue('TIRE_CHANGE')
  tireChange('Cambio de llantas'),
  @JsonValue('PREVENTIVE')
  preventive('Revisión general'),
  @JsonValue('AIR_FILTER')
  airFilter('Filtro de aire'),
  @JsonValue('CHAIN_SPROCKET')
  chainSprocket('Cadena y piñones'),
  @JsonValue('ELECTRICAL')
  electrical('Electricidad'),
  @JsonValue('OTHER')
  other('Otro');

  final String label;
  const MaintenanceType(this.label);
}

enum DistanceUnit {
  @JsonValue('kilometers')
  kilometers('KM'),
  @JsonValue('miles')
  miles('Millas');

  final String label;
  const DistanceUnit(this.label);
}

class MaintenanceModel {
  final String? id;
  final String? userId;
  final String? vehicleId;
  final MaintenanceType type;
  final String? notes;
  final DateTime date;
  final DateTime? nextMaintenanceDate;
  final int maintanceMileage;
  final bool isScheduled;
  final int? nextMaintenanceMileage;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final double? cost;

  String get name => type.label;

  MaintenanceModel({
    this.id,
    this.userId,
    this.vehicleId,
    required this.type,
    this.notes,
    required this.date,
    this.nextMaintenanceDate,
    required this.maintanceMileage,
    this.isScheduled = false,
    this.nextMaintenanceMileage,
    this.createdDate,
    this.updatedDate,
    this.cost,
  });

  MaintenanceModel copyWith({
    String? id,
    MaintenanceType? type,
    String? notes,
    DateTime? date,
    DateTime? nextMaintenanceDate,
    int? maintanceMileage,
    DistanceUnit? distanceUnit,
    bool? isScheduled,
    int? nextMaintenanceMileage,
    String? userId,
    String? vehicleId,
    DateTime? createdDate,
    DateTime? updatedDate,
    double? cost,
  }) {
    return MaintenanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      maintanceMileage: maintanceMileage ?? this.maintanceMileage,
      isScheduled: isScheduled ?? this.isScheduled,
      nextMaintenanceMileage:
          nextMaintenanceMileage ?? this.nextMaintenanceMileage,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      cost: cost ?? this.cost,
    );
  }
}
