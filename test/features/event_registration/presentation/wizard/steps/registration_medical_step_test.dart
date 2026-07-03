// Widget tests — RegistrationMedicalStep
// Covers: waiver phase — privacy section adds exactly 2 AppSwitchTile, both
// with a non-null (WCAG-required) subtitle.

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/steps/registration_medical_step.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/widgets/form/app_switch.dart';
import 'package:rideglory/shared/widgets/form/app_switch_tile.dart';
import 'package:rideglory/shared/widgets/form/form_focus_chain.dart';

Widget _wrap() {
  final focusChain = FormFocusChain(const ['eps', 'medicalInsurance']);
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
    home: Scaffold(
      body: FormBuilder(
        child: SingleChildScrollView(
          child: RegistrationMedicalStep(focusChain: focusChain),
        ),
      ),
    ),
  );
}

void main() {
  group('RegistrationMedicalStep — privacy switches (waiver phase)', () {
    testWidgets(
      'renders exactly 2 AppSwitchTile widgets for the privacy section',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();

        expect(find.byType(AppSwitchTile), findsNWidgets(2));
      },
    );

    testWidgets(
      'both AppSwitchTile widgets have a non-null subtitle (WCAG requirement)',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();

        final tiles = tester
            .widgetList<AppSwitchTile>(find.byType(AppSwitchTile))
            .toList();

        expect(tiles, hasLength(2));
        for (final tile in tiles) {
          expect(tile.subtitle, isNotNull);
          expect(tile.subtitle, isNotEmpty);
        }
      },
    );

    testWidgets('renders the privacy section title "Privacidad"', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('PRIVACIDAD'), findsOneWidget);
    });

    testWidgets(
      'both AppSwitchTile widgets default to false in create mode (AC#3)',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();

        final tiles = tester
            .widgetList<AppSwitchTile>(find.byType(AppSwitchTile))
            .toList();

        expect(tiles, hasLength(2));
        for (final tile in tiles) {
          expect(tile.initialValue, isFalse);
        }
      },
    );

    testWidgets('shareMedicalInfo switch is bound to the exact field name', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final tiles = tester
          .widgetList<AppSwitchTile>(find.byType(AppSwitchTile))
          .toList();
      expect(
        tiles.map((tile) => tile.name),
        containsAll(['shareMedicalInfo', 'allowOrganizerContact']),
      );
    });

    testWidgets(
      'tapping both AppSwitchTile rows turns each underlying AppSwitch on '
      '(QA case 2.4)',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();

        final switchesBefore = tester
            .widgetList<AppSwitch>(find.byType(AppSwitch))
            .toList();
        expect(switchesBefore, hasLength(2));
        expect(switchesBefore.every((s) => s.value == false), isTrue);

        for (final tileFinder in find.byType(AppSwitchTile).evaluate()) {
          await tester.tap(find.byWidget(tileFinder.widget));
        }
        await tester.pumpAndSettle();

        final switchesAfter = tester
            .widgetList<AppSwitch>(find.byType(AppSwitch))
            .toList();
        expect(switchesAfter, hasLength(2));
        expect(
          switchesAfter.every((s) => s.value == true),
          isTrue,
          reason:
              'Tapping each AppSwitchTile row must flip its bound AppSwitch '
              'to the "on" visual state (value == true).',
        );
      },
    );
  });
}
