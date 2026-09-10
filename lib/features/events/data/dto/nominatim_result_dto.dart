import '../../domain/destination_suggestion.dart';

/// Un resultado crudo de la API de búsqueda de Nominatim (OpenStreetMap).
/// Parseo manual porque `lat`/`lon` llegan como `String`, no `num`.
class NominatimResultDto {
  const NominatimResultDto({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory NominatimResultDto.fromJson(Map<String, dynamic> json) {
    return NominatimResultDto(
      displayName: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lon: double.parse(json['lon'] as String),
    );
  }

  final String displayName;
  final double lat;
  final double lon;

  DestinationSuggestion toDomain() =>
      DestinationSuggestion(displayName: displayName, lat: lat, lng: lon);
}
