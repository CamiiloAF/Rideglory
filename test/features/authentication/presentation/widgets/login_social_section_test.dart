// Widget tests for LoginSocialSection.
//
// Covers the mutual-exclusion behavior of `_loadingProvider`: while the
// Google sign-in is in progress the Apple button must be disabled, and vice
// versa (case 5.4 of the authentication QA checklist).
//
// Note on testability: `login_social_section.dart` gates the Google/Apple
// buttons behind `Platform.isAndroid`/`Platform.isIOS` (dart:io), which are
// `static final` values that reflect the actual host OS. A `flutter test`
// run always reports the dev/CI host OS (e.g. macOS or Linux), never
// android/ios, so on an unmodified widget neither button would ever render
// and this exclusion logic could not be exercised at all. To make this
// testable, `LoginSocialSection` exposes two `@visibleForTesting` static
// overrides (`debugIsAndroidOverride` / `debugIsIOSOverride`) that default to
// `null` and are ignored in production — they only let tests force a branch
// to render.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_social_button.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_social_section.dart';
import 'package:rideglory/l10n/app_localizations.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

Widget _wrap(AuthCubit authCubit) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(
      body: BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: const LoginSocialSection(),
      ),
    ),
  );
}

void main() {
  late MockAuthCubit authCubit;
  late MockAnalyticsService analyticsService;
  late MockFirebaseRemoteConfig remoteConfig;

  setUpAll(() {
    registerFallbackValue(const AuthState.initial());
  });

  setUp(() {
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(const AuthState.initial());
    whenListen(authCubit, const Stream<AuthState>.empty());
    when(() => authCubit.signInWithGoogle()).thenAnswer((_) async {});
    when(() => authCubit.signInWithApple()).thenAnswer((_) async {});

    analyticsService = MockAnalyticsService();
    when(
      () => analyticsService.logEvent(any(), any()),
    ).thenAnswer((_) async {});
    when(() => analyticsService.logEvent(any())).thenAnswer((_) async {});

    remoteConfig = MockFirebaseRemoteConfig();
    when(() => remoteConfig.getBool(any())).thenReturn(true);

    GetIt.I.allowReassignment = true;
    GetIt.I.registerSingleton<AnalyticsService>(analyticsService);
    GetIt.I.registerSingleton<FirebaseRemoteConfig>(remoteConfig);

    // Force both social buttons to render regardless of the host OS running
    // the test (see file header for why this is needed).
    LoginSocialSection.debugIsAndroidOverride = null;
    LoginSocialSection.debugIsIOSOverride = true;
  });

  tearDown(() {
    LoginSocialSection.debugIsAndroidOverride = null;
    LoginSocialSection.debugIsIOSOverride = null;
    if (GetIt.I.isRegistered<AnalyticsService>()) {
      GetIt.I.unregister<AnalyticsService>();
    }
    if (GetIt.I.isRegistered<FirebaseRemoteConfig>()) {
      GetIt.I.unregister<FirebaseRemoteConfig>();
    }
    GetIt.I.allowReassignment = false;
  });

  group('LoginSocialSection — mutual exclusion (case 5.4)', () {
    testWidgets(
      'TC-social-section-1: both buttons are enabled and idle initially',
      (tester) async {
        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        final buttons = tester
            .widgetList<LoginSocialButton>(find.byType(LoginSocialButton))
            .toList();

        expect(buttons, hasLength(2));
        expect(buttons.every((button) => !button.isDisabled), isTrue);
        expect(buttons.every((button) => !button.isLoading), isTrue);
      },
    );

    testWidgets(
      'TC-social-section-2: tapping Google disables and loads only the '
      'Google button, and disables (without loading) the Apple button',
      (tester) async {
        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        final googleButton = tester.widget<LoginSocialButton>(
          find.widgetWithText(
            LoginSocialButton,
            'Continuar con Google',
          ),
        );
        await tester.tap(find.byWidget(googleButton));
        await tester.pump();

        final buttonsAfterTap = tester
            .widgetList<LoginSocialButton>(find.byType(LoginSocialButton))
            .toList();
        final google = buttonsAfterTap.firstWhere(
          (button) => button.label == 'Continuar con Google',
        );
        final apple = buttonsAfterTap.firstWhere(
          (button) => button.label != 'Continuar con Google',
        );

        expect(google.isLoading, isTrue);
        expect(google.isDisabled, isTrue);
        expect(apple.isLoading, isFalse);
        expect(apple.isDisabled, isTrue);

        // Apple's InkWell is now a no-op — tapping it must not trigger sign-in.
        await tester.tap(find.byWidget(apple), warnIfMissed: false);
        await tester.pump();
        verifyNever(() => authCubit.signInWithApple());
      },
    );

    testWidgets(
      'TC-social-section-3: tapping Apple disables and loads only the '
      'Apple button, and disables (without loading) the Google button',
      (tester) async {
        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        final appleButton = tester
            .widgetList<LoginSocialButton>(find.byType(LoginSocialButton))
            .firstWhere((button) => button.label != 'Continuar con Google');
        await tester.tap(find.byWidget(appleButton));
        await tester.pump();

        final buttonsAfterTap = tester
            .widgetList<LoginSocialButton>(find.byType(LoginSocialButton))
            .toList();
        final google = buttonsAfterTap.firstWhere(
          (button) => button.label == 'Continuar con Google',
        );
        final apple = buttonsAfterTap.firstWhere(
          (button) => button.label != 'Continuar con Google',
        );

        expect(apple.isLoading, isTrue);
        expect(apple.isDisabled, isTrue);
        expect(google.isLoading, isFalse);
        expect(google.isDisabled, isTrue);

        await tester.tap(find.byWidget(google), warnIfMissed: false);
        await tester.pump();
        verifyNever(() => authCubit.signInWithGoogle());
      },
    );

    testWidgets(
      'TC-social-section-4: once the cubit resolves (non-loading state), '
      'both buttons re-enable',
      (tester) async {
        final controller = StreamController<AuthState>();
        addTearDown(controller.close);
        whenListen(authCubit, controller.stream);

        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        final googleButton = tester
            .widgetList<LoginSocialButton>(find.byType(LoginSocialButton))
            .firstWhere((button) => button.label == 'Continuar con Google');
        await tester.tap(find.byWidget(googleButton));
        await tester.pump();

        var buttons = tester
            .widgetList<LoginSocialButton>(find.byType(LoginSocialButton))
            .toList();
        expect(buttons.every((button) => button.isDisabled), isTrue);

        controller.add(const AuthState.error('boom'));
        await tester.pump();

        buttons = tester
            .widgetList<LoginSocialButton>(find.byType(LoginSocialButton))
            .toList();
        expect(buttons.every((button) => !button.isDisabled), isTrue);
        expect(buttons.every((button) => !button.isLoading), isTrue);
      },
    );
  });
}
