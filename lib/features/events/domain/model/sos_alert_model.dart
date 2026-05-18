/// Represents an active SOS alert broadcast by a rider in the tracking session.
class SosAlertModel {
  const SosAlertModel({
    required this.userId,
    required this.riderName,
    this.latitude,
    this.longitude,
    this.phone,
  });

  final String userId;
  final String riderName;
  final double? latitude;
  final double? longitude;

  /// Phone number of the rider (may be null if not registered).
  final String? phone;
}
