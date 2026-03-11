abstract class AppRoutes {
  // Splash route
  static const String splash = '/';

  // Home route
  static const String home = '/home';

  // Authentication routes
  static const String login = '/login';
  static const String signup = '/signup';

  // Onboarding routes
  static const String vehicleOnboarding = '/onboarding/vehicle';

  // Vehicle routes
  static const String garage = '/garage';
  static const String createVehicle = '/vehicles/create';
  static const String editVehicle = '/vehicles/edit';

  static const String maintenances = '/maintenances';
  static const String createMaintenance = '/maintenances/create';
  static const String editMaintenance = '/maintenances/edit';
  static const String maintenanceDetail = '/maintenances/detail';

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
