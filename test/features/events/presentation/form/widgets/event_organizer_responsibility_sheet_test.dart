// Tests for EventOrganizerResponsibilitySheet (legal-consentimientos-fase5,
// Bloque A).
//
// Covers: accept → saveEvent with organizerAcceptedResponsibilityAt set + sheet
// pops on success; error → inline error text, sheet stays open, buttons
// re-enabled; review → sheet pops without calling saveEvent.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_organizer_responsibility_sheet.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

class MockEventFormCubit extends MockCubit<EventFormState>
    implements EventFormCubit {}

class MockFormImageCubit extends MockCubit<ResultState<FormImageData>>
    implements FormImageCubit {}

class FakeEventModel extends Fake implements EventModel {}

final _testEvent = EventModel(
  id: 'event-1',
  ownerId: 'owner-1',
  name: 'Rodada de prueba',
  description: 'desc',
  startDate: DateTime(2026, 8, 1),
  difficulty: EventDifficulty.one,
  meetingTime: DateTime(2026, 8, 1, 8),
  eventType: EventType.onRoad,
);

// showEventOrganizerResponsibilitySheet reads the cubits from context; for
// widget tests we open the sheet directly with injected mock cubits.
Widget _app({
  required MockEventFormCubit eventFormCubit,
  required MockFormImageCubit imageCubit,
}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(
      body: Center(
        child: Builder(
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('event-form'),
              ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider<EventFormCubit>.value(value: eventFormCubit),
                      BlocProvider<FormImageCubit>.value(value: imageCubit),
                    ],
                    child: EventOrganizerResponsibilitySheet(
                      eventToSave: _testEvent,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeEventModel());
  });

  late MockEventFormCubit eventFormCubit;
  late MockFormImageCubit imageCubit;
  late StreamController<EventFormState> stateController;

  setUp(() {
    eventFormCubit = MockEventFormCubit();
    imageCubit = MockFormImageCubit();
    stateController = StreamController<EventFormState>.broadcast();
    whenListen(
      eventFormCubit,
      stateController.stream,
      initialState: const EventFormState(),
    );
    when(
      () => imageCubit.state,
    ).thenReturn(const ResultState<FormImageData>.initial());
    when(
      () => eventFormCubit.setOrganizerResponsibility(any()),
    ).thenReturn(null);
    when(
      () => eventFormCubit.saveEvent(
        any(),
        localCoverImagePath: any(named: 'localCoverImagePath'),
        remoteCoverImageUrl: any(named: 'remoteCoverImageUrl'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() => stateController.close());

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('accept: calls setOrganizerResponsibility + saveEvent with '
      'organizerAcceptedResponsibilityAt set, then pops on success', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(eventFormCubit: eventFormCubit, imageCubit: imageCubit),
    );
    await openSheet(tester);

    await tester.tap(find.text('Acepto y publico el evento'));
    await tester.pump();

    verify(() => eventFormCubit.setOrganizerResponsibility(any())).called(1);
    final captured = verify(
      () => eventFormCubit.saveEvent(
        captureAny(),
        localCoverImagePath: any(named: 'localCoverImagePath'),
        remoteCoverImageUrl: any(named: 'remoteCoverImageUrl'),
      ),
    ).captured;
    expect(captured, hasLength(1));
    final savedEvent = captured.first as EventModel;
    expect(savedEvent.organizerAcceptedResponsibilityAt, isNotNull);

    stateController.add(
      const EventFormState(saveResult: ResultState.loading()),
    );
    await tester.pump();
    stateController.add(
      EventFormState(saveResult: ResultState.data(data: _testEvent)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acepto y publico el evento'), findsNothing);
    expect(find.text('event-form'), findsOneWidget);
  });

  testWidgets(
    'error: shows inline error text, does not pop, buttons re-enabled',
    (tester) async {
      await tester.pumpWidget(
        _app(eventFormCubit: eventFormCubit, imageCubit: imageCubit),
      );
      await openSheet(tester);

      await tester.tap(find.text('Acepto y publico el evento'));
      await tester.pump();

      stateController.add(
        const EventFormState(saveResult: ResultState.loading()),
      );
      await tester.pump();
      stateController.add(
        const EventFormState(
          saveResult: ResultState.error(
            error: DomainException(message: 'network down'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos publicar el evento. Por favor intenta de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Acepto y publico el evento'), findsOneWidget);

      // Buttons re-enabled: tapping accept again re-triggers the flow.
      await tester.tap(find.text('Acepto y publico el evento'));
      await tester.pump();
      verify(() => eventFormCubit.setOrganizerResponsibility(any())).called(2);
    },
  );

  testWidgets('review: pops without calling saveEvent', (tester) async {
    await tester.pumpWidget(
      _app(eventFormCubit: eventFormCubit, imageCubit: imageCubit),
    );
    await openSheet(tester);

    await tester.tap(find.text('Revisar evento'));
    await tester.pumpAndSettle();

    verifyNever(
      () => eventFormCubit.saveEvent(
        any(),
        localCoverImagePath: any(named: 'localCoverImagePath'),
        remoteCoverImageUrl: any(named: 'remoteCoverImageUrl'),
      ),
    );
    expect(find.text('Acepto y publico el evento'), findsNothing);
    expect(find.text('event-form'), findsOneWidget);
  });
}
