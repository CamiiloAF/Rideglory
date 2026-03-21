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

/// Outcome after requesting permissions needed for live map tracking.
enum LiveTrackingLocationPermissionOutcome {
  /// "Always" / background location granted — updates continue off-screen.
  backgroundGranted,

  /// Only while-in-use / foreground — tracking works with the app open.
  foregroundOnly,

  /// Location access denied — cannot start tracking.
  denied,
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

  /// Requests foreground location, then "always" / background (required for
  /// updates when the app is backgrounded on Android 10+ and iOS).
  static Future<LiveTrackingLocationPermissionOutcome>
      requestForLiveTracking() async {
    var foreground = await _permission.status;
    if (!foreground.isGranted) {
      foreground = await _permission.request();
    }
    if (!foreground.isGranted) {
      return LiveTrackingLocationPermissionOutcome.denied;
    }

    if (Platform.isAndroid) {
      var notification = await Permission.notification.status;
      if (!notification.isGranted) {
        notification = await Permission.notification.request();
      }
    }

    var background = await Permission.locationAlways.status;
    if (background.isGranted) {
      return LiveTrackingLocationPermissionOutcome.backgroundGranted;
    }

    background = await Permission.locationAlways.request();
    if (background.isGranted) {
      return LiveTrackingLocationPermissionOutcome.backgroundGranted;
    }

    return LiveTrackingLocationPermissionOutcome.foregroundOnly;
  }

  static LocationPermissionResult _mapStatus(PermissionStatus status) {
    if (status.isGranted) return LocationPermissionResult.granted;
    if (status.isPermanentlyDenied) {
      return LocationPermissionResult.permanentlyDenied;
    }
    if (status.isRestricted) return LocationPermissionResult.restricted;
    return LocationPermissionResult.denied;
  }
}

