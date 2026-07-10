// Widget tests for NotificationsErrorState (Caso 4.5), including the retry
// button invoking the callback passed by NotificationsView (which in turn
// calls NotificationsCubit.load()).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/notifications/presentation/widgets/notifications_error_state.dart';
import 'package:rideglory/l10n/app_localizations.dart';

Widget _wrap({required VoidCallback onRetry}) {
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
    home: Scaffold(
      body: NotificationsErrorState(
        message: 'Sin conexión',
        onRetry: onRetry,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'TC-notif-error-1: renders error icon, title, subtitle and retry button',
    (tester) async {
      await tester.pumpWidget(_wrap(onRetry: () {}));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        find.text('No se pudieron cargar las notificaciones'),
        findsOneWidget,
      );
      expect(
        find.text('Verifica tu conexión a internet e intenta de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-notif-error-2: tapping retry button invokes onRetry callback (load())',
    (tester) async {
      var retryCount = 0;
      await tester.pumpWidget(_wrap(onRetry: () => retryCount++));
      await tester.pump();

      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      expect(retryCount, 1);
    },
  );
}
