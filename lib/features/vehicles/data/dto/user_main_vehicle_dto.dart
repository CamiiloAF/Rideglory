import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/vehicles/domain/models/user_main_vehicle_model.dart';

part 'user_main_vehicle_dto.g.dart';

@JsonSerializable()
class UserMainVehicleDto {
  final String userId;
  final String mainVehicleId;
  final DateTime? updatedAt;

  const UserMainVehicleDto({
    required this.userId,
    required this.mainVehicleId,
    this.updatedAt,
  });

  factory UserMainVehicleDto.fromJson(Map<String, dynamic> json) =>
      _$UserMainVehicleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserMainVehicleDtoToJson(this);

  /// Convert DTO to domain model
  UserMainVehicleModel toModel() {
    return UserMainVehicleModel(
      userId: userId,
      mainVehicleId: mainVehicleId,
      updatedAt: updatedAt,
    );
  }

  /// Create DTO from domain model
  factory UserMainVehicleDto.fromModel(UserMainVehicleModel model) {
    return UserMainVehicleDto(
      userId: model.userId,
      mainVehicleId: model.mainVehicleId,
      updatedAt: model.updatedAt,
    );
  }
}

/// Extension to convert domain model to JSON
extension UserMainVehicleModelExtension on UserMainVehicleModel {
  Map<String, dynamic> toJson() => UserMainVehicleDto.fromModel(this).toJson();
}
