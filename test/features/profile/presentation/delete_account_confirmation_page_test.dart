// Widget tests de DeleteAccountConfirmationPage: switch habilita el botón
// (AC3), estado loading deshabilita y muestra spinner (AC4), estado error
// muestra el banner + botón de reintentar (AC6), y confirmar dispara la
// segunda confirmación antes de invocar el cubit.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/profile/presentation/cubits/delete_account_cubit.dart';
import 'package:rideglory/features/profile/presentation/delete_account_confirmation_page.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/modals/app_modal_action_button.dart';

class MockDeleteAccountCubit extends MockCubit<ResultState<Nothing>>
    implements DeleteAccountCubit {}

Widget _buildTestPage() {
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
    home: const DeleteAccountConfirmationPage(),
  );
}

// La página es un ListView largo (intro + lista de 4 ítems + switch + botón,
// más el banner de error); se agranda la superficie de test para que todo el
// contenido se monte sin depender de scroll manual, mismo patrón que
// edit_profile_page_test.dart.
void useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  late MockDeleteAccountCubit mockCubit;

  setUp(() {
    mockCubit = MockDeleteAccountCubit();
    whenListen(
      mockCubit,
      const Stream<ResultState<Nothing>>.empty(),
      initialState: const ResultState<Nothing>.initial(),
    );
    when(() => mockCubit.deleteAccount()).thenAnswer((_) async {});
    when(() => mockCubit.close()).thenAnswer((_) async {});
    GetIt.I.allowReassignment = true;
    GetIt.I.registerFactory<DeleteAccountCubit>(() => mockCubit);
  });

  tearDown(() {
    if (GetIt.I.isRegistered<DeleteAccountCubit>()) {
      GetIt.I.unregister<DeleteAccountCubit>();
    }
    GetIt.I.allowReassignment = false;
  });

  testWidgets(
    'el botón de confirmación empieza deshabilitado y se habilita al activar el switch',
    (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(_buildTestPage());
      await tester.pumpAndSettle();

      AppButton confirmButton() =>
          tester.widget<AppButton>(find.byType(AppButton));

      expect(confirmButton().onPressed, isNull);

      await tester.tap(find.text('Entiendo que esta acción es irreversible'));
      await tester.pumpAndSettle();

      expect(confirmButton().onPressed, isNotNull);
    },
  );

  testWidgets(
    'confirmar con el switch activo abre el diálogo de segunda confirmación y llama al cubit',
    (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(_buildTestPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entiendo que esta acción es irreversible'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      final dialogConfirmButton = find.widgetWithText(
        AppModalActionButton,
        'Eliminar cuenta',
      );
      expect(dialogConfirmButton, findsOneWidget);

      await tester.tap(dialogConfirmButton);
      await tester.pumpAndSettle();

      verify(() => mockCubit.deleteAccount()).called(1);
    },
  );

  testWidgets(
    'estado loading deshabilita el botón y muestra el spinner en vez del label',
    (tester) async {
      useTallSurface(tester);
      whenListen(
        mockCubit,
        const Stream<ResultState<Nothing>>.empty(),
        initialState: const ResultState<Nothing>.loading(),
      );

      await tester.pumpWidget(_buildTestPage());
      await tester.pump();

      expect(find.text('Eliminando…'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<AppButton>(find.byType(AppButton)).isLoading, isTrue);
    },
  );

  testWidgets(
    'estado error muestra el banner con mensaje y el botón cambia a Reintentar',
    (tester) async {
      useTallSurface(tester);
      whenListen(
        mockCubit,
        const Stream<ResultState<Nothing>>.empty(),
        initialState: const ResultState<Nothing>.error(
          error: DomainException(message: 'boom'),
        ),
      );

      await tester.pumpWidget(_buildTestPage());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No pudimos eliminar tu cuenta. Verifica tu conexión e intenta de nuevo.',
        ),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    },
  );
}
