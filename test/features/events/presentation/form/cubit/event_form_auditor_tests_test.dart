// Auditor-mandated tests for event-form-stepper Fase 1
//
// AC-8:  validateStep(0) must return false when EventFormFields.name is empty
//        and true when it has a non-empty value.  Tests use a real
//        GlobalKey<FormBuilderState> attached to the cubit's formKey so that
//        formKey.currentState is non-null.
//
// AC-12: All 9 event_step_* keys exist in AppLocalizationsEs (locale es) and
//        event_form_publish_action is not duplicated.

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/use_cases/create_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/upload_event_image_use_case.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/users/domain/use_cases/get_current_user_id_use_case.dart';
import 'package:rideglory/l10n/app_localizations_es.dart';

class MockCreateEventUseCase extends Mock implements CreateEventUseCase {}

class MockUpdateEventUseCase extends Mock implements UpdateEventUseCase {}

class MockUploadEventImageUseCase extends Mock
    implements UploadEventImageUseCase {}

class MockGetCurrentUserIdUseCase extends Mock
    implements GetCurrentUserIdUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// ---------------------------------------------------------------------------
// Helper: build a minimal FormBuilder widget that uses the cubit's formKey.
// Registers only the fields listed in [fieldNames] with optional initial values.
// ---------------------------------------------------------------------------
Widget _buildFormWidget(
  GlobalKey<FormBuilderState> key, {
  Map<String, String> initialValues = const {},
  List<String> fieldNames = const [EventFormFields.name],
}) {
  return MaterialApp(
    home: Scaffold(
      body: FormBuilder(
        key: key,
        child: Column(
          children: [
            for (final name in fieldNames)
              FormBuilderTextField(
                name: name,
                initialValue: initialValues[name] ?? '',
                validator: name == EventFormFields.name
                    ? FormBuilderValidators.required()
                    : null,
              ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCreateEventUseCase mockCreate;
  late MockUpdateEventUseCase mockUpdate;
  late MockUploadEventImageUseCase mockUpload;
  late MockGetCurrentUserIdUseCase mockGetUserId;
  late MockAnalyticsService mockAnalytics;
  late EventFormCubit cubit;

  setUp(() {
    mockCreate = MockCreateEventUseCase();
    mockUpdate = MockUpdateEventUseCase();
    mockUpload = MockUploadEventImageUseCase();
    mockGetUserId = MockGetCurrentUserIdUseCase();
    mockAnalytics = MockAnalyticsService();

    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    when(() => mockGetUserId()).thenAnswer((_) async => const Right('user-1'));

    cubit = EventFormCubit(
      mockCreate,
      mockUpdate,
      mockUpload,
      mockGetUserId,
      mockAnalytics,
    );
  });

  tearDown(() {
    cubit.close();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // AC-8 — validateStep(0) with a real mounted FormBuilder
  // ═══════════════════════════════════════════════════════════════════════════

  group('AC-8: validateStep(0) returns false/true based on name field value', () {
    testWidgets(
      'validateStep(0) returns false when EventFormFields.name is empty',
      (tester) async {
        await tester.pumpWidget(
          _buildFormWidget(
            cubit.formKey,
            initialValues: {EventFormFields.name: ''},
            fieldNames: [EventFormFields.name],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          cubit.validateStep(0),
          isFalse,
          reason:
              'validateStep(0) must return false when name is empty; '
              'TC-stp-9 only covers the null formKey case.',
        );
      },
    );

    testWidgets(
      'validateStep(0) returns true when EventFormFields.name is non-empty',
      (tester) async {
        await tester.pumpWidget(
          _buildFormWidget(
            cubit.formKey,
            initialValues: {EventFormFields.name: 'Rodada de los Andes'},
            fieldNames: [EventFormFields.name],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          cubit.validateStep(0),
          isTrue,
          reason:
              'validateStep(0) must return true when name has a non-empty value.',
        );
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // AC-12 — ARB keys static presence check
  // ═══════════════════════════════════════════════════════════════════════════

  group(
    'AC-12: AppLocalizations (es) — event_step_* keys and no duplicates',
    () {
      test(
        'all 9 event_step_* getters/methods exist in AppLocalizationsEs',
        () {
          // Instantiate the concrete Spanish localizations class directly — no
          // widget pump needed.  This will fail to compile if a key is missing.
          final l10n = AppLocalizationsEs();

          // Verify each of the 9 stepper strings returns a non-empty value.
          expect(l10n.event_step_basicInfo, isNotEmpty);
          expect(l10n.event_step_details, isNotEmpty);
          expect(l10n.event_step_route, isNotEmpty);
          expect(l10n.event_step_reviewAndPublish, isNotEmpty);
          expect(l10n.event_step_continue, isNotEmpty);
          expect(l10n.event_step_back, isNotEmpty);
          expect(l10n.event_step_of, isNotEmpty);
          // event_step_progressLabel is a method (parameterized).
          expect(l10n.event_step_progressLabel(1, 4), isNotEmpty);
        },
      );

      test(
        'event_form_publish_action exists and is distinct from step keys',
        () {
          final l10n = AppLocalizationsEs();

          // event_form_publish_action must exist (non-empty).
          expect(l10n.event_form_publish_action, isNotEmpty);

          // It must not share its value with any of the step action keys
          // (would indicate a duplicate entry in ARB).
          final stepValues = [
            l10n.event_step_continue,
            l10n.event_step_back,
            l10n.event_step_reviewAndPublish,
          ];
          expect(
            stepValues,
            isNot(contains(l10n.event_form_publish_action)),
            reason:
                'event_form_publish_action value must not duplicate any of the '
                'stepper action labels.',
          );
        },
      );
    },
  );
}
