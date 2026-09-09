import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import 'pages/email_auth_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/welcome_page.dart';

/// Rutas de autenticación, fuera del shell de pestañas. Se registran con
/// una sola línea en `app_router.dart`.
List<RouteBase> get authRoutes => [
  GoRoute(
    path: AppRoutes.welcomePath,
    name: AppRoutes.welcome,
    builder: (context, state) => const WelcomePage(),
    routes: [
      GoRoute(
        path: 'correo',
        name: AppRoutes.authEmailLogin,
        builder: (context, state) => const EmailAuthPage(),
      ),
      GoRoute(
        path: 'crear-cuenta',
        name: AppRoutes.authEmailRegister,
        builder: (context, state) => const EmailAuthPage(isRegister: true),
      ),
      GoRoute(
        path: 'recuperar',
        name: AppRoutes.authForgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
    ],
  ),
];
