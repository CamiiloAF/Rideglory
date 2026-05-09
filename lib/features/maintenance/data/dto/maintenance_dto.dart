import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

part 'maintenance_dto.g.dart';

@JsonSerializable(converters: apiJsonDateTimeConverters)
class MaintenanceDto {
  const MaintenanceDto({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.name,
    required this.type,
    this.notes,
    required this.date,
    this.nextMaintenanceDate,
    required this.maintanceMileage,
    required this.receiveAlert,
    required this.receiveMileageAlert,
    required this.receiveDateAlert,
    this.nextMaintenanceMileage,
    this.cost,
    this.createdAt,
    this.updatedAt,
  });

  factory MaintenanceDto.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceDtoToJson(this);

  final String id;
  final String userId;
  final String vehicleId;
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
  final double? cost;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MaintenanceModel toModel() => MaintenanceModel(
        id: id,
        userId: userId,
        vehicleId: vehicleId,
        name: name,
        type: type,
        notes: notes,
        date: date,
        nextMaintenanceDate: nextMaintenanceDate,
        maintanceMileage: maintanceMileage,
        receiveAlert: receiveAlert,
        receiveMileageAlert: receiveMileageAlert,
        receiveDateAlert: receiveDateAlert,
        nextMaintenanceMileage: nextMaintenanceMileage,
        cost: cost,
        createdDate: createdAt,
        updatedDate: updatedAt,
      );
}
