import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

part 'maintenance_dto.g.dart';

@JsonSerializable(converters: apiJsonDateTimeConverters, includeIfNull: false)
class MaintenanceDto extends MaintenanceModel {
  // ignore: prefer_const_constructors_in_immutables
  MaintenanceDto({
    super.id,
    super.userId,
    super.vehicleId,
    required super.type,
    required super.mode,
    super.serviceDate,
    super.odometerAtService,
    super.workshop,
    super.cost,
    super.notes,
    super.nextDate,
    super.nextOdometer,
    @JsonKey(name: 'createdAt') super.createdDate,
    @JsonKey(name: 'updatedAt') super.updatedDate,
  });

  factory MaintenanceDto.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceDtoToJson(this);
}

extension MaintenanceModelExtension on MaintenanceModel {
  Map<String, dynamic> toJson() => MaintenanceDto(
    id: id,
    userId: userId,
    vehicleId: vehicleId,
    type: type,
    mode: mode,
    serviceDate: serviceDate,
    odometerAtService: odometerAtService,
    workshop: workshop,
    cost: cost,
    notes: notes,
    nextDate: nextDate,
    nextOdometer: nextOdometer,
    createdDate: createdDate,
    updatedDate: updatedDate,
  ).toJson();
}
