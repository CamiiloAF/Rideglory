import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocationPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

abstract class LocationPermissionHandler {
  static const String _askedOnSplashKey = 'asked_location_permission_on_splash';

  static Permission get _permission {
    if (Platform.isIOS) return Permission.locationWhenInUse;
    return Permission.location;
  }

  static Future<LocationPermissionResult> status() async {
    final s = await _permission.status;
    return _mapStatus(s);
  }

  static Future<LocationPermissionResult> request() async {
    final s = await _permission.request();
    return _mapStatus(s);
  }

  static Future<void> requestOnceOnFirstSplashOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(_askedOnSplashKey) ?? false;
    if (alreadyAsked) return;

    await prefs.setBool(_askedOnSplashKey, true);
    await _permission.request();
  }

  static Future<bool> openSettings() => openAppSettings();

  static LocationPermissionResult _mapStatus(PermissionStatus status) {
    if (status.isGranted) return LocationPermissionResult.granted;
    if (status.isPermanentlyDenied) {
      return LocationPermissionResult.permanentlyDenied;
    }
    if (status.isRestricted) return LocationPermissionResult.restricted;
    return LocationPermissionResult.denied;
  }
}

