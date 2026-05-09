abstract final class ApiRoutes {
  static const signUp = '/users/sign-up';
  static const me = '/users/me';
  static const home = '/home';
  static const vehicles = '/vehicles';
  static const myVehicles = '/vehicles/my';
  static const events = '/events';
  static const myEvents = '/events/my';
  static const tracking = '/tracking';
  static const trackingWs = '$tracking/ws';

  static String eventTrackingStartSession(String eventId) =>
      '$events/$eventId/tracking/session/start';
  static String eventTrackingStopSession(String eventId) =>
      '$events/$eventId/tracking/session/stop';
  static String eventTrackingSnapshot(String eventId) =>
      '$events/$eventId/tracking/snapshot';
}
