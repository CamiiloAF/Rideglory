import 'package:battery_plus/battery_plus.dart';
import 'package:injectable/injectable.dart';

/// Registra el cliente de `battery_plus` que consume `BatteryPlusService`.
@module
abstract class BatteryModule {
  @lazySingleton
  Battery get battery => Battery();
}
