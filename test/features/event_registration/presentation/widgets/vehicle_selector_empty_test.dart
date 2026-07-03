// Widget tests — VehicleSelectorEmpty
// Covers: AC-7 (Issue #21) — empty state shown only for real empty / error states

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/vehicle_selector_empty.dart';
import 'package:rideglory/l10n/app_localizations.dart';

Widget _wrap({required VoidCallback onCreate}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(body: VehicleSelectorEmpty(onCreate: onCreate)),
  );
}

void main() {
  group('VehicleSelectorEmpty', () {
    testWidgets('TC-vempty-1: shows empty state title text', (tester) async {
      await tester.pumpWidget(_wrap(onCreate: () {}));
      await tester.pumpAndSettle();
      expect(
        find.text('No tienes vehículos disponibles para esta inscripción.'),
        findsOneWidget,
      );
    });

    testWidgets('TC-vempty-2: shows "Crear vehículo" CTA button', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(onCreate: () {}));
      await tester.pumpAndSettle();
      expect(find.text('Crear vehículo'), findsOneWidget);
    });

    testWidgets(
      'TC-vempty-3: onCreate callback fires when CTA button is tapped',
      (tester) async {
        var called = false;
        await tester.pumpWidget(_wrap(onCreate: () => called = true));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Crear vehículo'));
        await tester.pumpAndSettle();
        expect(called, isTrue);
      },
    );
  });
}
