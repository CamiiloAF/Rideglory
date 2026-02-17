import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

part 'maintenance_dto.g.dart';

@JsonSerializable()
class MaintenanceDto extends MaintenanceModel {
  MaintenanceDto({
    required super.id,
    required super.name,
    required super.type,
    required super.date,
    required super.maintanceMileage,
    required super.distanceUnit,
    required super.receiveAlert,
    required super.notes,
    required super.nextMaintenanceDate,
    required super.nextMaintenanceMileage,
    required super.userId,
    required super.vehicleId,
    required super.createdDate,
    required super.updatedDate,
  });

  factory MaintenanceDto.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceDtoToJson(this);
}

extension MaintenanceModelExtension on MaintenanceModel {
  Map<String, dynamic> toJson() => MaintenanceDto(
    id: id,
    name: name,
    type: type,
    date: date,
    maintanceMileage: maintanceMileage,
    distanceUnit: distanceUnit,
    receiveAlert: receiveAlert,
    notes: notes,
    nextMaintenanceDate: nextMaintenanceDate,
    nextMaintenanceMileage: nextMaintenanceMileage,
    userId: userId,
    vehicleId: vehicleId,
    createdDate: createdDate,
    updatedDate: updatedDate,
  ).toJson();
}
