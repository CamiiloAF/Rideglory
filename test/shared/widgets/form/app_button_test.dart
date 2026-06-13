// CA7: Widget tests for AppButton optional analytics tap params.
//
// Verifies:
//   CA7a: analyticsTapEvent fires on tap when non-null.
//   CA7b: null analyticsTapEvent is a no-op (no getIt call, no error).
//   CA7c: isLoading=true suppresses both onPressed and analytics.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class _MockAnalyticsService extends Mock implements AnalyticsService {}

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );

void main() {
  late _MockAnalyticsService mockAnalytics;

  setUp(() {
    mockAnalytics = _MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    // Register mock into the global GetIt instance used by AppButton.
    if (!getIt.isRegistered<AnalyticsService>()) {
      getIt.registerSingleton<AnalyticsService>(mockAnalytics);
    } else {
      getIt.unregister<AnalyticsService>();
      getIt.registerSingleton<AnalyticsService>(mockAnalytics);
    }
  });

  tearDown(() async {
    if (getIt.isRegistered<AnalyticsService>()) {
      await getIt.unregister<AnalyticsService>();
    }
  });

  // CA7a: analyticsTapEvent fires on tap
  testWidgets(
    'CA7a: tapping AppButton with analyticsTapEvent fires the event',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'Tap me',
            onPressed: () => tapped = true,
            analyticsTapEvent: 'test_event',
            analyticsTapParams: const {'key': 'value'},
          ),
        ),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapped, isTrue);
      verify(
        () => mockAnalytics.logEvent('test_event', {'key': 'value'}),
      ).called(1);
    },
  );

  // CA7b: null analyticsTapEvent — no analytics call, onPressed still fires
  testWidgets(
    'CA7b: tapping AppButton with null analyticsTapEvent is a no-op for analytics',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'Tap me',
            onPressed: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapped, isTrue);
      verifyNever(() => mockAnalytics.logEvent(any(), any()));
      verifyNever(() => mockAnalytics.logEvent(any()));
    },
  );

  // CA7c: isLoading=true suppresses onPressed and analytics
  testWidgets(
    'CA7c: tapping AppButton with isLoading=true does not fire analytics',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'Loading',
            onPressed: () => tapped = true,
            isLoading: true,
            analyticsTapEvent: 'test_event',
          ),
        ),
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isFalse);
      verifyNever(() => mockAnalytics.logEvent(any(), any()));
    },
  );
}
