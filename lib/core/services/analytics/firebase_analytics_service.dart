import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';

import 'analytics_service.dart';

@Injectable(as: AnalyticsService)
@Environment('prod')
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> logScreenView(String screenName) {
    return _analytics.logScreenView(screenName: screenName);
  }

  @override
  Future<void> setUserId(String hashedId) {
    return _analytics.setUserId(id: hashedId);
  }

  @override
  Future<void> setUserProperty(String name, String value) {
    return _analytics.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> setEnabled(bool enabled) {
    return _analytics.setAnalyticsCollectionEnabled(enabled);
  }
}
