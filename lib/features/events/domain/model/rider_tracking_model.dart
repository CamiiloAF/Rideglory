enum RiderTrackingRole {
  lead,
  rider;

  static RiderTrackingRole fromStorage(String? value) {
    switch (value) {
      case 'lead':
        return RiderTrackingRole.lead;
      case 'rider':
        return RiderTrackingRole.rider;
      default:
        return RiderTrackingRole.rider;
    }
  }
}

class RiderTrackingModel {
  const RiderTrackingModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.distanceMeters,
    required this.batteryPercent,
    required this.isActive,
    required this.deviceLabel,
    required this.lastUpdated,
  });

  final String userId;
  final String firstName;
  final String lastName;

  /// Role in the live tracking session (stored as string in Firestore).
  final RiderTrackingRole role;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double distanceMeters;
  final int batteryPercent;
  final bool isActive;
  final String deviceLabel;
  final DateTime lastUpdated;

  RiderTrackingModel copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    RiderTrackingRole? role,
    double? latitude,
    double? longitude,
    double? speedKmh,
    double? distanceMeters,
    int? batteryPercent,
    bool? isActive,
    String? deviceLabel,
    DateTime? lastUpdated,
  }) {
    return RiderTrackingModel(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedKmh: speedKmh ?? this.speedKmh,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isActive: isActive ?? this.isActive,
      deviceLabel: deviceLabel ?? this.deviceLabel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
