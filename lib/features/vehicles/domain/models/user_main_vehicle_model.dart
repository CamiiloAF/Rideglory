/// Model representing the user's main vehicle preference
///
/// Contains userId, mainVehicleId, and when it was last updated
class UserMainVehicleModel {
  final String userId;
  final String mainVehicleId;
  final DateTime? updatedAt;

  const UserMainVehicleModel({
    required this.userId,
    required this.mainVehicleId,
    this.updatedAt,
  });

  UserMainVehicleModel copyWith({
    String? userId,
    String? mainVehicleId,
    DateTime? updatedAt,
  }) {
    return UserMainVehicleModel(
      userId: userId ?? this.userId,
      mainVehicleId: mainVehicleId ?? this.mainVehicleId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserMainVehicleModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          mainVehicleId == other.mainVehicleId &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      userId.hashCode ^ mainVehicleId.hashCode ^ updatedAt.hashCode;

  @override
  String toString() =>
      'UserMainVehicleModel(userId: $userId, mainVehicleId: $mainVehicleId, updatedAt: $updatedAt)';
}
