import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/core/observability/pii_denylist.dart';

void main() {
  group('kPiiDenylist', () {
    test('contains all expected PII keys', () {
      const expectedKeys = {
        'authorization',
        'id_token',
        'password',
        'email',
        'phone',
        'telefono',
        'soat',
        'placa',
        'vin',
      };
      for (final key in expectedKeys) {
        expect(
          kPiiDenylist.contains(key),
          isTrue,
          reason: 'kPiiDenylist should contain "$key"',
        );
      }
    });

    test('has expected cardinality — no unintended keys added', () {
      expect(kPiiDenylist.length, equals(9));
    });

    test('does not contain non-PII keys like event_title or http_status', () {
      expect(kPiiDenylist.contains('event_title'), isFalse);
      expect(kPiiDenylist.contains('http_status'), isFalse);
      expect(kPiiDenylist.contains('error_category'), isFalse);
    });
  });
}
