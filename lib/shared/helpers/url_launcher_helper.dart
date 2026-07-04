import 'package:url_launcher/url_launcher.dart' as launcher;

abstract final class UrlLauncherHelper {
  UrlLauncherHelper._();

  /// Intenta abrir [url] en una app externa. Devuelve `true` si se lanzó y
  /// `false` si ninguna app puede manejarlo o la plataforma rechazó el intento.
  /// NO se traga el fallo en silencio: el caller decide si mostrar feedback.
  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launcher.canLaunchUrl(uri)) return false;
      return await launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
    } catch (_) {
      // canLaunchUrl/launchUrl pueden lanzar (p. ej. sin plugin en tests, o
      // PlatformException en device). Se trata como "no se pudo abrir".
      return false;
    }
  }

  static String sanitizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^\d+]'), '');

  static Future<bool> openPhone(String phone) => openUrl('tel:$phone');

  /// Intenta el esquema directo de WhatsApp y, si no está disponible, cae al
  /// enlace universal `wa.me` (que un navegador puede resolver).
  static Future<bool> openWhatsApp(String phone) async {
    final sanitized = sanitizePhone(phone);
    if (await openUrl('whatsapp://send?phone=$sanitized')) return true;
    return openUrl('https://wa.me/$sanitized');
  }
}
