import 'package:injectable/injectable.dart';

import '../location_permission_state.dart';
import '../location_service.dart';

@injectable
class GetLocationPermissionStateUseCase {
  const GetLocationPermissionStateUseCase(this._locationService);

  final LocationService _locationService;

  Future<LocationPermissionState> call() => _locationService.permissionState();
}
