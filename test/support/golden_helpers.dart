import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/theme/app_theme.dart';
import 'package:rideglory/l10n/app_localizations.dart';

/// Helper compartido de goldens (primera aparición en el repo, F11
/// live_ride). Fuerza el tamaño de frame del `.pen` (390x844, densidad 1)
/// y envuelve en `MaterialApp` con tema y localización — sin esto, dos
/// máquinas con densidades de pantalla distintas producen goldens
/// distintos por razones ajenas al widget.
///
/// La trampa de Outfit/`google_fonts` bajo `flutter_test` (ver CLAUDE.md)
/// ya la resuelve `AppTypography` detectando `FLUTTER_TEST`, así que este
/// helper no necesita nada especial para la fuente: el `ThemeData` de
/// `AppTheme` ya la aplica sin red.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget widget, {
  Size size = const Size(390, 844),
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget,
    ),
  );
  await tester.pump();
}
