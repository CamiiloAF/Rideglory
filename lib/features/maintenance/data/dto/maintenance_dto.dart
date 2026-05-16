import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

part 'maintenance_dto.g.dart';

@JsonSerializable(converters: apiJsonDateTimeConverters, includeIfNull: false)
class MaintenanceDto {
  const MaintenanceDto({
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
    this.cost,
    this.createdAt,
    this.updatedAt,
  });

  factory MaintenanceDto.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceDtoFromJson(json);

  factory MaintenanceDto.fromModel(MaintenanceModel m) => MaintenanceDto(
    id: m.id,
    userId: m.userId,
    vehicleId: m.vehicleId,
    type: m.type,
    notes: m.notes,
    date: m.date,
    nextMaintenanceDate: m.nextMaintenanceDate,
    maintanceMileage: m.maintanceMileage,
    isScheduled: m.isScheduled,
    nextMaintenanceMileage: m.nextMaintenanceMileage,
    cost: m.cost,
  );

  Map<String, dynamic> toJson() {
    final json = _$MaintenanceDtoToJson(this);
    json['date'] = apiEncodeRequiredDateTime(date);
    return json;
  }

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
  final double? cost;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MaintenanceModel toModel() => MaintenanceModel(
    id: id,
    userId: userId,
    vehicleId: vehicleId,
    type: type,
    notes: notes,
    date: date,
    nextMaintenanceDate: nextMaintenanceDate,
    maintanceMileage: maintanceMileage,
    isScheduled: isScheduled,
    nextMaintenanceMileage: nextMaintenanceMileage,
    cost: cost,
    createdDate: createdAt,
    updatedDate: updatedAt,
  );
}
