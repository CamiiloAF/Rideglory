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

enum MaintenanceMode {
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('SCHEDULED')
  scheduled,
}

/// Calculated at runtime from nextOdometer/nextDate vs currentVehicleMileage/today.
/// Only applies to mode == scheduled. Completed records have no status.
enum MaintenanceStatus {
  overdue,
  next,
  upToDate,
}

// Thresholds for status calculation
const int kMaintenanceUmbralKm = 500;
const int kMaintenanceUmbralDays = 30;

class MaintenanceModel {
  final String? id;
  final String? userId;
  final String? vehicleId;
  final MaintenanceType type;
  final MaintenanceMode mode;

  // Fields for mode == completed
  final DateTime? serviceDate;
  final int? odometerAtService;
  final String? workshop;
  final double? cost;

  // Common fields
  final String? notes;

  // Next service fields (applicable to both modes; required for scheduled)
  final DateTime? nextDate;
  final int? nextOdometer;

  final DateTime? createdDate;
  final DateTime? updatedDate;

  String get name => type.label;

  MaintenanceModel({
    this.id,
    this.userId,
    this.vehicleId,
    required this.type,
    required this.mode,
    this.serviceDate,
    this.odometerAtService,
    this.workshop,
    this.cost,
    this.notes,
    this.nextDate,
    this.nextOdometer,
    this.createdDate,
    this.updatedDate,
  });

  /// Calculates the [MaintenanceStatus] for this maintenance record given
  /// the vehicle's current mileage. Returns null for completed records.
  static MaintenanceStatus? calculateStatus(
    MaintenanceModel maintenance,
    int currentVehicleMileage,
  ) {
    if (maintenance.mode == MaintenanceMode.completed) return null;

    final now = DateTime.now();
    final overdueByKm = maintenance.nextOdometer != null &&
        currentVehicleMileage > maintenance.nextOdometer!;
    final overdueByDate = maintenance.nextDate != null &&
        now.isAfter(maintenance.nextDate!);

    if (overdueByKm || overdueByDate) return MaintenanceStatus.overdue;

    final nextByKm = maintenance.nextOdometer != null &&
        (maintenance.nextOdometer! - currentVehicleMileage) <= kMaintenanceUmbralKm;
    final nextByDate = maintenance.nextDate != null &&
        maintenance.nextDate!.difference(now).inDays <= kMaintenanceUmbralDays;

    if (nextByKm || nextByDate) return MaintenanceStatus.next;

    return MaintenanceStatus.upToDate;
  }

  MaintenanceModel copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    MaintenanceType? type,
    MaintenanceMode? mode,
    DateTime? serviceDate,
    int? odometerAtService,
    String? workshop,
    double? cost,
    String? notes,
    DateTime? nextDate,
    int? nextOdometer,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return MaintenanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      mode: mode ?? this.mode,
      serviceDate: serviceDate ?? this.serviceDate,
      odometerAtService: odometerAtService ?? this.odometerAtService,
      workshop: workshop ?? this.workshop,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      nextDate: nextDate ?? this.nextDate,
      nextOdometer: nextOdometer ?? this.nextOdometer,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}
