import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/presentation/event_registration_page.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_page.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_page.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_page.dart';
import 'package:rideglory/features/events/presentation/detail/event_detail_page.dart';
import 'package:rideglory/features/events/presentation/detail/params.dart';
import 'package:rideglory/features/events/presentation/form/event_form_page.dart';
import 'package:rideglory/features/events/presentation/list/events_page.dart';
import 'package:rideglory/features/events/presentation/detail/event_detail_by_id_page.dart';
import 'package:rideglory/features/events/presentation/drafts/my_drafts_page.dart';
import 'package:rideglory/features/events/presentation/tracking/live_map_page.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/participants_placeholder_page.dart';
import 'package:rideglory/features/home/presentation/home_page.dart';
import 'package:rideglory/features/notifications/presentation/notifications_page.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_capture_page.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_capture_params.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_scan_page.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_scan_params.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_status_page.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_upload_page.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

import '../../features/authentication/application/auth_cubit.dart';
import '../../features/users/presentation/pages/rider_profile_page.dart';
import '../../features/authentication/login/presentation/login_view.dart';
import '../../features/authentication/login/presentation/forgot_password_view.dart';
import '../../features/authentication/signup/presentation/signup_view.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/edit_profile_page.dart';
import '../../features/users/domain/model/user_model.dart';
import '../../features/maintenance/presentation/detail/maintenance_detail_page.dart';
import '../../features/maintenance/presentation/form/maintenance_form_page.dart';
import '../../features/maintenance/presentation/list/maintenances/maintenances_page.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/vehicles/presentation/detail/vehicle_detail_page.dart';
import '../../features/vehicles/presentation/form/vehicle_form_page.dart';
import '../../features/vehicles/presentation/garage/garage_page.dart';
import '../widgets/main_shell.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  /// Navega a partir de una URI con scheme `rideglory://`.
  /// `rideglory://events/detail-by-id?id=xxx` → push `/events/detail-by-id?id=xxx`
  static void pushDeepLink(String ridegloryUri) {
    final uri = Uri.tryParse(ridegloryUri);
    if (uri == null || uri.scheme != 'rideglory') return;
    final path = '/${uri.host}${uri.path}';
    final routerPath = uri.hasQuery ? '$path?${uri.query}' : path;
    appRouter.push(routerPath);
  }

  static final GoRouter appRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = FirebaseAuth.instance.currentUser != null;

      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnAuthPage =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.forgotPassword;

      // Allow access to splash and auth pages
      if (isOnSplash || isOnAuthPage) {
        return null;
      }

      // Protect authenticated routes
      if (!isAuthenticated) {
        return AppRoutes.login;
      }

      final isEventRegistration =
          state.matchedLocation == AppRoutes.eventRegistration;
      if (isEventRegistration) {
        final extra = state.extra;
        if (extra is EventRegistrationParams) {
          final currentUserId = getIt<AuthCubit>().state.currentUser?.id;
          final event = extra.event;
          if (currentUserId != null && event.ownerId == currentUserId) {
            final eventId = event.id;
            if (eventId != null) {
              return Uri(
                path: AppRoutes.eventDetailById,
                queryParameters: {'id': eventId},
              ).toString();
            }
            return AppRoutes.events;
          }
        }
      }

      return null; // No redirect needed
    },
    refreshListenable: GoRouterRefreshStream(getIt.get<AuthCubit>().stream),
    routes: <RouteBase>[
      // Splash route
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splash,
        builder: (context, state) {
          return const SplashScreen();
        },
      ),

      // Authentication routes
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.login,
        builder: (context, state) {
          return const LoginView();
        },
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: AppRoutes.signup,
        builder: (context, state) {
          return const SignupView();
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPassword,
        builder: (context, state) {
          return const ForgotPasswordView();
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(
            navigationShell: navigationShell,
            showNotificationBadge: true,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.garage,
                name: AppRoutes.garage,
                builder: (context, state) => const GaragePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.events,
                name: AppRoutes.events,
                builder: (context, state) => const EventsPage(),
              ),
              GoRoute(
                path: AppRoutes.myEvents,
                name: AppRoutes.myEvents,
                builder: (context, state) =>
                    const EventsPage(showMyEvents: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: AppRoutes.editProfile,
                    builder: (context, state) {
                      final user = state.extra as UserModel;
                      return EditProfilePage(user: user);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.createVehicle,
        name: AppRoutes.createVehicle,
        builder: (context, state) {
          return const VehicleFormPage();
        },
      ),
      GoRoute(
        path: AppRoutes.vehicleDetail,
        name: AppRoutes.vehicleDetail,
        builder: (context, state) {
          final vehicle = state.extra as VehicleModel;
          return VehicleDetailPage(vehicle: vehicle);
        },
      ),
      GoRoute(
        path: AppRoutes.editVehicle,
        name: AppRoutes.editVehicle,
        builder: (context, state) {
          final vehicle = state.extra as VehicleModel?;
          return VehicleFormPage(vehicle: vehicle);
        },
      ),
      GoRoute(
        path: AppRoutes.vehicleSoat,
        name: AppRoutes.vehicleSoat,
        builder: (context, state) {
          final vehicle = state.extra as VehicleModel;
          return SoatUploadPage(vehicle: vehicle);
        },
      ),

      // Maintenance routes
      GoRoute(
        path: AppRoutes.maintenances,
        name: AppRoutes.maintenances,
        builder: (context, state) {
          final initialVehicleId = state.extra as String?;
          return MaintenancesPage(initialVehicleId: initialVehicleId);
        },
      ),
      GoRoute(
        path: AppRoutes.createMaintenance,
        name: AppRoutes.createMaintenance,
        builder: (context, state) {
          final vehicle = state.extra as VehicleModel?;
          return MaintenanceFormPage(preselectedVehicle: vehicle);
        },
      ),
      GoRoute(
        path: AppRoutes.editMaintenance,
        name: AppRoutes.editMaintenance,
        builder: (context, state) {
          final maintenance = state.extra as MaintenanceModel?;
          return MaintenanceFormPage(maintenance: maintenance);
        },
      ),
      GoRoute(
        path: AppRoutes.maintenanceDetail,
        name: AppRoutes.maintenanceDetail,
        builder: (context, state) {
          final maintenance = state.extra as MaintenanceModel;
          return MaintenanceDetailPage(maintenance: maintenance);
        },
      ),

      GoRoute(
        path: AppRoutes.myDrafts,
        name: AppRoutes.myDrafts,
        builder: (context, state) => const MyDraftsPage(),
      ),
      GoRoute(
        path: AppRoutes.createEvent,
        name: AppRoutes.createEvent,
        builder: (context, state) => const EventFormPage(),
      ),
      GoRoute(
        path: AppRoutes.editEvent,
        name: AppRoutes.editEvent,
        builder: (context, state) {
          final event = state.extra as EventModel?;
          return EventFormPage(event: event);
        },
      ),
      GoRoute(
        path: AppRoutes.eventDetail,
        name: AppRoutes.eventDetail,
        builder: (context, state) {
          final event = state.extra as EventModel;
          return EventDetailPage(params: EventDetailPageParams(event: event));
        },
      ),
      GoRoute(
        path: AppRoutes.eventRegistration,
        name: AppRoutes.eventRegistration,
        builder: (context, state) {
          final params = state.extra as EventRegistrationParams;
          return EventRegistrationPage(params: params);
        },
      ),
      GoRoute(
        path: AppRoutes.eventAttendees,
        name: AppRoutes.eventAttendees,
        builder: (context, state) {
          final event = state.extra as EventModel;
          return AttendeesPage(event: event);
        },
      ),
      GoRoute(
        path: AppRoutes.liveMap,
        name: AppRoutes.liveMap,
        builder: (context, state) {
          final event = state.extra as EventModel;
          return LiveMapPage(event: event);
        },
      ),
      GoRoute(
        path: AppRoutes.participants,
        name: AppRoutes.participants,
        builder: (context, state) {
          final event = state.extra as EventModel;
          return ParticipantsPlaceholderPage(event: event);
        },
      ),
      GoRoute(
        path: AppRoutes.myRegistrations,
        name: AppRoutes.myRegistrations,
        builder: (context, state) => const MyRegistrationsPage(),
      ),
      GoRoute(
        path: AppRoutes.registrationDetail,
        name: AppRoutes.registrationDetail,
        builder: (context, state) {
          final extra = state.extra as RegistrationDetailExtra;
          return RegistrationDetailPage(params: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.eventDetailById,
        name: AppRoutes.eventDetailById,
        builder: (context, state) {
          final eventIdFromQuery = state.uri.queryParameters['id'];
          final eventIdFromExtra = state.extra is String
              ? state.extra as String
              : null;
          final eventId = eventIdFromQuery ?? eventIdFromExtra ?? '';
          return EventDetailByIdPage(eventId: eventId);
        },
      ),
      GoRoute(
        path: AppRoutes.riderProfile,
        name: AppRoutes.riderProfile,
        builder: (context, state) {
          final userId = state.extra as String;
          return RiderProfilePage(userId: userId);
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: AppRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.soatUpload,
        name: AppRoutes.soatUpload,
        builder: (context, state) {
          final vehicle = state.extra as VehicleModel;
          return SoatUploadPage(vehicle: vehicle);
        },
      ),
      GoRoute(
        path: AppRoutes.soatStatus,
        name: AppRoutes.soatStatus,
        builder: (context, state) {
          final vehicle = state.extra as VehicleModel;
          return SoatStatusPage(vehicle: vehicle);
        },
      ),
      GoRoute(
        path: AppRoutes.soatManualCapture,
        name: AppRoutes.soatManualCapture,
        builder: (context, state) {
          final params = state.extra as SoatManualCaptureParams;
          return SoatManualCapturePage(
            vehicle: params.vehicle,
            existingSoat: params.soat,
            initialLocalImagePath: params.initialLocalImagePath,
            extraction: params.extraction,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.soatScan,
        name: AppRoutes.soatScan,
        builder: (context, state) {
          final params = state.extra as SoatScanParams;
          return SoatScanPage(params: params);
        },
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
