import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/theme/app_theme.dart';
import 'package:rideglory/features/live_ride/presentation/widgets/sos_hold_button.dart';
import 'package:rideglory/l10n/app_localizations.dart';

Widget _wrap(VoidCallback onConfirmed) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(child: SosHoldButton(onConfirmed: onConfirmed)),
    ),
  );
}

void main() {
  testWidgets('does not fire before the hold duration completes', (
    tester,
  ) async {
    var confirmed = false;
    await tester.pumpWidget(_wrap(() => confirmed = true));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SosHoldButton)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 800));

    expect(confirmed, isFalse);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('fires once the hold duration completes', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(_wrap(() => confirmed = true));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SosHoldButton)),
    );
    await tester.pump();
    // kLongPressTimeout (500ms) para que arranque onLongPressStart.
    await tester.pump(const Duration(milliseconds: 600));
    // holdDuration (1500ms) del anillo de progreso.
    await tester.pump(const Duration(milliseconds: 1600));

    expect(confirmed, isTrue);

    await gesture.up();
  });
}
