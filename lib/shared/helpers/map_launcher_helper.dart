import 'package:rideglory/shared/helpers/url_launcher_helper.dart';

abstract final class MapLauncherHelper {
  MapLauncherHelper._();

  static Future<void> openSearchByAddress(String address) {
    final trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty) {
      return Future.value();
    }

    final encodedAddress = Uri.encodeComponent(trimmedAddress);
    return UrlLauncherHelper.openUrl(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    );
  }

  static Future<void> openDirections({
    required String origin,
    required String destination,
  }) {
    final trimmedOrigin = origin.trim();
    final trimmedDestination = destination.trim();
    if (trimmedOrigin.isEmpty || trimmedDestination.isEmpty) {
      return Future.value();
    }

    final encodedOrigin = Uri.encodeComponent(trimmedOrigin);
    final encodedDestination = Uri.encodeComponent(trimmedDestination);
    return UrlLauncherHelper.openUrl(
      'https://www.google.com/maps/dir/?api=1&origin=$encodedOrigin&destination=$encodedDestination',
    );
  }
}
