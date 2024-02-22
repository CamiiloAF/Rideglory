
import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_router.dart';

class LoggedUserGuard extends AutoRouteGuard {
  @override
  void onNavigation(
    final NavigationResolver resolver,
    final StackRouter router,
  ) {
    if (FirebaseAuth.instance.currentUser != null &&
        resolver.route.name == SignInRoute.name) {
      resolver.redirect(const HomeRoute());
    } else {
      return resolver.next();
    }
  }
}
