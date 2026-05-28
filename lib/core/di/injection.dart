import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/events/data/cache/attendees_cache.dart';

import 'injection.config.dart';

GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() {
  if (!getIt.isRegistered<AttendeesCache>()) {
    getIt.registerSingleton<AttendeesCache>(AttendeesCache());
  }
  getIt.init();
}
