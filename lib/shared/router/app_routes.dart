abstract class AppRoutes {
  // Splash route
  static const String splash = '/';

  // Authentication routes
  static const String login = '/login';
  static const String signup = '/signup';

  // Onboarding routes
  static const String vehicleOnboarding = '/onboarding/vehicle';

  // Vehicle routes
  static const String vehicles = '/vehicles';
  static const String createVehicle = '/vehicles/create';
  static const String editVehicle = '/vehicles/edit';

  // Maintenance routes
  static const String maintenances = '/maintenances';
  static const String createMaintenance = '/maintenances/create';
  static const String editMaintenance = '/maintenances/edit';

  // Events routes
  static const String events = '/events';
  static const String myEvents = '/events/mine';
  static const String createEvent = '/events/create';
  static const String editEvent = '/events/edit';
  static const String eventDetail = '/events/detail';
  static const String eventRegistration = '/events/registration';
  static const String eventAttendees = '/events/attendees';
  static const String myRegistrations = '/events/my-registrations';
  static const String registrationDetail = '/events/registration-detail';
  static const String eventDetailById = '/events/detail-by-id';
}
