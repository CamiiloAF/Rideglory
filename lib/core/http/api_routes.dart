abstract final class ApiRoutes {
  static const signUp = '/users/sign-up';
  static const me = '/users/me';
  static const home = '/home';
  static const maintenances = '/maintenances';
  static const vehicles = '/vehicles';
  static const myVehicles = '/vehicles/my';
  static const events = '/events';
  static const myEvents = '/events/my';
  static const tracking = '/tracking';
  static const trackingWs = '$tracking/ws';
  static const registrations = '/registrations';
  static const myRegistrations = '$registrations/me';
  static const placesAutocomplete = '/places/autocomplete';
  static const placesGeocode = '/places/geocode';
  static const placesDetails = '/places/details';

  static String eventTrackingStart(String eventId) =>
      '$events/$eventId/tracking/start';
  static String eventTrackingEnd(String eventId) =>
      '$events/$eventId/tracking/end';
  static String eventRoute(String eventId) => '$events/$eventId/route';

  static String eventTrackingStartSession(String eventId) =>
      '$events/$eventId/tracking/session/start';
  static String eventTrackingStopSession(String eventId) =>
      '$events/$eventId/tracking/session/stop';
  static String eventTrackingSnapshot(String eventId) =>
      '$events/$eventId/tracking/snapshot';

  static String eventRegistrations(String eventId) =>
      '$events/$eventId/registrations';
  static String myRegistrationForEvent(String eventId) =>
      '$events/$eventId/registrations/me';
  static String registration(String registrationId) =>
      '$registrations/$registrationId';
  static String cancelRegistration(String registrationId) =>
      '$registrations/$registrationId/cancel';
  static String approveRegistration(String registrationId) =>
      '$registrations/$registrationId/approve';
  static String rejectRegistration(String registrationId) =>
      '$registrations/$registrationId/reject';
  static String setRegistrationReadyForEdit(String registrationId) =>
      '$registrations/$registrationId/ready-for-edit';

  static const notifications = '/notifications';
  static const notificationsFcmToken = '/notifications/fcm-token';
  static const notificationsReadAll = '/notifications/read-all';

  static String vehicleSoat(String vehicleId) => '$vehicles/$vehicleId/soat';
  static String vehicleTecnomecanica(String vehicleId) =>
      '$vehicles/$vehicleId/tecnomecanica';
  static String notificationRead(String notificationId) =>
      '$notifications/$notificationId/read';
}
