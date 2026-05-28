// Widget tests — AppModal semantic variants
// Covers: AppModalVariant (info / destructive / warning / success) wiring of
// default icon, icon color and primary action label color (Pencil node ibKDx).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
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
    home: Scaffold(body: child),
  );
}

AppModal _modal(AppModalVariant variant) => AppModal(
  title: 'Título',
  description: 'Descripción del modal',
  variant: variant,
  actions: [AppModalAction(label: 'Confirmar', onPressed: () {})],
);

Icon _icon(WidgetTester tester) => tester.widget<Icon>(find.byType(Icon).first);

Color _primaryLabelColor(WidgetTester tester) =>
    tester.widget<Text>(find.text('Confirmar')).style!.color!;

void main() {
  group('AppModal variants', () {
    testWidgets('info: default info icon, primary accent, dark label', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_modal(AppModalVariant.info)));
      await tester.pumpAndSettle();
      expect(_icon(tester).icon, Icons.info_outline_rounded);
      expect(_icon(tester).color, AppColors.primary);
      expect(_primaryLabelColor(tester), AppColors.darkBgPrimary);
    });

    testWidgets('destructive: delete icon, error accent, white label', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_modal(AppModalVariant.destructive)));
      await tester.pumpAndSettle();
      expect(_icon(tester).icon, Icons.delete_outline);
      expect(_icon(tester).color, AppColors.error);
      expect(_primaryLabelColor(tester), AppColors.textOnDarkPrimary);
    });

    testWidgets('warning: warning icon, warning accent, dark label', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_modal(AppModalVariant.warning)));
      await tester.pumpAndSettle();
      expect(_icon(tester).icon, Icons.warning_amber_rounded);
      expect(_icon(tester).color, AppColors.warning);
      expect(_primaryLabelColor(tester), AppColors.darkBgPrimary);
    });

    testWidgets('success: check icon, green accent, dark label', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_modal(AppModalVariant.success)));
      await tester.pumpAndSettle();
      expect(_icon(tester).icon, Icons.check_circle);
      expect(_icon(tester).color, AppColors.statusGreen);
      expect(_primaryLabelColor(tester), AppColors.darkBgPrimary);
    });

    testWidgets('explicit icon/iconColor override the variant defaults', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppModal(
            title: 'Título',
            icon: Icons.speed_rounded,
            iconColor: AppColors.statusGreen,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_icon(tester).icon, Icons.speed_rounded);
      expect(_icon(tester).color, AppColors.statusGreen);
    });
  });
}
