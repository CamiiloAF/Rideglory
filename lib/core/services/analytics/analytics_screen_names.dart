import 'package:rideglory/shared/router/app_routes.dart';

/// Mapa canónico ruta→nombre de pantalla estable para Firebase Analytics.
///
/// Contratos:
/// - Clave = `GoRoute.path` (valor de [AppRoutes]); nunca la URI concreta
///   con valores de parámetros o query strings.
/// - Valor = nombre estable, snake_case, sin ids, sin params dinámicos.
///   P.ej. `event_detail_by_id` → `event_detail`.
/// - Toda nueva ruta agregada a [AppRoutes] debe tener entrada aquí para
///   evitar omisiones silenciosas de `screen_view`.
///
/// Consume: [AnalyticsRouteObserver] (Fase 3) y [ShellScreenViewTracker].
/// Produce: nombres estables que aparecen en GA4 DebugView / reportes.
abstract final class AnalyticsScreenNames {
  /// Mapa canónico `path → nombre de pantalla estable`.
  ///
  /// Usar [forPath] para hacer el lookup (devuelve `null` si la ruta no
  /// está mapeada, en cuyo caso el observer omite el `screen_view`).
  static const Map<String, String> _map = {
    // Splash
    AppRoutes.splash: 'splash',

    // Auth
    AppRoutes.login: 'login',
    AppRoutes.signup: 'signup',
    AppRoutes.forgotPassword: 'forgot_password',

    // Shell branches (tabs)
    AppRoutes.home: 'home',
    AppRoutes.garage: 'garage',
    AppRoutes.events: 'events',
    AppRoutes.profile: 'profile',

    // Profile sub-routes
    AppRoutes.editProfile: 'profile_edit',

    // Vehicles
    AppRoutes.createVehicle: 'vehicle_create',
    AppRoutes.vehicleDetail: 'vehicle_detail',
    AppRoutes.editVehicle: 'vehicle_edit',

    // Maintenance
    AppRoutes.maintenances: 'maintenances',
    AppRoutes.createMaintenance: 'maintenance_create',
    AppRoutes.editMaintenance: 'maintenance_edit',
    AppRoutes.maintenanceDetail: 'maintenance_detail',

    // Events
    AppRoutes.myEvents: 'events_mine',
    AppRoutes.myDrafts: 'events_drafts',
    AppRoutes.createEvent: 'event_create',
    AppRoutes.editEvent: 'event_edit',
    AppRoutes.eventDetail: 'event_detail',
    AppRoutes.eventRegistration: 'event_registration',
    AppRoutes.eventAttendees: 'event_attendees',
    AppRoutes.liveMap: 'live_map',
    AppRoutes.participants: 'participants',
    AppRoutes.myRegistrations: 'my_registrations',
    AppRoutes.registrationDetail: 'registration_detail',

    // event_detail_by_id → mismo nombre canónico que event_detail
    // (ambas pantallas muestran el detalle de un evento; la distinción
    // es de navegación, no de pantalla).
    AppRoutes.eventDetailById: 'event_detail',

    // Riders
    AppRoutes.riderProfile: 'rider_profile',

    // Notifications
    AppRoutes.notifications: 'notifications',

    // SOAT
    AppRoutes.soatStatus: 'soat_status',
    AppRoutes.soatManualCapture: 'soat_manual_capture',
  };

  /// Devuelve el nombre canónico estable para [path], o `null` si la ruta
  /// no está mapeada (p.ej. diálogos / bottom sheets sin `GoRoute`).
  ///
  /// El observer debe omitir el `screen_view` cuando este método devuelve
  /// `null` — nunca inventar un nombre desde el path crudo.
  static String? forPath(String path) => _map[path];

  /// Paths de las rutas raíz de cada branch del [StatefulShellRoute].
  ///
  /// Índice → path raíz del branch. Usado por [ShellScreenViewTracker]
  /// para traducir `navigationShell.currentIndex` a nombre canónico.
  static const List<String> branchRootPaths = [
    AppRoutes.home,   // branch 0
    AppRoutes.garage, // branch 1
    AppRoutes.events, // branch 2
    AppRoutes.profile, // branch 3
  ];
}
