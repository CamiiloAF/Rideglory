import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/core/observability/sentry_pii_scrubber.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('SentryPiiScrubber.beforeSend', () {
    test('redacts denylisted keys from extra, contexts and request', () {
      final event = SentryEvent(
        // ignore: deprecated_member_use
        extra: const {
          'email': 'rider@rideglory.co',
          'event_title': 'Rodada al Nevado',
        },
        user: SentryUser(id: 'user-123', email: 'rider@rideglory.co'),
        request: SentryRequest(
          url: 'https://api.rideglory.co/vehicles',
          headers: const {
            'Authorization': 'Bearer secret-token',
            'Content-Type': 'application/json',
          },
          queryString: 'placa=abc12d',
        )..cookies = 'session=abc',
      );
      event.contexts['placa'] = 'ABC12D';
      event.contexts['error_category'] = 'network';

      final scrubbed = SentryPiiScrubber.beforeSend(event, Hint())!;

      // ignore: deprecated_member_use
      expect(scrubbed.extra!['email'], '[redacted]');
      // ignore: deprecated_member_use
      expect(scrubbed.extra!['event_title'], 'Rodada al Nevado');
      expect(scrubbed.contexts['placa'], '[redacted]');
      expect(scrubbed.contexts['error_category'], 'network');
      expect(scrubbed.request!.headers['Authorization'], '[redacted]');
      expect(scrubbed.request!.headers['Content-Type'], 'application/json');
      expect(scrubbed.request!.cookies, '[redacted]');
      expect(scrubbed.request!.queryString, '[redacted]');
    });

    test('leaves only a hashed id on the user, drops email and ip', () {
      final event = SentryEvent(
        user: SentryUser(
          id: 'user-123',
          email: 'rider@rideglory.co',
          ipAddress: '1.2.3.4',
        ),
      );

      final scrubbed = SentryPiiScrubber.beforeSend(event, Hint())!;

      expect(scrubbed.user!.email, isNull);
      expect(scrubbed.user!.ipAddress, isNull);
      expect(scrubbed.user!.id, isNotNull);
      expect(scrubbed.user!.id, isNot('user-123'));
    });

    test('scrubs emails, colombian phones and moto plates from exception '
        'messages', () {
      final event = SentryEvent(
        exceptions: [
          SentryException(
            type: 'AuthException',
            value:
                'Fallo con correo rider@rideglory.co, celular 3001234567 '
                'y placa ABC12D',
          ),
        ],
      );

      final scrubbed = SentryPiiScrubber.beforeSend(event, Hint())!;

      final message = scrubbed.exceptions!.first.value!;
      expect(message.contains('rider@rideglory.co'), isFalse);
      expect(message.contains('3001234567'), isFalse);
      expect(message.contains('ABC12D'), isFalse);
      expect(message.contains('[redacted]'), isTrue);
    });
  });

  group('SentryPiiScrubber.beforeBreadcrumb', () {
    test('redacts denylisted keys from breadcrumb data', () {
      final breadcrumb = Breadcrumb(
        message: 'Contacto de emergencia: 3001234567',
        data: const {'phone': '3001234567', 'action': 'sos_sent'},
      );

      final scrubbed = SentryPiiScrubber.beforeBreadcrumb(breadcrumb, Hint())!;

      expect(scrubbed.data!['phone'], '[redacted]');
      expect(scrubbed.data!['action'], 'sos_sent');
      expect(scrubbed.message!.contains('3001234567'), isFalse);
    });

    test('returns null when breadcrumb is null', () {
      expect(SentryPiiScrubber.beforeBreadcrumb(null, Hint()), isNull);
    });
  });
}
