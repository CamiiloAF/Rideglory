import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/live_ride/presentation/live_ride_formatters.dart';
import 'package:rideglory/l10n/app_localizations_es.dart';

/// D17: el cuerpo del SMS de fallback del SOS ya no vive hardcodeado en
/// Dart — lo arma `context.l10n.sos_sms_body` sobre `sosGoogleMapsLink`.
void main() {
  final l10n = AppLocalizationsEs();

  test('sosGoogleMapsLink arma la URL de Google Maps con las coordenadas', () {
    expect(
      sosGoogleMapsLink(4.6, -74.1),
      'https://maps.google.com/?q=4.6,-74.1',
    );
  });

  test('sos_sms_body interpola coordenadas y link en el cuerpo del SMS', () {
    final lat = 4.6.toString();
    final lng = (-74.1).toString();
    final link = sosGoogleMapsLink(4.6, -74.1);

    final body = l10n.sos_sms_body(lat, lng, link);

    expect(
      body,
      'Necesito ayuda. Mi ubicación: 4.6,-74.1 '
      'https://maps.google.com/?q=4.6,-74.1',
    );
  });
}
