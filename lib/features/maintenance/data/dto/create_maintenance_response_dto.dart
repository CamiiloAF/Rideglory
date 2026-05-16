import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/maintenance/data/dto/maintenance_dto.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

part 'create_maintenance_response_dto.g.dart';

/// Response from POST /api/maintenances/vehicle/:vehicleId
/// Contains 1 record (scheduled mode or completed without next fields)
/// or 2 records (completed mode with nextKmInterval or nextDate).
@JsonSerializable(converters: apiJsonDateTimeConverters)
class CreateMaintenanceResponseDto {
  const CreateMaintenanceResponseDto({required this.created});

  factory CreateMaintenanceResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CreateMaintenanceResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateMaintenanceResponseDtoToJson(this);

  final List<MaintenanceDto> created;

  List<MaintenanceModel> toModels() => created.map((dto) => dto.toModel()).toList();
}
