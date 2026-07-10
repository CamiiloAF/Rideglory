// Widget tests for RiderProfileContent, isolated from RiderProfileCubit and
// any backend/network dependency.
//
// Covers gaps listed in docs/testing/qa-checklists/users_QA_CHECKLIST.md
// (Fixes requeridos #1 and #2):
//   - Tapping "Seguir" opens the "Muy pronto" info bottom sheet/dialog.
//   - Edge cases with null/empty `fullName` and `residenceCity`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/features/users/presentation/widgets/rider_profile_content.dart';
import 'package:rideglory/l10n/app_localizations.dart';

Widget _buildTestWidget(UserModel user) {
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
    home: Scaffold(body: RiderProfileContent(user: user)),
  );
}

void main() {
  const mockUser = UserModel(
    id: 'user-123',
    fullName: 'Juan Pérez',
    email: 'juan@example.com',
    residenceCity: 'Bogotá',
  );

  group('RiderProfileContent — botón "Seguir" y bottom sheet informativo', () {
    testWidgets(
      'toca "Seguir" abre el diálogo/bottom sheet con título "Muy pronto"',
      (tester) async {
        await tester.pumpWidget(_buildTestWidget(mockUser));
        await tester.pumpAndSettle();

        expect(find.text('Muy pronto'), findsNothing);

        await tester.tap(find.text('Seguir'));
        await tester.pumpAndSettle();

        expect(find.text('Muy pronto'), findsOneWidget);
        expect(
          find.text(
            'Estamos trabajando en la función de seguir riders. '
            '¡Pronto podrás hacerlo!',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'no dispara ninguna acción de follow/unfollow real (solo abre el diálogo)',
      (tester) async {
        await tester.pumpWidget(_buildTestWidget(mockUser));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Seguir'));
        await tester.pumpAndSettle();

        // El botón "Seguir" (AppButton) sigue mostrando el mismo texto; no
        // cambia a "Siguiendo" ni similar tras la interacción.
        expect(find.widgetWithText(AppButton, 'Seguir'), findsOneWidget);
      },
    );
  });

  group('RiderProfileContent — casos de borde: residenceCity nula/vacía', () {
    testWidgets(
      'residenceCity nula: no renderiza la fila de ciudad ni el ícono de ubicación',
      (tester) async {
        const userWithoutCity = UserModel(
          id: 'user-456',
          fullName: 'Ana Gómez',
          email: 'ana@example.com',
        );

        await tester.pumpWidget(_buildTestWidget(userWithoutCity));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.location_on_outlined), findsNothing);
        expect(find.text('Ana Gómez'), findsOneWidget);
      },
    );

    testWidgets(
      'residenceCity vacía: no renderiza la fila de ciudad ni el ícono de ubicación',
      (tester) async {
        const userWithEmptyCity = UserModel(
          id: 'user-456',
          fullName: 'Ana Gómez',
          email: 'ana@example.com',
          residenceCity: '',
        );

        await tester.pumpWidget(_buildTestWidget(userWithEmptyCity));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.location_on_outlined), findsNothing);
      },
    );
  });

  group('RiderProfileContent — casos de borde: fullName nulo/vacío', () {
    testWidgets(
      'fullName nulo: no lanza excepción y no muestra el texto "null"',
      (tester) async {
        const userWithoutName = UserModel(
          id: 'user-789',
          fullName: null,
          email: 'sinnombre@example.com',
          residenceCity: 'Medellín',
        );

        await tester.pumpWidget(_buildTestWidget(userWithoutName));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('null'), findsNothing);
        // La fila de ciudad y el resto de la pantalla se ven con normalidad.
        expect(find.text('Medellín'), findsOneWidget);
      },
    );

    testWidgets(
      'fullName vacío: no lanza excepción y no muestra el texto "null"',
      (tester) async {
        const userWithEmptyName = UserModel(
          id: 'user-789',
          fullName: '',
          email: 'sinnombre@example.com',
        );

        await tester.pumpWidget(_buildTestWidget(userWithEmptyName));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('null'), findsNothing);
      },
    );
  });
}
