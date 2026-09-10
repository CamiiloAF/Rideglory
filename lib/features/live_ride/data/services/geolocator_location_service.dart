import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/location_permission_state.dart';
import '../../domain/location_service.dart';
import '../../domain/rider_position.dart';

/// D14: `geolocator` para posición y permiso "mientras usa la app";
/// `permission_handler` solo para el segundo paso explícito de D21
/// (ubicación "todo el tiempo" en Android 10+, que `geolocator` no expone
/// como una solicitud separada — la deriva de si ya se concedió la de
/// primer plano).
@Injectable(as: LocationService)
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationPermissionState> permissionState() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionState.serviceDisabled;
    final permission = await Geolocator.checkPermission();
    return _fromGeolocatorPermission(permission);
  }

  @override
  Future<LocationPermissionState> requestWhileInUse() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionState.serviceDisabled;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return _fromGeolocatorPermission(permission);
  }

  @override
  Future<LocationPermissionState> requestAlways() async {
    final whileInUse = await requestWhileInUse();
    if (whileInUse != LocationPermissionState.whileInUse &&
        whileInUse != LocationPermissionState.always) {
      return whileInUse;
    }
    final status = await ph.Permission.locationAlways.request();
    if (status.isGranted) return LocationPermissionState.always;
    if (status.isPermanentlyDenied) {
      return LocationPermissionState.deniedForever;
    }
    return LocationPermissionState.whileInUse;
  }

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<RiderPosition?> currentPosition({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(timeLimit: timeout),
      );
      return _toDomain(position);
    } on TimeoutException {
      return _lastKnown();
    } catch (_) {
      return _lastKnown();
    }
  }

  Future<RiderPosition?> _lastKnown() async {
    final position = await Geolocator.getLastKnownPosition();
    return position == null ? null : _toDomain(position);
  }

  @override
  Stream<RiderPosition> positionStream({double distanceFilterMeters = 25}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        distanceFilter: distanceFilterMeters.round(),
      ),
    ).map(_toDomain);
  }

  RiderPosition _toDomain(Position position) => RiderPosition(
    lat: position.latitude,
    lng: position.longitude,
    recordedAt: position.timestamp,
    speedKmh: position.speed * 3.6,
    heading: position.heading,
    accuracyM: position.accuracy,
  );

  LocationPermissionState _fromGeolocatorPermission(
    LocationPermission permission,
  ) {
    return switch (permission) {
      LocationPermission.always => LocationPermissionState.always,
      LocationPermission.whileInUse => LocationPermissionState.whileInUse,
      LocationPermission.deniedForever => LocationPermissionState.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => LocationPermissionState.denied,
    };
  }
}
