import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/shared/router/app_router.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
          create: (context) =>
              AuthCubit(getIt.get<AuthService>())..checkAuthState(),
        ),
        BlocProvider(create: (context) => getIt.get<VehicleCubit>()),
        BlocProvider(create: (context) => getIt.get<VehicleListCubit>()),
      ],
      child: Builder(
        builder: (context) {
          // Load vehicles when authenticated
          context.read<AuthCubit>().stream.listen((authState) {
            if (authState.isAuthenticated) {
              context.read<VehicleListCubit>().loadVehicles();
            }
          });

          return MaterialApp.router(
            routerConfig: appRouter(context),
            title: 'Rideglory',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
          );
        },
      ),
    );
  }
}
