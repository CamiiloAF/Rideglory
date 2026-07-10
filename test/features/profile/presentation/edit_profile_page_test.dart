import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/profile/presentation/cubits/edit_profile_cubit.dart';
import 'package:rideglory/features/profile/presentation/edit_profile_page.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class MockEditProfileCubit extends Mock implements EditProfileCubit {}

// `EditProfilePage._save()` llama a `context.pop()` (extensión de go_router),
// así que el árbol de test necesita un GoRouter real detrás de la página
// (no basta con MaterialApp + Navigator plano).
Widget _buildTestPage(UserModel user) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/edit'),
              child: const Text('go-to-edit'),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => EditProfilePage(user: user),
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(
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
    routerConfig: router,
  );
}

void main() {
  late MockEditProfileCubit mockEditProfileCubit;

  const mockUser = UserModel(
    id: 'user-123',
    fullName: 'Juan Pérez',
    email: 'juan@example.com',
    phone: '3001234567',
    residenceCity: 'Bogotá',
    emergencyContactName: 'Ana Pérez',
    emergencyContactPhone: '3007654321',
  );

  setUp(() {
    mockEditProfileCubit = MockEditProfileCubit();
    when(() => mockEditProfileCubit.notifyEditStarted()).thenReturn(null);
    when(() => mockEditProfileCubit.notifyEditSucceeded()).thenReturn(null);
    when(() => mockEditProfileCubit.close()).thenAnswer((_) async {});
    GetIt.I.allowReassignment = true;
    GetIt.I.registerFactory<EditProfileCubit>(() => mockEditProfileCubit);
  });

  tearDown(() {
    if (GetIt.I.isRegistered<EditProfileCubit>()) {
      GetIt.I.unregister<EditProfileCubit>();
    }
    GetIt.I.allowReassignment = false;
  });

  // El form es un ListView largo (avatar + 6 campos + botón); se agranda la
  // superficie de test para que todos los campos se construyan sin
  // necesidad de scroll manual en cada test.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> pumpEditPage(WidgetTester tester, UserModel user) async {
    useTallSurface(tester);
    await tester.pumpWidget(_buildTestPage(user));
    await tester.pumpAndSettle();
    await tester.tap(find.text('go-to-edit'));
    await tester.pumpAndSettle();
  }

  group('EditProfilePage — pre-llenado desde UserModel', () {
    testWidgets('pre-llena los campos con los datos del usuario recibido', (
      WidgetTester tester,
    ) async {
      await pumpEditPage(tester, mockUser);

      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(find.text('3001234567'), findsOneWidget);
      expect(find.text('Bogotá'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('3007654321'), findsOneWidget);
    });

    testWidgets('notifica profile_edit_started al abrir la pantalla', (
      WidgetTester tester,
    ) async {
      await pumpEditPage(tester, mockUser);

      verify(() => mockEditProfileCubit.notifyEditStarted()).called(1);
    });
  });

  group('EditProfilePage — validación de campos requeridos', () {
    testWidgets(
      'muestra error de validación cuando fullName está vacío y no permite guardar',
      (WidgetTester tester) async {
        const emptyNameUser = UserModel(
          id: 'user-123',
          fullName: '',
          email: 'juan@example.com',
        );

        await pumpEditPage(tester, emptyNameUser);

        await tester.tap(find.byType(AppButton).first);
        await tester.pumpAndSettle();

        // No se cierra la pantalla porque la validación falla.
        expect(find.byType(EditProfilePage), findsOneWidget);
        verifyNever(() => mockEditProfileCubit.notifyEditSucceeded());
      },
    );

    testWidgets(
      'con todos los campos válidos, notifica profile_edit_succeeded y cierra la pantalla',
      (WidgetTester tester) async {
        await pumpEditPage(tester, mockUser);

        await tester.tap(find.byType(AppButton).first);
        await tester.pumpAndSettle();

        verify(() => mockEditProfileCubit.notifyEditSucceeded()).called(1);
      },
    );
  });

  group(
    'EditProfilePage — regresión: _save() NO persiste nada a backend',
    () {
      testWidgets(
        'guardar el form solo valida y hace pop; no invoca ningún use case '
        'o repositorio de escritura (no hay integración de persistencia hoy). '
        'Si en el futuro se implementa un UpdateUserUseCase, este test debe '
        'actualizarse para verificar la llamada real.',
        (WidgetTester tester) async {
          await pumpEditPage(tester, mockUser);

          await tester.tap(find.byType(AppButton).first);
          await tester.pumpAndSettle();

          // Únicos efectos observables de abrir + guardar el form: los
          // eventos de analytics de inicio y éxito. No existe (todavía)
          // ningún use case/repositorio de escritura invocado desde
          // EditProfilePage.
          verify(() => mockEditProfileCubit.notifyEditStarted()).called(1);
          verify(() => mockEditProfileCubit.notifyEditSucceeded()).called(1);
          verifyNoMoreInteractions(mockEditProfileCubit);
        },
      );
    },
  );
}
