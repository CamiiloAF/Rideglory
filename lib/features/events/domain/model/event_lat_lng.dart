class EventLatLng {
  final double latitude;
  final double longitude;

  const EventLatLng({required this.latitude, required this.longitude});

  String get mapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory EventLatLng.fromJson(Map<String, dynamic> json) => EventLatLng(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  EventLatLng copyWith({double? latitude, double? longitude}) => EventLatLng(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventLatLng &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
