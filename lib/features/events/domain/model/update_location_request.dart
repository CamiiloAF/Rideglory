class UpdateLocationRequest {
  const UpdateLocationRequest({
    required this.eventId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.distanceMeters,
    required this.batteryPercent,
  });

  final String eventId;
  final String userId;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double distanceMeters;
  final int batteryPercent;
}
