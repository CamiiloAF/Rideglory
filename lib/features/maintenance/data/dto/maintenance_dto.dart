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
    required this.mode,
    this.serviceDate,
    this.odometerAtService,
    this.workshop,
    this.notes,
    this.nextDate,
    this.nextOdometer,
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
    mode: m.mode,
    serviceDate: m.serviceDate,
    odometerAtService: m.odometerAtService,
    workshop: m.workshop,
    notes: m.notes,
    nextDate: m.nextDate,
    nextOdometer: m.nextOdometer,
    cost: m.cost,
  );

  Map<String, dynamic> toJson() => _$MaintenanceDtoToJson(this);

  final String? id;
  final String? userId;
  final String? vehicleId;
  final MaintenanceType type;
  final MaintenanceMode mode;
  final DateTime? serviceDate;
  final int? odometerAtService;
  final String? workshop;
  final String? notes;
  @JsonKey(name: 'nextDate')
  final DateTime? nextDate;
  @JsonKey(name: 'nextOdometer')
  final int? nextOdometer;
  final double? cost;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MaintenanceModel toModel() => MaintenanceModel(
    id: id,
    userId: userId,
    vehicleId: vehicleId,
    type: type,
    mode: mode,
    serviceDate: serviceDate,
    odometerAtService: odometerAtService,
    workshop: workshop,
    notes: notes,
    nextDate: nextDate,
    nextOdometer: nextOdometer,
    cost: cost,
    createdDate: createdAt,
    updatedDate: updatedAt,
  );
}
