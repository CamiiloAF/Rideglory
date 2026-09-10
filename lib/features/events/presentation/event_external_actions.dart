import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Abre el destino en la app de mapas del sistema (Waze/Google Maps en
/// Android via `geo:`, Apple Maps en iOS via `maps:`). Sin mapa embebido
/// en v2 (D10): esta es la única forma de navegar al punto exacto.
Future<void> openMapsForDestination({
  required double lat,
  required double lng,
  required String label,
}) async {
  final query = Uri.encodeComponent(label);
  final uri = Platform.isIOS
      ? Uri.parse('maps:$lat,$lng?q=$query')
      : Uri.parse('geo:$lat,$lng?q=$lat,$lng($query)');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Abre el marcador telefónico con el número precargado. Nunca hace la
/// llamada por sí solo -- el rider siempre confirma en su propia app.
Future<void> openPhoneDialer(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
