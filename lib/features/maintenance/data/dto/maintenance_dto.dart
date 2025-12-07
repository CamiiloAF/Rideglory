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
    required super.currentMileage,
    required super.distanceUnit,
    required super.receiveAlert,
    required super.notes,
    required super.nextMaintenanceDate,
    required super.nextMaintenanceMileage,
  });

  factory MaintenanceDto.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceDtoToJson(this);

  MaintenanceModel toModel() {
    return MaintenanceModel(
      id: id,
      name: name,
      type: type,
      date: date,
      currentMileage: currentMileage,
      distanceUnit: distanceUnit,
      receiveAlert: receiveAlert,
      notes: notes,
      nextMaintenanceDate: nextMaintenanceDate,
      nextMaintenanceMileage: nextMaintenanceMileage,
    );
  }
}

extension MaintenanceModelExtension on MaintenanceModel {
  Map<String, dynamic> toJson() => MaintenanceDto(
    id: id,
    name: name,
    type: type,
    date: date,
    currentMileage: currentMileage,
    distanceUnit: distanceUnit,
    receiveAlert: receiveAlert,
    notes: notes,
    nextMaintenanceDate: nextMaintenanceDate,
    nextMaintenanceMileage: nextMaintenanceMileage,
  ).toJson();
}
