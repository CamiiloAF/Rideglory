import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';

/// Location settings for live ride tracking: Android foreground service
/// notification and iOS background updates when [LocationPermission.always].
abstract class TrackingLocationSettings {
  static const int _distanceFilterMeters = 12;

  static LocationSettings positionStream({
    required LocationPermission geolocatorPermission,
  }) {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilterMeters,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilterMeters,
        intervalDuration: const Duration(seconds: 4),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: EventStrings.trackingForegroundServiceTitle,
          notificationText: EventStrings.trackingForegroundServiceBody,
          notificationChannelName:
              EventStrings.trackingForegroundServiceChannelName,
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final allowBackground =
          geolocatorPermission == LocationPermission.always;
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilterMeters,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: allowBackground,
        showBackgroundLocationIndicator: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _distanceFilterMeters,
    );
  }

  static LocationSettings currentFix() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
    );
  }
}
