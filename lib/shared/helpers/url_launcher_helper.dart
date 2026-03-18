import 'package:url_launcher/url_launcher.dart' as launcher;

abstract final class UrlLauncherHelper {
  UrlLauncherHelper._();

  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
    }
  }

  static String sanitizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^\d+]'), '');

  static Future<void> openPhone(String phone) => openUrl('tel:$phone');

  static Future<void> openWhatsApp(String phone) =>
      openUrl('https://wa.me/${sanitizePhone(phone)}');
}
