import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/app_env.dart';
import 'sentry_pii_scrubber.dart';

/// Sentry solo se activa en `prod`. En desarrollo, todo error va a consola
/// — nunca a Sentry (regla del contrato).
abstract final class AppSentry {
  static Future<void> runGuarded(Future<void> Function() body) async {
    if (!AppEnv.isProd || AppEnv.sentryDsn.isEmpty) {
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint(details.exceptionAsString());
      };
      await body();
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = AppEnv.sentryDsn;
      options.tracesSampleRate = 0.2;
      options.environment = AppEnv.flavor;
      // Ningún evento ni breadcrumb sale del dispositivo sin pasar por el
      // scrubber de PII (`kPiiDenylist`); ver `sentry_pii_scrubber.dart`.
      options.beforeSend = SentryPiiScrubber.beforeSend;
      options.beforeBreadcrumb = SentryPiiScrubber.beforeBreadcrumb;
    }, appRunner: body);
  }
}
