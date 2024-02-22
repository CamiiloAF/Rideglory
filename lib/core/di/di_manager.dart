import 'package:get_it/get_it.dart';
import 'package:rideglory/features/auth/sign_up/di/sign_up_di.dart';

import '../../features/users/di/users_di.dart';

abstract class DIManager {
  static GetIt getIt = GetIt.instance;

  static bool alreadyInitialized = false;

  static void initializeDependencies() {
    final dependencies = [
      SignUpDI(),
      UsersDI(),
    ];

    for (final dependency in dependencies) {
      dependency.initializeDependencies();
    }

    alreadyInitialized = true;
  }
}
