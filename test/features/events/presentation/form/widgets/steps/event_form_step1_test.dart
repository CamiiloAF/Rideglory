// Widget smoke tests for EventFormStep1 — Fase 3
//
// AC #7: TC-wdg-01 (renders without overflow/exceptions with empty name),
//        TC-wdg-02 ('Continuar' disabled when validateStep returns false),
//        TC-wdg-03 ('Continuar' enabled after validateStep returns true).
// TC-step-07 (AC-6g): buildEventToSave() produces meetingPoint == ''
//        when state.meetingPointName is null (mounted FormBuilder, real cubit).

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/ai_description_result.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/create_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/upload_event_image_use_case.dart';
import 'package:rideglory/features/events/presentation/form/cubit/ai_description_chat_cubit.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_form_step1.dart';
import 'package:rideglory/features/users/domain/use_cases/get_current_user_id_use_case.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';
import 'package:rideglory/core/services/place_service.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockEventFormCubit extends MockCubit<EventFormState>
    implements EventFormCubit {}

class MockFormImageCubit extends MockCubit<ResultState<FormImageData>>
    implements FormImageCubit {}

class MockAiDescriptionChatCubit
    extends MockCubit<AiDescriptionChatState>
    implements AiDescriptionChatCubit {}

class MockPlaceService extends Mock implements PlaceService {}

class MockCreateEventUseCase extends Mock implements CreateEventUseCase {}

class MockUpdateEventUseCase extends Mock implements UpdateEventUseCase {}

class MockUploadEventImageUseCase extends Mock
    implements UploadEventImageUseCase {}

class MockGetCurrentUserIdUseCase extends Mock
    implements GetCurrentUserIdUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _buildStep1({
  required MockEventFormCubit eventFormCubit,
  required MockFormImageCubit formImageCubit,
  required MockAiDescriptionChatCubit aiCubit,
}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<EventFormCubit>.value(value: eventFormCubit),
          BlocProvider<FormImageCubit>.value(value: formImageCubit),
          BlocProvider<AiDescriptionChatCubit>.value(value: aiCubit),
        ],
        child: const EventFormStep1(),
      ),
    ),
  );
}

void _stubEventFormCubit(
  MockEventFormCubit cubit, {
  bool validateResult = false,
}) {
  when(() => cubit.state).thenReturn(const EventFormState(currentStep: 0));
  when(() => cubit.validateStep(any())).thenReturn(validateResult);
  when(() => cubit.isEditing).thenReturn(false);
  when(() => cubit.editingEvent).thenReturn(null);
  when(() => cubit.formKey).thenReturn(GlobalKey());
}

void _stubFormImageCubit(MockFormImageCubit cubit) {
  when(() => cubit.state)
      .thenReturn(const ResultState<FormImageData>.initial());
}

void _stubAiCubit(MockAiDescriptionChatCubit cubit) {
  when(() => cubit.state).thenReturn(
    const AiDescriptionChatState(
      sendResult: ResultState<AiDescriptionResult>.initial(),
      remainingQuota: 10,
      isQuotaInitialized: true,
    ),
  );
  when(() => cubit.initQuota()).thenAnswer((_) async {});
  when(() => cubit.isQuotaExhausted).thenReturn(false);
  when(() => cubit.lastMarkdown).thenReturn(null);
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final gI = GetIt.instance;
  late MockPlaceService mockPlace;
  late MockAiDescriptionChatCubit mockAiCubit;

  setUp(() {
    mockPlace = MockPlaceService();
    when(() => mockPlace.autocomplete(any(), any()))
        .thenAnswer((_) async => []);

    if (!gI.isRegistered<PlaceService>()) {
      gI.registerSingleton<PlaceService>(mockPlace);
    }

    mockAiCubit = MockAiDescriptionChatCubit();
    _stubAiCubit(mockAiCubit);

    if (gI.isRegistered<AiDescriptionChatCubit>()) {
      gI.unregister<AiDescriptionChatCubit>();
    }
    gI.registerFactory<AiDescriptionChatCubit>(() => mockAiCubit);
  });

  tearDown(() {
    if (gI.isRegistered<AiDescriptionChatCubit>()) {
      gI.unregister<AiDescriptionChatCubit>();
    }
    if (gI.isRegistered<PlaceService>()) {
      gI.unregister<PlaceService>();
    }
  });

  group('EventFormStep1 smoke tests (AC #7)', () {
    // TC-wdg-01 ──────────────────────────────────────────────────────────────
    testWidgets(
        'TC-wdg-01: EventFormStep1 renders without overflow/exceptions with empty name',
        (tester) async {
      final eventFormCubit = MockEventFormCubit();
      final formImageCubit = MockFormImageCubit();
      _stubEventFormCubit(eventFormCubit, validateResult: false);
      _stubFormImageCubit(formImageCubit);

      await tester.pumpWidget(
        _buildStep1(
          eventFormCubit: eventFormCubit,
          formImageCubit: formImageCubit,
          aiCubit: mockAiCubit,
        ),
      );
      await tester.pump();

      expect(find.byType(EventFormStep1), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // TC-wdg-02 ──────────────────────────────────────────────────────────────
    testWidgets(
        'TC-wdg-02: Continuar button is disabled when validateStep returns false (empty name)',
        (tester) async {
      final eventFormCubit = MockEventFormCubit();
      final formImageCubit = MockFormImageCubit();
      _stubEventFormCubit(eventFormCubit, validateResult: false);
      _stubFormImageCubit(formImageCubit);

      await tester.pumpWidget(
        _buildStep1(
          eventFormCubit: eventFormCubit,
          formImageCubit: formImageCubit,
          aiCubit: mockAiCubit,
        ),
      );
      await tester.pump();

      await tester.tap(find.textContaining('Continuar'));
      await tester.pump();

      verifyNever(() => eventFormCubit.nextStep());
    });

    // TC-wdg-03 ──────────────────────────────────────────────────────────────
    testWidgets(
        'TC-wdg-03: Continuar button is enabled when validateStep returns true (name filled)',
        (tester) async {
      final eventFormCubit = MockEventFormCubit();
      final formImageCubit = MockFormImageCubit();
      _stubEventFormCubit(eventFormCubit, validateResult: true);
      _stubFormImageCubit(formImageCubit);
      when(() => eventFormCubit.nextStep()).thenReturn(null);

      await tester.pumpWidget(
        _buildStep1(
          eventFormCubit: eventFormCubit,
          formImageCubit: formImageCubit,
          aiCubit: mockAiCubit,
        ),
      );
      await tester.pump();

      await tester.tap(find.textContaining('Continuar'));
      await tester.pump();

      verify(() => eventFormCubit.nextStep()).called(1);
    });
  });

  // ─── TC-step-07 (AC-6g) ──────────────────────────────────────────────────
  // buildEventToSave() must produce meetingPoint == '' when no waypoints exist.
  // meetingPoint is now a computed getter derived from routePoints.
  group('TC-step-07 (AC-6g): buildEventToSave meetingPoint when no waypoints',
      () {
    testWidgets(
        'buildEventToSave() returns EventModel with meetingPoint == "" '
        'when state has no waypoints',
        (tester) async {
      final mockCreate = MockCreateEventUseCase();
      final mockUpdate = MockUpdateEventUseCase();
      final mockUpload = MockUploadEventImageUseCase();
      final mockGetUserId = MockGetCurrentUserIdUseCase();
      final mockAnalytics = MockAnalyticsService();

      when(() => mockAnalytics.logEvent(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
      when(() => mockGetUserId())
          .thenAnswer((_) async => const Right('user-test-123'));

      final realCubit = EventFormCubit(
        mockCreate,
        mockUpdate,
        mockUpload,
        mockGetUserId,
        mockAnalytics,
      );

      final now = DateTime.now();
      final initialValues = <String, dynamic>{
        EventFormFields.name: 'Rodada QA',
        EventFormFields.description: 'Descripción de prueba',
        EventFormFields.dateRange: DateTimeRange(start: now, end: now),
        EventFormFields.meetingTime: DateTime(now.year, now.month, now.day, 7),
        EventFormFields.difficulty: EventDifficulty.one,
        EventFormFields.eventType: EventType.onRoad,
        EventFormFields.allowedBrands: <String>[],
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: BlocProvider<EventFormCubit>.value(
              value: realCubit,
              child: FormBuilder(
                key: realCubit.formKey,
                initialValue: initialValues,
                child: Column(
                  children: [
                    for (final entry in initialValues.entries)
                      FormBuilderField<dynamic>(
                        name: entry.key,
                        initialValue: entry.value,
                        builder: (_) => const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final result = await realCubit.buildEventToSave();

      expect(result, isNotNull,
          reason: 'buildEventToSave must return a non-null EventModel '
              'when the form is valid');
      // meetingPoint is derived from routePoints (empty when no waypoints)
      expect(result!.meetingPoint, equals(''));

      realCubit.close();
    });
  });
}
