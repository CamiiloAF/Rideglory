/*
 * Created by Camilo Agudelo (CamiiloAF) on sep. 19 2023.
 */

import 'package:auto_route/auto_route.dart';
import 'package:rideglory/features/home/presentation/pages/home_screen.dart';
import 'package:rideglory/shared/routes/guards/logged_user_guard.dart';

import '../../features/auth/sign_in/presentation/sign_in_screen.dart';
import '../../features/auth/sign_up/presentation/sign_up_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => <AutoRoute>[
        AutoRoute(
          page: SignInRoute.page,
          path: '/sign-in',
          initial: true,
          guards: [LoggedUserGuard()],
        ),
        AutoRoute(
          page: SignUpRoute.page,
          path: '/sign-up',
          guards: [LoggedUserGuard()],
        ),
        AutoRoute(
          page: HomeRoute.page,
          path: '/home',
        ),
      ];
}
