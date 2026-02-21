import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/shared/router/app_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/theme/app_theme.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        BlocProvider(create: (context) => getIt.get<VehicleListCubit>()),
      ],
      child: MaterialApp.router(
        routerConfig: AppRouter.appRouter,
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
      ),
    );
  }
}
