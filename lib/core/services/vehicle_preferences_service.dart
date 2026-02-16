import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@injectable
class VehiclePreferencesService {
  static const String _selectedVehicleIdKey = 'selected_vehicle_id';

  Future<bool> saveSelectedVehicleId(String vehicleId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_selectedVehicleIdKey, vehicleId);
  }

  Future<String?> getSelectedVehicleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedVehicleIdKey);
  }

  Future<bool> clearSelectedVehicleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_selectedVehicleIdKey);
  }
}
