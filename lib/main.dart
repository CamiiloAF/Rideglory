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
import 'package:rideglory/core/config/api_remote_config.dart';
import 'package:rideglory/core/config/app_env.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/crash/crash_handler_setup.dart';
import 'package:rideglory/core/services/crash/crash_reporter.dart';
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

void main() {
  // runZonedGuarded debe envolver TODA la inicialización + runApp para que
  // WidgetsFlutterBinding.ensureInitialized() y runApp estén en la misma zona.
  runZonedGuarded(() async {
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
    await ApiRemoteConfig.initialize(FirebaseRemoteConfig.instance);
    await initializeDateFormatting();

    const mapboxToken = AppEnv.mapboxAccessToken;
    assert(
      mapboxToken != null && mapboxToken.isNotEmpty,
      'MAPBOX_ACCESS_TOKEN must be set in .env',
    );
    MapboxOptions.setAccessToken(mapboxToken!);

    configureDependencies();

    try {
      await getIt<CrashReporter>().setEnabled(!kDebugMode);
    } catch (_) {}
    try {
      await getIt<AnalyticsService>().setEnabled(!kDebugMode);
    } catch (_) {}

    registerCrashHandlers(
      isDebug: kDebugMode,
      reporter: getIt<CrashReporter>(),
    );

    runApp(const MyApp());
  }, (error, stack) {
    if (kDebugMode) {
      // No silenciar errores de arranque en debug: si la config de Firebase
      // falta (p. ej. se corrió sin --dart-define-from-file=config/<flavor>.json)
      // la app se quedaba en el splash sin ningún log. Ahora se ve en consola.
      FlutterError.dumpErrorToConsole(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    } else {
      try {
        getIt<CrashReporter>().recordError(error, stack, fatal: false);
      } catch (_) {}
    }
  });
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
