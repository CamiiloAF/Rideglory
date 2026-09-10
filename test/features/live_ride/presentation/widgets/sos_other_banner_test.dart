import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/theme/app_theme.dart';
import 'package:rideglory/features/live_ride/presentation/widgets/sos_other_banner.dart';
import 'package:rideglory/l10n/app_localizations.dart';

void main() {
  testWidgets('shows the rider name, distance and a view CTA', (tester) async {
    var viewed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SosOtherBanner(
            riderName: 'Carlos Ramírez',
            distanceMeters: 1200,
            onView: () => viewed = true,
          ),
        ),
      ),
    );

    expect(find.textContaining('Carlos Ramírez'), findsOneWidget);
    expect(find.textContaining('1,2 km'), findsOneWidget);

    await tester.tap(find.text('Ver'));
    expect(viewed, isTrue);
  });
}
