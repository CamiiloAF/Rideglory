// Widget tests for EventFormStep4Review — fixes for QA checklist gaps
// (docs/testing/qa-checklists/events_QA_CHECKLIST.md, casos 3D.6 y 4.1).
//
// 3D.6: verifies the real wiring of the "Editar" buttons on each ReviewCard
//       (goToStep(0)/goToStep(1)/goToStep(2)), and the real existence of a
//       "Cerrar" button in editing mode (instead of the tautological
//       "Publicar evento" absence check from AC-13).
// 4.1:  verifies EventStepIndicator is absent when the real editing-mode
//       widget tree (EventFormStep4Review + EventStepNavBar) is mounted,
//       instead of a placeholder Scaffold.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_form_step4_review.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_step_indicator.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockEventFormCubit extends MockCubit<EventFormState>
    implements EventFormCubit {}

class MockFormImageCubit extends MockCubit<ResultState<FormImageData>>
    implements FormImageCubit {}

class _MockNavigatorObserver extends Mock implements NavigatorObserver {}

class _FakeRoute extends Fake implements Route<dynamic> {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MockFormImageCubit _imageWithPhoto() {
  final imageCubit = MockFormImageCubit();
  when(() => imageCubit.state).thenReturn(
    const ResultState.data(
      data: FormImageData(remoteImageUrl: 'https://example.com/img.jpg'),
    ),
  );
  return imageCubit;
}

/// Mounts the real editing-mode tree used by step 4: the review page plus
/// its bottom nav bar, exactly as composed by `_EditingScaffold`.
Widget _wrapEditingStep4(MockEventFormCubit cubit) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<EventFormCubit>.value(value: cubit),
          BlocProvider<FormImageCubit>.value(value: _imageWithPhoto()),
        ],
        // EventFormStep4Review already composes its own EventStepNavBar
        // internally (Column: Expanded(review) + EventStepNavBar), mirroring
        // the real _EditingScaffold tree — no extra wrapping needed.
        child: const EventFormStep4Review(),
      ),
    ),
  );
}

MockEventFormCubit _editingCubit() {
  final cubit = MockEventFormCubit();
  when(
    () => cubit.state,
  ).thenReturn(const EventFormState(currentStep: 3, waypoints: []));
  when(() => cubit.isEditing).thenReturn(true);
  when(() => cubit.formKey).thenReturn(GlobalKey());
  when(() => cubit.goToStep(any())).thenReturn(null);
  return cubit;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ═════════════════════════════════════════════════════════════════════════
  // 3D.6 — Editar buttons wire to goToStep(0/1/2); Cerrar button exists
  // ═════════════════════════════════════════════════════════════════════════

  group('3D.6: EventFormStep4Review editing mode — real Editar wiring', () {
    testWidgets('tapping "Editar" on card 1 (Básico) calls goToStep(0)', (
      tester,
    ) async {
      final cubit = _editingCubit();
      await tester.pumpWidget(_wrapEditingStep4(cubit));
      await tester.pumpAndSettle();

      final editButtons = find.text('Editar');
      expect(editButtons, findsNWidgets(3));

      await tester.tap(editButtons.at(0));
      await tester.pumpAndSettle();

      verify(() => cubit.goToStep(0)).called(1);
    });

    testWidgets(
      'tapping "Editar" on card 2 (Descripción) calls goToStep(1)',
      (tester) async {
        final cubit = _editingCubit();
        await tester.pumpWidget(_wrapEditingStep4(cubit));
        await tester.pumpAndSettle();

        final editButtons = find.text('Editar');
        expect(editButtons, findsNWidgets(3));

        await tester.tap(editButtons.at(1));
        await tester.pumpAndSettle();

        verify(() => cubit.goToStep(1)).called(1);
      },
    );

    testWidgets(
      'tapping "Editar" on card 3 (Ruta y detalles) calls goToStep(2)',
      (tester) async {
        final cubit = _editingCubit();
        await tester.pumpWidget(_wrapEditingStep4(cubit));
        await tester.pumpAndSettle();

        final editButtons = find.text('Editar');
        expect(editButtons, findsNWidgets(3));

        await tester.ensureVisible(editButtons.at(2));
        await tester.pumpAndSettle();
        await tester.tap(editButtons.at(2));
        await tester.pumpAndSettle();

        verify(() => cubit.goToStep(2)).called(1);
      },
    );

    testWidgets(
      'a real "Cerrar" button is rendered (not "Publicar evento") and pops the '
      'route when tapped',
      (tester) async {
        final cubit = _editingCubit();
        final observer = _MockNavigatorObserver();
        registerFallbackValue(_FakeRoute());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            navigatorObservers: [observer],
            home: MultiBlocProvider(
              providers: [
                BlocProvider<EventFormCubit>.value(value: cubit),
                BlocProvider<FormImageCubit>.value(value: _imageWithPhoto()),
              ],
              child: const Scaffold(body: EventFormStep4Review()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Publicar evento'), findsNothing);
        final closeButton = find.text('Cerrar');
        expect(
          closeButton,
          findsOneWidget,
          reason:
              'En modo edición el step 4 debe mostrar un botón "Cerrar" real '
              '(PublishRow.isEditing branch), no solo la ausencia de '
              '"Publicar evento".',
        );

        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        verify(() => observer.didPop(any(), any())).called(1);
      },
    );
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 4.1 — Editing mode real tree does not render EventStepIndicator
  // ═════════════════════════════════════════════════════════════════════════

  group('4.1: real editing-mode tree has no EventStepIndicator', () {
    testWidgets(
      'EventFormStep4Review + EventStepNavBar in editing mode renders no '
      'EventStepIndicator',
      (tester) async {
        final cubit = _editingCubit();
        await tester.pumpWidget(_wrapEditingStep4(cubit));
        await tester.pumpAndSettle();

        expect(
          find.byType(EventStepIndicator),
          findsNothing,
          reason:
              'El árbol real de edición (EventFormStep4Review + '
              'EventStepNavBar) nunca compone EventStepIndicator, a '
              'diferencia del flujo de creación.',
        );
      },
    );
  });
}
