import 'package:firebase_analytics/firebase_analytics.dart';

import '../config/app_env.dart';

/// Envoltorio de Firebase Analytics. En desarrollo es un no-op para no
/// ensuciar los dashboards de producción con eventos de prueba.
abstract final class AppAnalytics {
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!AppEnv.isProd) {
      return;
    }
    await FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
    );
  }
}
