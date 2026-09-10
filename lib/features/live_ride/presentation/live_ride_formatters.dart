import 'package:latlong2/latlong.dart';

/// Distancia en metros entre dos coordenadas (haversine, vía `latlong2`).
double liveRideDistanceMeters({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  return const Distance().as(
    LengthUnit.Meter,
    LatLng(lat1, lng1),
    LatLng(lat2, lng2),
  );
}

/// A partir de qué tan vieja es una posición se considera "sin señal"
/// (D20: nunca una alarma automática, solo información en la UI).
bool liveRideIsStale(DateTime recordedAt, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  return reference.toUtc().difference(recordedAt.toUtc()).inMinutes > 3;
}

/// Iniciales de un nombre completo para el avatar de un rider ("Camilo
/// Agudelo" → "CA").
String liveRideInitials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  final first = parts.first.substring(0, 1);
  final last = parts.length > 1 && parts.last.isNotEmpty
      ? parts.last.substring(0, 1)
      : '';
  return (first + last).toUpperCase();
}

/// Link de Google Maps para el SMS de fallback del SOS (D17), a partir de
/// las coordenadas ya obtenidas — no hace red, solo arma la URL.
String sosGoogleMapsLink(double lat, double lng) =>
    'https://maps.google.com/?q=$lat,$lng';

/// Minutos transcurridos desde [recordedAt], para interpolar en las cadenas
/// "Hace X min" / "Sin señal hace X min" del `.arb`.
int liveRideMinutesSince(DateTime recordedAt, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final minutes = reference.toUtc().difference(recordedAt.toUtc()).inMinutes;
  return minutes < 0 ? 0 : minutes;
}
