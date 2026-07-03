import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:rideglory/core/config/api_remote_config.dart';
import 'package:rideglory/core/config/app_env.dart';
import 'package:rideglory/core/http/api_base_url_resolver.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/crash/crash_handler_setup.dart';
import 'package:rideglory/core/services/crash/crash_reporter.dart';
import 'package:rideglory/core/services/crash/sentry_crash_reporter.dart';
import 'package:rideglory/core/services/fcm_service.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:rideglory/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/shared/router/app_router.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

import 'firebase_options.dart';

// DSN leído en tiempo de compilación desde --dart-define-from-file=config/<flavor>.json.
// Vacío en dev → Sentry no envía nada. DSN real en prod.
// NO usar @EnviedField — envied no procesa --dart-define (D4 rev 2).
const String _sentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue: '',
);

void main() {
  // runZonedGuarded debe envolver TODA la inicialización + runApp para que
  // WidgetsFlutterBinding.ensureInitialized() y runApp estén en la misma zona.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
      if (firebaseOptions.apiKey.isEmpty ||
          firebaseOptions.appId.isEmpty ||
          firebaseOptions.messagingSenderId.isEmpty ||
          firebaseOptions.projectId.isEmpty) {
        throw StateError(
          'Missing Firebase configuration. Pass required values using --dart-define.',
        );
      }

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await Firebase.initializeApp(options: firebaseOptions);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Sentry init — ANTES de Remote Config para capturar errores de startup
      // (red caída en primer arranque, Firebase falla, etc.) y antes de DI para
      // que TracingClientAdapter esté activo cuando AppDio.addSentry() se ejecute
      // dentro de configureDependencies().
      await SentryFlutter.init((options) {
        options.dsn = _sentryDsn;
        options.environment = kReleaseMode ? 'prod' : 'dev';
        options.tracesSampleRate = kReleaseMode ? 0.2 : 0.0;
        // tracePropagationTargets restringe el header sentry-trace al host
        // Rideglory y hosts locales de dev. Nunca Mapbox ni Firebase Storage.
        options.tracePropagationTargets.clear();
        options.tracePropagationTargets.addAll([
          'api.rideglory.com',
          '10.0.2.2',
          'localhost',
        ]);
        options.beforeSend = (event, hint) {
          if (kDebugMode) return null;
          return scrubPiiFromEvent(event);
        };
        options.beforeBreadcrumb = (crumb, hint) {
          if (crumb == null) return null;
          return scrubPiiFromBreadcrumb(crumb);
        };
      });

      // Remote Config tras Sentry para que errores de red queden capturados.
      // fetchAndActivate() es fault-tolerant: continúa con defaults si falla.
      await ApiRemoteConfig.initialize(FirebaseRemoteConfig.instance);
      await initializeDateFormatting();

      const mapboxToken = AppEnv.mapboxAccessToken;
      assert(
        mapboxToken != null && mapboxToken.isNotEmpty,
        'MAPBOX_ACCESS_TOKEN must be set in .env',
      );
      MapboxOptions.setAccessToken(mapboxToken!);

      final resolvedApiUrl = ApiBaseUrlResolver(
        FirebaseRemoteConfig.instance,
      ).resolve();

      // AC8: Registrar api_base_url como tag de scope Sentry.
      // Reemplaza crashlytics.setCustomKey('api_base_url', ...) eliminado en D13.
      // Sentry vacío en dev (DSN vacío) → el tag se setea pero nunca se envía.
      Sentry.configureScope(
        (scope) => scope.setTag('api_base_url', resolvedApiUrl),
      );

      // DI después de Sentry para que TracingClientAdapter se active en AppDio.
      const diEnvironment = kReleaseMode ? 'prod' : 'dev';
      configureDependencies(environment: diEnvironment);

      try {
        await getIt<CrashReporter>().setEnabled(!kDebugMode);
      } catch (_) {}
      try {
        await getIt<AnalyticsService>().setEnabled(!kDebugMode);
      } catch (_) {}

      try {
        registerCrashHandlers(
          isDebug: kDebugMode,
          reporter: getIt<CrashReporter>(),
        );
      } catch (_) {}

      runApp(const MyApp());
    },
    (error, stack) {
      if (kDebugMode) {
        // No silenciar errores de arranque en debug: si la config de Firebase
        // falta (p. ej. se corrió sin --dart-define-from-file=config/<flavor>.json)
        // la app se quedaba en el splash sin ningún log. Ahora se ve en consola.
        FlutterError.dumpErrorToConsole(
          FlutterErrorDetails(exception: error, stack: stack),
        );
      } else {
        // Sentry se inicializa antes que DI, así que captureException funciona
        // incluso para errores de startup pre-DI (Remote Config, Firebase, etc.).
        Sentry.captureException(error, stackTrace: stack);
        try {
          getIt<CrashReporter>().recordError(error, stack, fatal: false);
        } catch (_) {}
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt.get<AuthCubit>()..checkAuthState(),
        ),
        BlocProvider(create: (context) => getIt.get<VehicleCubit>()),
        BlocProvider(
          create: (context) =>
              getIt.get<MyRegistrationsCubit>()..fetchMyRegistrations(),
        ),
        BlocProvider(create: (context) => getIt.get<ProfileCubit>()),
        BlocProvider(create: (context) => getIt.get<NotificationsCubit>()),
      ],
      child: MaterialApp.router(
        scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
        routerConfig: AppRouter.appRouter,
        onGenerateTitle: (context) => context.l10n.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
      ),
    );
  }
}
