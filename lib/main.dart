import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_env.dart';
import 'core/di/injection.dart';
import 'core/observability/app_sentry.dart';
import 'core/services/notifications/local_notifications_initializer.dart';
import 'core/router/app_router.dart';
import 'design_system/theme/app_theme.dart';
import 'features/documents/data/services/document_reminder_scheduler.dart';
import 'features/events/presentation/event_push_navigator.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'shared/cubits/connectivity/connectivity_cubit.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppSentry.runGuarded(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      publishableKey: AppEnv.supabaseAnonKey,
    );
    await LocalNotificationsInitializer.init();
    await configureDependencies();
    await getIt<DocumentReminderScheduler>().init();
    await getIt<EventPushNavigator>().init();

    runApp(const RidegloryApp());
  });
}

/// Raíz de la app: tema claro/oscuro (`ThemeMode.system`), router y los
/// cubits globales (`ConnectivityCubit`; `AuthCubit` es la excepción que se
/// resuelve directo por el router).
class RidegloryApp extends StatelessWidget {
  const RidegloryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => getIt<ConnectivityCubit>())],
      child: MaterialApp.router(
        title: 'Rideglory',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: buildAppRouter(),
      ),
    );
  }
}
