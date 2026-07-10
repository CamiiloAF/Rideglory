import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/soat/domain/models/soat_scan_result.dart';
import 'package:rideglory/features/soat/domain/usecases/scan_soat_usecase.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_capture_page.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_not_recognized_warning.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class MockScanSoatUseCase extends Mock implements ScanSoatUseCase {}

class FakeFile extends Fake implements File {}

/// Textos reales usados por Material/`MaterialLocalizations` en español para
/// el `showDatePicker` embebido en `AppDatePicker` (mismo patrón que
/// `integration_test/soat_manual_capture_patrol_test.dart`).
const _switchToInputTooltip = 'Cambiar a cuadro de texto';
const _datePickerConfirm = 'ACEPTAR';

Widget _buildTestPage({String? initialLocalImagePath}) {
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
    home: SoatManualCapturePage(initialLocalImagePath: initialLocalImagePath),
  );
}

/// Abre el date picker de Material del campo en [fieldIndex], cambia a modo
/// de entrada de texto y escribe la fecha en formato `dd/mm/aaaa`, luego
/// confirma con "ACEPTAR". Réplica del helper usado en el test Patrol
/// equivalente (`soat_manual_capture_patrol_test.dart`).
Future<void> _pickDate(
  WidgetTester tester, {
  required int fieldIndex,
  required String day,
  required String month,
  required String year,
}) async {
  await tester.tap(find.byType(TextField).at(fieldIndex));
  await tester.pumpAndSettle();

  await tester.tap(find.byTooltip(_switchToInputTooltip));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).last, '$day/$month/$year');
  await tester.pumpAndSettle();

  await tester.tap(find.text(_datePickerConfirm));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFile());
    registerFallbackValue(SoatScanSource.gallery);
  });

  group('SoatManualCapturePage — TC-7.3 corrección de fecha inválida', () {
    testWidgets(
      'el error inline desaparece y el botón se habilita al corregir la '
      'fecha de vencimiento',
      (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestPage());
        await tester.pumpAndSettle();

        // Aseguradora requerida.
        await tester.enterText(
          find.byType(TextField).at(1),
          'Seguros Bolívar',
        );
        await tester.pumpAndSettle();

        // Fecha de inicio: 01/01/2024.
        await _pickDate(
          tester,
          fieldIndex: 2,
          day: '01',
          month: '01',
          year: '2024',
        );

        // Fecha de vencimiento ANTERIOR a la de inicio: dispara el error
        // inline de fechas inválidas (`ValidityCardInvalidDates`) y deshabilita
        // el botón de guardar.
        await _pickDate(
          tester,
          fieldIndex: 3,
          day: '01',
          month: '01',
          year: '2023',
        );

        expect(find.text('Fechas inválidas'), findsOneWidget);

        final saveButtonFinder = find.byType(AppButton);
        expect(saveButtonFinder, findsOneWidget);
        expect(tester.widget<AppButton>(saveButtonFinder).onPressed, isNull);

        // Corrige la fecha de vencimiento para que sea posterior a la de
        // inicio.
        await _pickDate(
          tester,
          fieldIndex: 3,
          day: '01',
          month: '01',
          year: '2030',
        );

        expect(find.text('Fechas inválidas'), findsNothing);
        expect(
          tester.widget<AppButton>(saveButtonFinder).onPressed,
          isNotNull,
        );
      },
    );
  });

  group('SoatManualCapturePage — TC-9A.1 documento no reconocido', () {
    late MockScanSoatUseCase mockScanSoatUseCase;

    setUp(() {
      mockScanSoatUseCase = MockScanSoatUseCase();
      GetIt.I.allowReassignment = true;
      getIt.registerFactory<ScanSoatUseCase>(() => mockScanSoatUseCase);
    });

    tearDown(() {
      if (getIt.isRegistered<ScanSoatUseCase>()) {
        getIt.unregister<ScanSoatUseCase>();
      }
      GetIt.I.allowReassignment = false;
    });

    testWidgets(
      'muestra SoatNotRecognizedWarning cuando el escaneo lanza '
      'SoatScanException',
      (WidgetTester tester) async {
        when(
          () => mockScanSoatUseCase.call(
            file: any(named: 'file'),
            source: any(named: 'source'),
          ),
        ).thenThrow(
          const SoatScanException(SoatScanFailureReason.noTextDetected),
        );

        await tester.pumpWidget(
          _buildTestPage(initialLocalImagePath: 'fake_document.jpg'),
        );
        // El escaneo se dispara en un post-frame callback en `initState`.
        await tester.pumpAndSettle();

        expect(find.byType(SoatNotRecognizedWarning), findsOneWidget);
      },
    );
  });
}
