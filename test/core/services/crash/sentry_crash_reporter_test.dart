import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:rideglory/core/observability/pii_denylist.dart';
import 'package:rideglory/core/services/crash/sentry_crash_reporter.dart';

void main() {
  group('scrubPiiFromEvent', () {
    test('returns event unchanged when tags are null', () {
      final event = SentryEvent();
      final result = scrubPiiFromEvent(event);
      expect(result.tags, isNull);
    });

    test('returns event unchanged when tags are empty', () {
      final event = SentryEvent(tags: const {});
      final result = scrubPiiFromEvent(event);
      expect(result.tags, isEmpty);
    });

    test('redacts PII keys in tags', () {
      for (final piiKey in kPiiDenylist) {
        final event = SentryEvent(tags: {piiKey: 'sensitive-value'});
        final result = scrubPiiFromEvent(event);
        expect(
          result.tags?[piiKey],
          equals('[redacted]'),
          reason: 'Tag "$piiKey" should be redacted',
        );
      }
    });

    test('preserves non-PII keys in tags', () {
      final event = SentryEvent(
        tags: const {
          'http_status': '500',
          'error_category': 'network',
          'endpoint': '/api/events',
        },
      );
      final result = scrubPiiFromEvent(event);
      expect(result.tags?['http_status'], equals('500'));
      expect(result.tags?['error_category'], equals('network'));
      expect(result.tags?['endpoint'], equals('/api/events'));
    });

    test('redacts PII keys while preserving non-PII keys in same event', () {
      final event = SentryEvent(
        tags: const {
          'email': 'user@example.com',
          'password': 'secret123',
          'http_status': '500',
          'error_category': 'network',
        },
      );
      final result = scrubPiiFromEvent(event);
      expect(result.tags?['email'], equals('[redacted]'));
      expect(result.tags?['password'], equals('[redacted]'));
      expect(result.tags?['http_status'], equals('500'));
      expect(result.tags?['error_category'], equals('network'));
    });
  });

  group('scrubPiiFromBreadcrumb', () {
    test('returns breadcrumb unchanged when data is null', () {
      final crumb = Breadcrumb(message: 'test');
      final result = scrubPiiFromBreadcrumb(crumb);
      expect(result.data, isNull);
    });

    test('returns breadcrumb unchanged when data is empty', () {
      final crumb = Breadcrumb(message: 'test', data: const {});
      final result = scrubPiiFromBreadcrumb(crumb);
      expect(result.data, isEmpty);
    });

    test('redacts PII keys in breadcrumb data', () {
      for (final piiKey in kPiiDenylist) {
        final crumb = Breadcrumb(
          message: 'test',
          data: {piiKey: 'sensitive-value'},
        );
        final result = scrubPiiFromBreadcrumb(crumb);
        expect(
          result.data?[piiKey],
          equals('[redacted]'),
          reason: 'Breadcrumb data "$piiKey" should be redacted',
        );
      }
    });

    test('preserves non-PII keys in breadcrumb data', () {
      final crumb = Breadcrumb(
        message: 'HTTP request',
        data: const {'url': '/api/events', 'method': 'GET', 'status_code': 200},
      );
      final result = scrubPiiFromBreadcrumb(crumb);
      expect(result.data?['url'], equals('/api/events'));
      expect(result.data?['method'], equals('GET'));
      expect(result.data?['status_code'], equals(200));
    });
  });

  group('SentryCrashReporter.setEnabled', () {
    test('setEnabled is a no-op and does not throw', () async {
      final reporter = SentryCrashReporter();
      // No lanza ni en true ni en false — gating controlado por DSN y beforeSend.
      await expectLater(reporter.setEnabled(true), completes);
      await expectLater(reporter.setEnabled(false), completes);
    });
  });
}
