import 'package:flutter/widgets.dart';

import '../../../l10n/l10n_extensions.dart';
import 'live_ride_formatters.dart';

/// "A 350 m" / "A 1,2 km". Sin `BuildContext` no hay `l10n`, así que este
/// formateo vive en presentación (mismo patrón de `event_labels.dart`).
String liveRideDistanceLabel(BuildContext context, double meters) {
  if (meters < 1000) {
    return context.l10n.live_distance_meters(meters.round());
  }
  final km = meters / 1000;
  final rounded = (km * 10).round() / 10;
  final label = rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toStringAsFixed(1).replaceAll('.', ',');
  return context.l10n.live_distance_km(label);
}

/// "Hace 2 min" para una posición fresca.
String liveRideFreshnessLabel(BuildContext context, DateTime recordedAt) {
  final minutes = liveRideMinutesSince(recordedAt);
  return minutes <= 0
      ? context.l10n.live_freshness_now
      : context.l10n.live_freshness_minutes(minutes);
}

/// "Sin señal hace 6 min" para una posición vieja (D20: solo información,
/// nunca una alarma automática).
String liveRideStaleLabel(BuildContext context, DateTime recordedAt) {
  final minutes = liveRideMinutesSince(recordedAt);
  return context.l10n.live_freshness_stale_minutes(minutes);
}
