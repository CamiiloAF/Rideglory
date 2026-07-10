// Widget tests for NotificationsEmptyState (Caso 4.4).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/notifications/presentation/widgets/notifications_empty_state.dart';
import 'package:rideglory/l10n/app_localizations.dart';

Widget _wrap() {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: const Scaffold(body: NotificationsEmptyState()),
  );
}

void main() {
  testWidgets(
    'TC-notif-empty-1: renders empty-state icon, title and subtitle',
    (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
      expect(find.text('Sin notificaciones'), findsOneWidget);
      expect(
        find.text(
          'Aquí aparecerán tus inscripciones aprobadas, recordatorios de '
          'eventos y más.',
        ),
        findsOneWidget,
      );
    },
  );
}
