import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import 'pages/create_event_page.dart';
import 'pages/event_detail_page.dart';
import 'pages/event_registrants_page.dart';
import 'pages/registration_page.dart';

/// Rutas de eventos anidadas bajo `/events`, registradas con una línea en
/// `app_router.dart`.
List<RouteBase> eventsRoutes = [
  GoRoute(
    path: AppRoutes.eventCreatePath,
    name: AppRoutes.eventCreate,
    builder: (context, state) => const CreateEventPage(),
  ),
  GoRoute(
    path: AppRoutes.eventDetailPath,
    name: AppRoutes.eventDetail,
    builder: (context, state) =>
        EventDetailPage(eventId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: AppRoutes.eventRegistrationPath,
    name: AppRoutes.eventRegistration,
    builder: (context, state) =>
        RegistrationPage(eventId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: AppRoutes.eventRegistrantsPath,
    name: AppRoutes.eventRegistrants,
    builder: (context, state) => EventRegistrantsPage(
      eventId: state.pathParameters['id']!,
      maxParticipants: state.extra as int?,
    ),
  ),
];
