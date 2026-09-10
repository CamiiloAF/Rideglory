import 'package:battery_plus/battery_plus.dart';
import 'package:injectable/injectable.dart';

import '../../domain/battery_service.dart';

@Injectable(as: BatteryService)
class BatteryPlusService implements BatteryService {
  const BatteryPlusService(this._battery);

  final Battery _battery;

  @override
  Future<int?> currentLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return null;
    }
  }
}
