import 'package:sentry_flutter/sentry_flutter.dart';

import 'pii_denylist.dart';

/// Redacta PII de eventos y breadcrumbs de Sentry antes de que salgan del
/// dispositivo. [kPiiDenylist] es la fuente de verdad de qué claves se
/// consideran sensibles; esta clase es la única que la usa para mutar
/// eventos reales (contrato: Sentry sin `beforeSend`/`beforeBreadcrumb` deja
/// esa constante como código muerto).
abstract final class SentryPiiScrubber {
  static const _redacted = '[redacted]';

  static final RegExp _emailPattern = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');

  /// Celular colombiano: 10 dígitos empezando por 3.
  static final RegExp _colombianPhonePattern = RegExp(r'\b3\d{9}\b');

  /// Placa de moto colombiana: 3 letras + 2 dígitos + 1 letra.
  static final RegExp _plateePattern = RegExp(r'\b[A-Za-z]{3}\d{2}[A-Za-z]\b');

  static SentryEvent? beforeSend(SentryEvent event, Hint hint) {
    return scrubEvent(event);
  }

  static Breadcrumb? beforeBreadcrumb(Breadcrumb? breadcrumb, Hint hint) {
    if (breadcrumb == null) return null;
    return scrubBreadcrumb(breadcrumb);
  }

  static SentryEvent scrubEvent(SentryEvent event) {
    // ignore: deprecated_member_use
    event.extra = _scrubMap(event.extra);
    _scrubContexts(event.contexts);
    event.user = _scrubUser(event.user);
    event.request = _scrubRequest(event.request);
    event.message = _scrubMessage(event.message);
    event.exceptions = event.exceptions
        ?.map(_scrubException)
        .toList(growable: false);
    event.breadcrumbs = event.breadcrumbs
        ?.map(scrubBreadcrumb)
        .whereType<Breadcrumb>()
        .toList(growable: false);
    return event;
  }

  static Breadcrumb scrubBreadcrumb(Breadcrumb breadcrumb) {
    return Breadcrumb(
      message: breadcrumb.message != null
          ? scrubText(breadcrumb.message!)
          : null,
      timestamp: breadcrumb.timestamp,
      category: breadcrumb.category,
      data: _scrubMap(breadcrumb.data),
      level: breadcrumb.level,
      type: breadcrumb.type,
    );
  }

  static Map<String, dynamic>? _scrubMap(Map<String, dynamic>? source) {
    if (source == null) return null;
    final scrubbed = <String, dynamic>{};
    source.forEach((key, value) {
      if (kPiiDenylist.contains(key.toLowerCase())) {
        scrubbed[key] = _redacted;
      } else if (value is String) {
        scrubbed[key] = scrubText(value);
      } else {
        scrubbed[key] = value;
      }
    });
    return scrubbed;
  }

  static void _scrubContexts(Contexts contexts) {
    for (final key in contexts.keys.toList()) {
      if (kPiiDenylist.contains(key.toLowerCase())) {
        contexts[key] = _redacted;
      }
    }
  }

  static SentryUser? _scrubUser(SentryUser? user) {
    if (user == null) return null;
    // Se deja solo un id (hasheado si estaba presente): nunca correo,
    // usuario ni IP hacia Sentry.
    final hashedId = user.id?.hashCode.toRadixString(16);
    return SentryUser(id: hashedId ?? 'unknown');
  }

  static SentryRequest? _scrubRequest(SentryRequest? request) {
    if (request == null) return null;
    final scrubbedHeaders = <String, String>{};
    request.headers.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      if (lowerKey == 'authorization' ||
          lowerKey == 'cookie' ||
          lowerKey == 'set-cookie' ||
          kPiiDenylist.contains(lowerKey)) {
        scrubbedHeaders[key] = _redacted;
      } else {
        scrubbedHeaders[key] = value;
      }
    });
    request.headers = scrubbedHeaders;
    request.cookies = request.cookies != null ? _redacted : null;
    request.queryString = request.queryString != null ? _redacted : null;
    return request;
  }

  static SentryMessage? _scrubMessage(SentryMessage? message) {
    if (message == null) return null;
    message.formatted = scrubText(message.formatted);
    return message;
  }

  static SentryException _scrubException(SentryException exception) {
    if (exception.value != null) {
      exception.value = scrubText(exception.value!);
    }
    return exception;
  }

  /// Borra correos, celulares colombianos y placas de moto de un texto
  /// libre (mensaje de excepción, breadcrumb).
  static String scrubText(String text) {
    return text
        .replaceAll(_emailPattern, _redacted)
        .replaceAll(_colombianPhonePattern, _redacted)
        .replaceAll(_plateePattern, _redacted);
  }
}
