import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/maintenance/data/dto/maintenance_dto.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';

part 'vehicle_maintenances_list_response_dto.g.dart';

@JsonSerializable(converters: apiJsonDateTimeConverters)
class MaintenanceListSummaryDto {
  const MaintenanceListSummaryDto({
    this.lastServiceDate,
    this.lastServiceMileage,
    this.nextServiceDate,
  });

  factory MaintenanceListSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceListSummaryDtoFromJson(json);

  final DateTime? lastServiceDate;
  final int? lastServiceMileage;
  final DateTime? nextServiceDate;

  MaintenanceListSummary toModel() => MaintenanceListSummary(
    lastServiceDate: lastServiceDate,
    lastServiceMileage: lastServiceMileage,
    nextServiceDate: nextServiceDate,
  );
}

@JsonSerializable(converters: apiJsonDateTimeConverters)
class VehicleMaintenancesListResponseDto {
  const VehicleMaintenancesListResponseDto({
    required this.items,
    required this.summary,
  });

  factory VehicleMaintenancesListResponseDto.fromJson(
    Map<String, dynamic> json,
  ) => _$VehicleMaintenancesListResponseDtoFromJson(json);

  final List<MaintenanceDto> items;
  final MaintenanceListSummaryDto summary;
}
