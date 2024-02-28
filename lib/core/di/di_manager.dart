import 'package:get_it/get_it.dart';
import '../../features/auth/sign_up/di/sign_up_di.dart';

import '../../features/files/di/files_di.dart';
import '../../features/users/di/users_di.dart';

abstract class DIManager {
  static GetIt getIt = GetIt.instance;

  static bool alreadyInitialized = false;

  static void initializeDependencies() {
    final dependencies = [
      SignUpDI(),
      UsersDI(),
      FilesDI(),
    ];

    for (final dependency in dependencies) {
      dependency.initializeDependencies();
    }

    alreadyInitialized = true;
  }
}
