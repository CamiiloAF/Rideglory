/// A resolved geographic coordinate with an optional human-readable label.
class AddressLocation {
  const AddressLocation({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  final double latitude;
  final double longitude;
  final String? label;
}
