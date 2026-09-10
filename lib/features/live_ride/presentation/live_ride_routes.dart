import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import 'live_ride_route_args.dart';
import 'live_ride_session_scope.dart';
import 'pages/live_ride_view.dart';
import 'pages/live_riders_page.dart';
import 'pages/sos_active_view.dart';

/// Rutas de `live_ride` (Bloque 3, F11): LV1 (`/live`), LV3-LV4
/// (`/live/sos`) y LV6 (`/live/riders`). Las tres comparten
/// [LiveRideSessionScope] vía `ShellRoute` — un solo [LiveRideCubit] y
/// [SosCubit] por sesión, para que un SOS confirmado en LV3 no se pierda
/// al navegar a `/live/sos`.
List<RouteBase> liveRideRoutes = [
  ShellRoute(
    builder: (context, state, child) {
      final eventId = state.pathParameters['id']!;
      return LiveRideSessionScope(eventId: eventId, child: child);
    },
    routes: [
      GoRoute(
        path: AppRoutes.eventLivePath,
        name: AppRoutes.eventLive,
        builder: (context, state) => LiveRideView(
          eventId: state.pathParameters['id']!,
          args: state.extra as LiveRideRouteArgs? ?? LiveRideRouteArgs.empty,
        ),
      ),
      GoRoute(
        path: AppRoutes.eventLiveSosPath,
        name: AppRoutes.eventLiveSos,
        builder: (context, state) => SosActiveView(
          eventId: state.pathParameters['id']!,
          args: state.extra as LiveRideRouteArgs? ?? LiveRideRouteArgs.empty,
        ),
      ),
      GoRoute(
        path: AppRoutes.eventLiveRidersPath,
        name: AppRoutes.eventLiveRiders,
        builder: (context, state) => LiveRidersPage(
          eventId: state.pathParameters['id']!,
          args: state.extra as LiveRideRouteArgs? ?? LiveRideRouteArgs.empty,
        ),
      ),
    ],
  ),
];
