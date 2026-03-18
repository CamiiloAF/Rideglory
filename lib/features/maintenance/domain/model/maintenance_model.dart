import 'package:freezed_annotation/freezed_annotation.dart';

enum MaintenanceType {
  oilChange('Cambio de aceite'),
  preventive('Mantenimiento preventivo');

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
  final String name;
  final MaintenanceType type;
  final String? notes;
  final DateTime date;
  final DateTime? nextMaintenanceDate;
  final int maintanceMileage;
  final bool receiveAlert;
  final bool receiveMileageAlert;
  final bool receiveDateAlert;
  final int? nextMaintenanceMileage;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final double? cost;

  MaintenanceModel({
    this.id,
    this.userId,
    this.vehicleId,
    required this.name,
    required this.type,
    this.notes,
    required this.date,
    this.nextMaintenanceDate,
    required this.maintanceMileage,
    required this.receiveAlert,
    this.receiveMileageAlert = false,
    this.receiveDateAlert = false,
    this.nextMaintenanceMileage,
    this.createdDate,
    this.updatedDate,
    this.cost,
  });

  MaintenanceModel copyWith({
    String? id,
    String? name,
    MaintenanceType? type,
    String? notes,
    DateTime? date,
    DateTime? nextMaintenanceDate,
    int? maintanceMileage,
    DistanceUnit? distanceUnit,
    bool? receiveAlert,
    bool? receiveMileageAlert,
    bool? receiveDateAlert,
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
      name: name ?? this.name,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      maintanceMileage: maintanceMileage ?? this.maintanceMileage,
      receiveAlert: receiveAlert ?? this.receiveAlert,
      receiveMileageAlert: receiveMileageAlert ?? this.receiveMileageAlert,
      receiveDateAlert: receiveDateAlert ?? this.receiveDateAlert,
      nextMaintenanceMileage:
          nextMaintenanceMileage ?? this.nextMaintenanceMileage,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      cost: cost ?? this.cost,
    );
  }
}
