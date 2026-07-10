import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/tecnomecanica/presentation/widgets/tecnomecanica_empty_state.dart';
import 'package:rideglory/features/tecnomecanica/presentation/widgets/tecnomecanica_exemption_notice.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/l10n/app_localizations.dart';

/// Test de regresión: `TecnomecanicaEmptyState` importaba
/// `TecnomecanicaExemptionNotice` pero nunca lo instanciaba en su `build()`
/// (ver "Bugs encontrados" en `docs/testing/qa-checklists/tecnomecanica_QA_CHECKLIST.md`,
/// casos 5.2 y 10.8). Si alguien vuelve a quitar el widget del árbol, este
/// test debe fallar.
void main() {
  const vehicle = VehicleModel(name: 'Mi Moto', currentMileage: 1000);

  Widget buildTestWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: const Scaffold(body: TecnomecanicaEmptyState(vehicle: vehicle)),
    );
  }

  testWidgets(
    'TecnomecanicaExemptionNotice se renderiza dentro de '
    'TecnomecanicaEmptyState (regresión del bug confirmado)',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TecnomecanicaEmptyState), findsOneWidget);
      expect(find.byType(TecnomecanicaExemptionNotice), findsOneWidget);
    },
  );
}
