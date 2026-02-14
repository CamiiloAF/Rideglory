enum MaintenanceType {
  oilChange('Cambio de aceite'),
  preventive('Mantenimiento preventivo');

  final String label;
  const MaintenanceType(this.label);
}

enum DistanceUnit {
  kilometers('KM'),
  miles('Millas');

  final String label;
  const DistanceUnit(this.label);
}

class MaintenanceModel {
  final String? id;
  final String name;
  final MaintenanceType type;
  final String? notes;
  final DateTime date;
  final DateTime? nextMaintenanceDate;
  final double maintanceMileage;
  final DistanceUnit distanceUnit;
  final bool receiveAlert;
  final double? nextMaintenanceMileage;

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
  }) {
    return MaintenanceModel(
      id: id ?? this.id,
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
    );
  }
}
