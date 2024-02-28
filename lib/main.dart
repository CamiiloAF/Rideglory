import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/di_manager.dart';
import 'features/users/domain/repositories/users_repository_contract.dart';
import 'features/users/presentation/cubit/current_user/current_user_cubit.dart';
import 'firebase_options.dart';
import 'generated/l10n.dart';
import 'shared/routes/app_router.dart';
import 'shared/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/config/.env');

  DIManager.initializeDependencies();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (final context) => CurrentUserCubit(
          usersRepository: DIManager.getIt<UsersRepositoryContract>(),),
      child: MaterialApp.router(
        title: 'Rideglory',
        theme: AppTheme.darkTheme,
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es'),
          Locale('en'),
        ],
        routerConfig: _appRouter.config(
          reevaluateListenable: ReevaluateListenable.stream(
            FirebaseAuth.instance.authStateChanges(),
          ),
        ),
      ),
    );
  }
}
