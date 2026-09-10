import '../domain/location_permission_state.dart';

/// D21: `whileInUse` y `always` son ambos un permiso concedido para
/// arrancar el tracking; solo `always` evita la hoja LV2b.
bool isLiveRideLocationGranted(LocationPermissionState state) =>
    state == LocationPermissionState.whileInUse ||
    state == LocationPermissionState.always;

bool isLiveRideLocationAlways(LocationPermissionState state) =>
    state == LocationPermissionState.always;
