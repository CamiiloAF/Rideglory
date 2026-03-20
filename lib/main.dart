import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/shared/router/app_router.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

import 'firebase_options.dart';

Future<void> main() async {
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

  await Firebase.initializeApp(options: firebaseOptions);
  await initializeDateFormatting();

  configureDependencies();

  runApp(const MyApp());
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
      ],
      child: MaterialApp.router(
        routerConfig: AppRouter.appRouter,
        onGenerateTitle: (context) => context.l10n.appName,
        theme: AppTheme.lightTheme,
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
