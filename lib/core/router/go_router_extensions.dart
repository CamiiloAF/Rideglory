import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';

/// Navegación para cambios de estado de sesión (logout, fin de onboarding):
/// limpia el stack por completo antes de ir a `route`. Para transiciones
/// normales dentro de una feature usa `context.pushNamed()`.
extension GoRouterStateChangeExtension on BuildContext {
  void goAndClearStack(String route) {
    while (GoRouter.of(this).canPop()) {
      GoRouter.of(this).pop();
    }
    GoRouter.of(this).go(route);
  }
}
