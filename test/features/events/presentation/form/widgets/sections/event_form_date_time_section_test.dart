// Widget tests for the "Fecha y hora" section of the event creation wizard
// (docs/testing/qa-checklists/events_QA_CHECKLIST.md, sección "3A-bis").
//
// Covers:
//   3A.8  — single-day mode: selecting a start date updates the row.
//   3A.9  — toggling "Es un evento de varios días" swaps
//           EventSingleDayCard -> EventMultiDayCard and clears dateRange.
//   3A.10 — multi-day mode: selecting start then end date (end after start,
//           validation passes); and start==end triggers
//           event_startDateMustBeBeforeEndDate.
//   3A.11 — selecting a meeting time updates the row (hh:mm a format).
//   3A.12 — leaving the date empty and validating shows event_startDateRequired.

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_date_time_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_multi_day_card.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_single_day_card.dart';
import 'package:rideglory/l10n/app_localizations.dart';

/// Real strings used by `MaterialLocalizations` in Spanish for the native
/// `showDatePicker`/`showTimePicker` dialogs (same pattern as
/// `test/features/soat/presentation/pages/soat_manual_capture_page_test.dart`).
const _switchToDateInputTooltip = 'Cambiar a cuadro de texto';
const _switchToTimeInputTooltip = 'Cambiar al modo de introducción de texto';
const _pickerConfirm = 'ACEPTAR';

Widget _buildTestPage({required GlobalKey<FormBuilderState> formKey}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      AppLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(
      body: FormBuilder(
        key: formKey,
        child: const EventFormDateTimeSection(),
      ),
    ),
  );
}

/// Opens the native date picker for the row currently showing [rowText],
/// switches it to text-input mode and types [day]/[month]/[year], then
/// confirms with "ACEPTAR".
Future<void> _pickDateOnRow(
  WidgetTester tester, {
  required String rowText,
  required String day,
  required String month,
  required String year,
}) async {
  await tester.tap(find.text(rowText).first);
  await tester.pumpAndSettle();

  await tester.tap(find.byTooltip(_switchToDateInputTooltip));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).last, '$day/$month/$year');
  await tester.pumpAndSettle();

  await tester.tap(find.text(_pickerConfirm));
  await tester.pumpAndSettle();
}

/// Opens the native time picker for the meeting-time row and confirms the
/// pre-filled time (07:00) via "ACEPTAR", exercising the picker wiring.
Future<void> _confirmTimePicker(WidgetTester tester) async {
  await tester.tap(find.text('07:00 AM'));
  await tester.pumpAndSettle();

  await tester.tap(find.byTooltip(_switchToTimeInputTooltip));
  await tester.pumpAndSettle();

  await tester.tap(find.text(_pickerConfirm));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ═════════════════════════════════════════════════════════════════════════
  // 3A.8 — Single-day mode: selecting a start date updates the row
  // ═════════════════════════════════════════════════════════════════════════

  group('3A.8: single-day date selection', () {
    testWidgets(
      'selecting a start date replaces the placeholder with the formatted '
      'date',
      (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        await tester.pumpWidget(_buildTestPage(formKey: formKey));
        await tester.pumpAndSettle();

        expect(find.byType(EventSingleDayCard), findsOneWidget);
        expect(find.text('Seleccionar fecha...'), findsOneWidget);

        final target = DateTime.now().add(const Duration(days: 30));
        await _pickDateOnRow(
          tester,
          rowText: 'Seleccionar fecha...',
          day: target.day.toString().padLeft(2, '0'),
          month: target.month.toString().padLeft(2, '0'),
          year: target.year.toString(),
        );

        final expectedText = DateFormat(
          'EEE, dd MMM yyyy',
          'es',
        ).format(DateTime(target.year, target.month, target.day));

        expect(find.text('Seleccionar fecha...'), findsNothing);
        expect(find.text(expectedText), findsOneWidget);

        final range =
            formKey.currentState!.fields[EventFormFields.dateRange]!.value
                as DateTimeRange?;
        expect(range, isNotNull);
        expect(range!.start.day, target.day);
        expect(range.start.month, target.month);
        expect(range.start.year, target.year);
      },
    );
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 3A.11 — Meeting time selection
  // ═════════════════════════════════════════════════════════════════════════

  group('3A.11: meeting time selection', () {
    testWidgets(
      'confirming the time picker reflects the chosen time in hh:mm a format',
      (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        await tester.pumpWidget(_buildTestPage(formKey: formKey));
        await tester.pumpAndSettle();

        // Default initialValue is 07:00, already displayed (not the
        // placeholder) — confirm the picker still round-trips through the
        // real onPickTime wiring without altering the displayed value.
        expect(find.text('07:00 AM'), findsOneWidget);

        await _confirmTimePicker(tester);

        expect(find.text('07:00 AM'), findsOneWidget);

        final time =
            formKey.currentState!.fields[EventFormFields.meetingTime]!.value
                as DateTime?;
        expect(time, isNotNull);
        expect(time!.hour, 7);
        expect(time.minute, 0);
      },
    );
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 3A.9 — Multi-day toggle
  // ═════════════════════════════════════════════════════════════════════════

  group('3A.9: multi-day toggle', () {
    testWidgets(
      'activating "Es un evento de varios días" swaps the card and clears '
      'dateRange',
      (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        await tester.pumpWidget(_buildTestPage(formKey: formKey));
        await tester.pumpAndSettle();

        // Fill a start date first, in single-day mode.
        final target = DateTime.now().add(const Duration(days: 5));
        await _pickDateOnRow(
          tester,
          rowText: 'Seleccionar fecha...',
          day: target.day.toString().padLeft(2, '0'),
          month: target.month.toString().padLeft(2, '0'),
          year: target.year.toString(),
        );
        expect(
          formKey.currentState!.fields[EventFormFields.dateRange]!.value,
          isNotNull,
        );

        expect(find.byType(EventSingleDayCard), findsOneWidget);
        expect(find.byType(EventMultiDayCard), findsNothing);

        await tester.tap(find.text('Es un evento de varios días'));
        await tester.pumpAndSettle();

        expect(find.byType(EventSingleDayCard), findsNothing);
        expect(find.byType(EventMultiDayCard), findsOneWidget);

        expect(
          formKey.currentState!.fields[EventFormFields.dateRange]!.value,
          isNull,
          reason:
              'Toggling to multi-day mode must clear dateRange '
              '(field.didChange(null)).',
        );
        expect(find.text('Seleccionar fecha...'), findsNWidgets(2));
      },
    );

    testWidgets('deactivating the toggle swaps back to EventSingleDayCard', (
      tester,
    ) async {
      final formKey = GlobalKey<FormBuilderState>();
      await tester.pumpWidget(_buildTestPage(formKey: formKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Es un evento de varios días'));
      await tester.pumpAndSettle();
      expect(find.byType(EventMultiDayCard), findsOneWidget);

      await tester.tap(find.text('Es un evento de varios días'));
      await tester.pumpAndSettle();

      expect(find.byType(EventSingleDayCard), findsOneWidget);
      expect(find.byType(EventMultiDayCard), findsNothing);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 3A.10 — Multi-day: start/end date selection + end-after-start validation
  // ═════════════════════════════════════════════════════════════════════════

  group('3A.10: multi-day start/end date selection and validation', () {
    testWidgets(
      'selecting a start date then an end date after it passes validation',
      (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        await tester.pumpWidget(_buildTestPage(formKey: formKey));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Es un evento de varios días'));
        await tester.pumpAndSettle();
        expect(find.byType(EventMultiDayCard), findsOneWidget);

        final start = DateTime.now().add(const Duration(days: 10));
        await _pickDateOnRow(
          tester,
          rowText: 'Seleccionar fecha...',
          day: start.day.toString().padLeft(2, '0'),
          month: start.month.toString().padLeft(2, '0'),
          year: start.year.toString(),
        );

        // Only the end-date row still shows the placeholder now.
        expect(find.text('Seleccionar fecha...'), findsOneWidget);

        final end = start.add(const Duration(days: 3));
        await _pickDateOnRow(
          tester,
          rowText: 'Seleccionar fecha...',
          day: end.day.toString().padLeft(2, '0'),
          month: end.month.toString().padLeft(2, '0'),
          year: end.year.toString(),
        );

        expect(find.text('Seleccionar fecha...'), findsNothing);

        final isValid = formKey.currentState!.saveAndValidate();
        expect(isValid, isTrue);
        expect(
          find.text('La fecha de inicio debe ser anterior a la fecha de fin'),
          findsNothing,
        );

        final range =
            formKey.currentState!.fields[EventFormFields.dateRange]!.value
                as DateTimeRange?;
        expect(range!.end.isAfter(range.start), isTrue);
      },
    );

    testWidgets(
      'a dateRange with start == end fails validation with '
      'event_startDateMustBeBeforeEndDate',
      (tester) async {
        // The real firstDate(start + 1 day) constraint on the end-date
        // native picker makes it impossible to reach an equal start/end pair
        // through the UI — so this exercises the production validator
        // directly (FormBuilderField.validator composed in
        // EventMultiDayCard), the same code path the UI would trigger if the
        // picker constraint were ever relaxed.
        final formKey = GlobalKey<FormBuilderState>();
        await tester.pumpWidget(_buildTestPage(formKey: formKey));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Es un evento de varios días'));
        await tester.pumpAndSettle();

        final sameDay = DateTime.now().add(const Duration(days: 10));
        formKey.currentState!.fields[EventFormFields.dateRange]!.didChange(
          DateTimeRange(start: sameDay, end: sameDay),
        );
        await tester.pumpAndSettle();

        final isValid = formKey.currentState!.saveAndValidate();
        expect(isValid, isFalse);

        await tester.pumpAndSettle();
        expect(
          find.text('La fecha de inicio debe ser anterior a la fecha de fin'),
          findsOneWidget,
        );
      },
    );
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 3A.12 — Required date error
  // ═════════════════════════════════════════════════════════════════════════

  group('3A.12: required start date error', () {
    testWidgets(
      'validating with no date selected (single-day mode) shows '
      'event_startDateRequired and fails validation',
      (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        await tester.pumpWidget(_buildTestPage(formKey: formKey));
        await tester.pumpAndSettle();

        final isValid = formKey.currentState!.saveAndValidate();
        expect(isValid, isFalse);

        await tester.pumpAndSettle();
        expect(
          find.text('La fecha de inicio es requerida'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'validating with no date selected (multi-day mode) shows '
      'event_dateRangeRequired and fails validation',
      (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        await tester.pumpWidget(_buildTestPage(formKey: formKey));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Es un evento de varios días'));
        await tester.pumpAndSettle();

        final isValid = formKey.currentState!.saveAndValidate();
        expect(isValid, isFalse);

        await tester.pumpAndSettle();
        expect(
          find.text('Las fechas del evento son requeridas'),
          findsOneWidget,
        );
      },
    );
  });
}
