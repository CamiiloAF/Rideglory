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
  final String name;
  final MaintenanceType type;
  final String? notes;
  final DateTime date;
  final DateTime? nextMaintenanceDate;
  final double maintanceMileage;
  final DistanceUnit distanceUnit;
  final bool receiveAlert;
  final double? nextMaintenanceMileage;
  final DateTime? createdDate;
  final DateTime? updatedDate;

  MaintenanceModel({
    this.id,
    required this.name,
    required this.type,
    this.notes,
    required this.date,
    this.nextMaintenanceDate,
    required this.maintanceMileage,
    required this.distanceUnit,
    required this.receiveAlert,
    this.nextMaintenanceMileage,
    this.userId,
    this.createdDate,
    this.updatedDate,
  });

  MaintenanceModel copyWith({
    String? id,
    String? name,
    MaintenanceType? type,
    String? notes,
    DateTime? date,
    DateTime? nextMaintenanceDate,
    double? maintanceMileage,
    DistanceUnit? distanceUnit,
    bool? receiveAlert,
    double? nextMaintenanceMileage,
    String? userId,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return MaintenanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      maintanceMileage: maintanceMileage ?? this.maintanceMileage,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      receiveAlert: receiveAlert ?? this.receiveAlert,
      nextMaintenanceMileage:
          nextMaintenanceMileage ?? this.nextMaintenanceMileage,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}
