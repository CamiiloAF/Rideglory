import 'package:url_launcher/url_launcher.dart';

/// D17/D18: acciones de fallback sin datos del SOS activo. Nunca marcan ni
/// envían por sí solas — siempre abren la app nativa con el contenido
/// precargado para que el rider confirme.
Future<void> openSosPhoneDialer(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// SMS con las coordenadas y un link de Google Maps, para cuando no hay
/// datos móviles pero sí señal de voz/SMS.
Future<void> openSosSms({
  required String phone,
  required double lat,
  required double lng,
}) async {
  final body =
      'Necesito ayuda. Mi ubicación: $lat,$lng '
      'https://maps.google.com/?q=$lat,$lng';
  final uri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': body});
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
