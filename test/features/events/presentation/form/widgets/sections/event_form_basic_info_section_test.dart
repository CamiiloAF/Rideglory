// Widget tests for EventFormBasicInfoSection (converted StatefulWidget)
// AC17: section renders without errors when isEditing=false and isEditing=true
// AC18: _buildEventContext maps form fields correctly:
//   title == EventFormFields.name value,
//   eventType == EventType enum .apiValue,
//   difficulty == null (not set in the form)

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/place_service.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/ai_description_result.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/ai_description_chat_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_description_chat_page.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart';
import 'package:rideglory/l10n/app_localizations.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockPlaceService extends Mock implements PlaceService {}

class MockAiDescriptionChatCubit
    extends MockCubit<AiDescriptionChatState>
    implements AiDescriptionChatCubit {}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _buildHost({
  EventType eventType = EventType.onRoad,
  bool isEditing = false,
  GlobalKey<FormBuilderState>? formKey,
  MockAiDescriptionChatCubit? cubit,
}) {
  Widget child = MaterialApp(
    theme: AppTheme.darkTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(
      body: SingleChildScrollView(
        child: FormBuilder(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hidden field registers eventType in the FormBuilder scope so
              // that _buildEventContext() can read it.
              FormBuilderField<EventType>(
                name: EventFormFields.eventType,
                initialValue: eventType,
                builder: (_) => const SizedBox.shrink(),
              ),
              EventFormBasicInfoSection(isEditing: isEditing),
            ],
          ),
        ),
      ),
    ),
  );

  if (cubit != null) {
    child = BlocProvider<AiDescriptionChatCubit>.value(
      value: cubit,
      child: child,
    );
  }

  return child;
}

void _setupMockCubit(MockAiDescriptionChatCubit mockCubit) {
  when(() => mockCubit.initQuota()).thenAnswer((_) async {});
  when(() => mockCubit.isQuotaExhausted).thenReturn(false);
  when(() => mockCubit.lastMarkdown).thenReturn(null);
  when(() => mockCubit.sendMessage(
        userMessage: any(named: 'userMessage'),
        title: any(named: 'title'),
        eventType: any(named: 'eventType'),
        difficulty: any(named: 'difficulty'),
        startDate: any(named: 'startDate'),
      )).thenAnswer((_) async {});
  whenListen(
    mockCubit,
    const Stream<AiDescriptionChatState>.empty(),
    initialState: const AiDescriptionChatState(
      sendResult: ResultState<AiDescriptionResult>.initial(),
      remainingQuota: 10,
      isQuotaInitialized: true,
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  final gI = GetIt.instance;
  late MockAiDescriptionChatCubit mockCubit;

  setUp(() {
    mockCubit = MockAiDescriptionChatCubit();
    _setupMockCubit(mockCubit);

    if (!gI.isRegistered<PlaceService>()) {
      final mockPlace = MockPlaceService();
      when(() => mockPlace.autocomplete(any(), any()))
          .thenAnswer((_) async => []);
      gI.registerSingleton<PlaceService>(mockPlace);
    }
    if (gI.isRegistered<AiDescriptionChatCubit>()) {
      gI.unregister<AiDescriptionChatCubit>();
    }
    gI.registerFactory<AiDescriptionChatCubit>(() => mockCubit);
  });

  tearDown(() {
    if (gI.isRegistered<AiDescriptionChatCubit>()) {
      gI.unregister<AiDescriptionChatCubit>();
    }
  });

  // AC17 ──────────────────────────────────────────────────────────────────────

  testWidgets('AC17: section renders without error when isEditing=false',
      (tester) async {
    await tester.pumpWidget(_buildHost(isEditing: false));
    await tester.pumpAndSettle();
    expect(find.byType(EventFormBasicInfoSection), findsOneWidget);
  });

  testWidgets('AC17: section renders without error when isEditing=true',
      (tester) async {
    await tester.pumpWidget(_buildHost(isEditing: true));
    await tester.pumpAndSettle();
    expect(find.byType(EventFormBasicInfoSection), findsOneWidget);
  });

  // AC18 ──────────────────────────────────────────────────────────────────────

  testWidgets(
    'AC18: _buildEventContext maps title/eventType from form fields correctly',
    (tester) async {
      // eventType is set via the hidden FormBuilderField with explicit initialValue.
      // title is patched via FormBuilderState.patchValue after the widget is built.
      final formKey = GlobalKey<FormBuilderState>();
      await tester.pumpWidget(_buildHost(
        eventType: EventType.onRoad,
        formKey: formKey,
        cubit: mockCubit,
      ));
      await tester.pumpAndSettle();

      // Patch the name field value directly through the FormBuilder state.
      formKey.currentState!.patchValue({
        EventFormFields.name: 'Rodada del Pacífico',
      });
      await tester.pump();

      // Tap the "IA" button in the rich-text editor toolbar.
      await tester.tap(find.text('IA'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final pageFinder = find.byType(AiDescriptionChatPage);
      expect(
        pageFinder,
        findsOneWidget,
        reason: 'AiDescriptionChatPage must open after tapping IA button',
      );

      final page = tester.widget<AiDescriptionChatPage>(pageFinder);

      // title maps from EventFormFields.name
      expect(
        page.eventContext.title,
        'Rodada del Pacífico',
        reason: 'title must come from EventFormFields.name value',
      );

      // eventType maps from EventType.apiValue — _buildEventContext uses .apiValue
      expect(
        page.eventContext.eventType,
        EventType.onRoad.apiValue,
        reason: 'eventType must be the API value (uppercase), not the Dart enum .name',
      );

      // difficulty must be null when not set in the form
      expect(
        page.eventContext.difficulty,
        isNull,
        reason: 'difficulty must be null when not provided in the form',
      );
    },
  );

  testWidgets(
    'AC18: AiDescriptionRequest has no audience field (v1 omission confirmed)',
    (tester) async {
      await tester.pumpWidget(_buildHost(
        eventType: EventType.onRoad,
        cubit: mockCubit,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('IA'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final page = tester.widget<AiDescriptionChatPage>(
        find.byType(AiDescriptionChatPage),
      );

      final ctx = page.eventContext;
      // Only these fields exist in AiDescriptionRequest v1 — no 'audience'.
      expect(ctx.title, isA<String>());
      expect(ctx.eventType, isA<String>());
      expect(ctx.history, isEmpty);
      // startDate and difficulty are nullable — null when unset is correct.
    },
  );
}
