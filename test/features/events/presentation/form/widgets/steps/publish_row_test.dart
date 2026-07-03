// Tests for PublishRow's interceptor (legal-consentimientos-fase5, Bloque A):
//
// - Creation mode: publishing no longer calls saveEvent directly — it opens the
//   organizer-responsibility bottom sheet, reusing the SAME cubit/imageCubit
//   instances and the built EventModel. saveEvent only runs when the organizer
//   accepts inside the sheet.
// - Edit mode: unchanged, no sheet, no interceptor involved.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/publish_row.dart';
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

Widget _pump({
  required MockEventFormCubit eventFormCubit,
  required MockFormImageCubit imageCubit,
  required bool isSaving,
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
      body: MultiBlocProvider(
        providers: [
          BlocProvider<EventFormCubit>.value(value: eventFormCubit),
          BlocProvider<FormImageCubit>.value(value: imageCubit),
        ],
        child: PublishRow(isSaving: isSaving, cubit: eventFormCubit),
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

  setUp(() {
    eventFormCubit = MockEventFormCubit();
    imageCubit = MockFormImageCubit();
    when(
      () => imageCubit.state,
    ).thenReturn(const ResultState<FormImageData>.initial());
  });

  group('Creation mode', () {
    setUp(() {
      when(() => eventFormCubit.isEditing).thenReturn(false);
      when(() => eventFormCubit.state).thenReturn(const EventFormState());
      when(
        () => eventFormCubit.buildEventToSave(),
      ).thenAnswer((_) async => _testEvent);
    });

    testWidgets(
      'tapping publish opens the organizer-responsibility sheet instead of saving',
      (tester) async {
        await tester.pumpWidget(
          _pump(
            eventFormCubit: eventFormCubit,
            imageCubit: imageCubit,
            isSaving: false,
          ),
        );
        await tester.pump();

        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(const Locale('es'));
        expect(
          find.text(l10n.event_organizerResponsibility_title),
          findsOneWidget,
        );
        verifyNever(
          () => eventFormCubit.saveEvent(
            any(),
            localCoverImagePath: any(named: 'localCoverImagePath'),
            remoteCoverImageUrl: any(named: 'remoteCoverImageUrl'),
          ),
        );
      },
    );

    testWidgets(
      'does not open the sheet when buildEventToSave returns null (invalid form)',
      (tester) async {
        when(
          () => eventFormCubit.buildEventToSave(),
        ).thenAnswer((_) async => null);

        await tester.pumpWidget(
          _pump(
            eventFormCubit: eventFormCubit,
            imageCubit: imageCubit,
            isSaving: false,
          ),
        );
        await tester.pump();

        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(const Locale('es'));
        expect(
          find.text(l10n.event_organizerResponsibility_title),
          findsNothing,
        );
        verifyNever(
          () => eventFormCubit.saveEvent(
            any(),
            localCoverImagePath: any(named: 'localCoverImagePath'),
            remoteCoverImageUrl: any(named: 'remoteCoverImageUrl'),
          ),
        );
      },
    );

    testWidgets(
      'shows a SnackBar with event_formIncompleteMessage when buildEventToSave returns null',
      (tester) async {
        when(
          () => eventFormCubit.buildEventToSave(),
        ).thenAnswer((_) async => null);

        await tester.pumpWidget(
          _pump(
            eventFormCubit: eventFormCubit,
            imageCubit: imageCubit,
            isSaving: false,
          ),
        );
        await tester.pump();

        await tester.tap(find.byType(AppButton));
        // Do not settle: the SnackBar's own exit animation would otherwise
        // dismiss it before the assertion runs.
        await tester.pump();

        final l10n = await AppLocalizations.delegate.load(const Locale('es'));
        expect(find.text(l10n.event_formIncompleteMessage), findsOneWidget);
        expect(
          find.text(l10n.event_organizerResponsibility_title),
          findsNothing,
        );
      },
    );
  });

  group('Edit mode', () {
    setUp(() {
      when(() => eventFormCubit.isEditing).thenReturn(true);
      when(() => eventFormCubit.state).thenReturn(const EventFormState());
    });

    testWidgets('renders the close button, no sheet involved', (tester) async {
      await tester.pumpWidget(
        _pump(
          eventFormCubit: eventFormCubit,
          imageCubit: imageCubit,
          isSaving: false,
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('es'));
      expect(find.text(l10n.event_organizerResponsibility_title), findsNothing);
      verifyNever(() => eventFormCubit.buildEventToSave());
    });
  });
}
