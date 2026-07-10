import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';
import 'package:rideglory/features/events/presentation/tracking/live_tracking_session_holder.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/presentation/event_registration_page.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_page.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_page.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_page.dart';
import 'package:rideglory/features/events/presentation/detail/event_detail_page.dart';
import 'package:rideglory/features/events/presentation/detail/params.dart';
import 'package:rideglory/features/events/presentation/form/event_edit_params.dart';
import 'package:rideglory/features/events/presentation/form/event_form_page.dart';
import 'package:rideglory/features/events/presentation/list/events_page.dart';
import 'package:rideglory/features/events/presentation/detail/event_detail_by_id_page.dart';
import 'package:rideglory/features/events/presentation/tracking/live_map_page.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/participants_placeholder_page.dart';
import 'package:rideglory/features/home/presentation/home_page.dart';
import 'package:rideglory/features/notifications/presentation/notifications_page.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_capture_page.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_capture_params.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_status_page.dart';
import 'package:rideglory/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_page.dart';
import 'package:rideglory/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_params.dart';
import 'package:rideglory/features/tecnomecanica/presentation/pages/tecnomecanica_status_page.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

import '../../features/authentication/application/auth_cubit.dart';
import '../../features/users/presentation/pages/rider_profile_page.dart';
import '../../features/authentication/login/presentation/login_view.dart';
import '../../features/authentication/login/presentation/forgot_password_view.dart';
import '../../features/authentication/signup/presentation/signup_view.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/edit_profile_page.dart';
import '../../features/profile/presentation/delete_account_confirmation_page.dart';
import '../../features/users/domain/model/user_model.dart';
import '../../features/maintenance/presentation/detail/maintenance_detail_page.dart';
import '../../features/maintenance/presentation/form/maintenance_form_page.dart';
import '../../features/maintenance/presentation/list/maintenances/maintenances_page.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/vehicles/presentation/detail/vehicle_detail_page.dart';
import '../../features/vehicles/presentation/form/vehicle_form_page.dart';
import '../../features/vehicles/presentation/garage/garage_page.dart';
import '../widgets/main_shell.dart';
import 'analytics_route_observer.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  /// Key global para mostrar SnackBars desde fuera del árbol de widgets
  /// (p.ej. tras un pop donde el contexto local ya no existe).
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Navega a partir de una URI con scheme `rideglory://`.
  /// `rideglory://events/detail-by-id?id=xxx` → push `/events/detail-by-id?id=xxx`
  ///
  /// Si el path destino es un tab del shell (home, garage, events, profile) usa
  /// `go()` para cambiar de tab; de lo contrario usa `push()` para apilar encima.
  static void pushDeepLink(String ridegloryUri) {
    final uri = Uri.tryParse(ridegloryUri);
    if (uri == null || uri.scheme != 'rideglory') return;
    final path = '/${uri.host}${uri.path}';
    final routerPath = uri.hasQuery ? '$path?${uri.query}' : path;

    const shellTabPaths = {
      AppRoutes.home,
      AppRoutes.garage,
      AppRoutes.events,
      AppRoutes.profile,
    };

    if (shellTabPaths.contains(path)) {
      appRouter.go(routerPath);
    } else {
      appRouter.push(routerPath);
    }
  }

  /// Observer que emite `screen_view` automáticamente por cada transición de
  /// ruta. Expuesto para que [MainShell] lo pase al [ShellScreenViewTracker].
  static final AnalyticsRouteObserver analyticsObserver =
      AnalyticsRouteObserver(getIt<AnalyticsService>());

  static final GoRouter appRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    observers: <NavigatorObserver>[
      analyticsObserver,
      if (kReleaseMode) SentryNavigatorObserver(),
    ],
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
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'mine',
                    name: AppRoutes.myEvents,
                    builder: (context, state) =>
                        const EventsPage(showMyEvents: true),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'create',
                    name: AppRoutes.createEvent,
                    builder: (context, state) => const EventFormPage(),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'edit',
                    name: AppRoutes.editEvent,
                    builder: (context, state) {
                      final extra = state.extra;
                      if (extra is EventEditParams) {
                        return EventFormPage(
                          event: extra.event,
                          onSaved: extra.onSaved,
                        );
                      }
                      return EventFormPage(event: extra as EventModel?);
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'detail',
                    name: AppRoutes.eventDetail,
                    builder: (context, state) {
                      final event = state.extra as EventModel;
                      return EventDetailPage(
                        params: EventDetailPageParams(event: event),
                      );
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'registration',
                    name: AppRoutes.eventRegistration,
                    builder: (context, state) {
                      final params = state.extra as EventRegistrationParams;
                      return EventRegistrationPage(params: params);
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'attendees',
                    name: AppRoutes.eventAttendees,
                    builder: (context, state) {
                      final event = state.extra as EventModel;
                      return AttendeesPage(event: event);
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'live-map',
                    name: AppRoutes.liveMap,
                    builder: (context, state) {
                      final event = state.extra as EventModel;
                      return LiveMapPage(event: event);
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'participants',
                    name: AppRoutes.participants,
                    builder: (context, state) {
                      final event = state.extra as EventModel;
                      final cubit = getIt<LiveTrackingSessionHolder>()
                          .obtainForEvent(
                            eventId: event.id ?? '',
                            eventOwnerId: event.ownerId,
                          );
                      return BlocProvider<LiveTrackingCubit>.value(
                        value: cubit,
                        child: ParticipantsPlaceholderPage(event: event),
                      );
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'my-registrations',
                    name: AppRoutes.myRegistrations,
                    builder: (context, state) => const MyRegistrationsPage(),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'registration-detail',
                    name: AppRoutes.registrationDetail,
                    builder: (context, state) {
                      final extra = state.extra as RegistrationDetailExtra;
                      return RegistrationDetailPage(params: extra);
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'detail-by-id',
                    name: AppRoutes.eventDetailById,
                    builder: (context, state) {
                      final eventIdFromQuery = state.uri.queryParameters['id'];
                      final eventIdFromExtra = state.extra is String
                          ? state.extra as String
                          : null;
                      final eventId =
                          eventIdFromQuery ?? eventIdFromExtra ?? '';
                      return EventDetailByIdPage(eventId: eventId);
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'attendees/rider-profile',
                    name: AppRoutes.riderProfile,
                    builder: (context, state) {
                      final userId = state.extra as String;
                      return RiderProfilePage(userId: userId);
                    },
                  ),
                ],
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
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'edit',
                    name: AppRoutes.editProfile,
                    builder: (context, state) {
                      final user = state.extra as UserModel;
                      return EditProfilePage(user: user);
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'delete-account',
                    name: AppRoutes.deleteAccount,
                    builder: (context, state) =>
                        const DeleteAccountConfirmationPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.createVehicle,
        name: AppRoutes.createVehicle,
        builder: (context, state) {
          return const VehicleFormPage();
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.vehicleDetail,
        name: AppRoutes.vehicleDetail,
        builder: (context, state) {
          final vehicle = state.extra as VehicleModel;
          return VehicleDetailPage(vehicle: vehicle);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.editVehicle,
        name: AppRoutes.editVehicle,
        builder: (context, state) {
          final vehicle = state.extra as VehicleModel?;
          return VehicleFormPage(vehicle: vehicle);
        },
      ),
      // Maintenance routes
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.maintenances,
        name: AppRoutes.maintenances,
        builder: (context, state) {
          final extra = state.extra;
          final String? initialVehicleId;
          final bool readOnly;
          if (extra is Map<String, dynamic>) {
            initialVehicleId = extra['vehicleId'] as String?;
            readOnly = (extra['readOnly'] as bool?) ?? false;
          } else {
            initialVehicleId = extra as String?;
            readOnly = false;
          }
          return MaintenancesPage(
            initialVehicleId: initialVehicleId,
            readOnly: readOnly,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.createMaintenance,
        name: AppRoutes.createMaintenance,
        builder: (context, state) {
          final vehicle = state.extra as VehicleModel?;
          return MaintenanceFormPage(preselectedVehicle: vehicle);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.editMaintenance,
        name: AppRoutes.editMaintenance,
        builder: (context, state) {
          final maintenance = state.extra as MaintenanceModel?;
          return MaintenanceFormPage(maintenance: maintenance);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.maintenanceDetail,
        name: AppRoutes.maintenanceDetail,
        builder: (context, state) {
          final extra = state.extra;
          final MaintenanceModel maintenance;
          final bool readOnly;
          if (extra is Map<String, dynamic>) {
            maintenance = extra['maintenance'] as MaintenanceModel;
            readOnly = (extra['readOnly'] as bool?) ?? false;
          } else {
            maintenance = extra as MaintenanceModel;
            readOnly = false;
          }
          return MaintenanceDetailPage(
            maintenance: maintenance,
            readOnly: readOnly,
          );
        },
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.notifications,
        name: AppRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.soatStatus,
        name: AppRoutes.soatStatus,
        builder: (context, state) {
          final extra = state.extra;
          final VehicleModel vehicle;
          final bool isArchived;
          if (extra is Map<String, dynamic>) {
            vehicle = extra['vehicle'] as VehicleModel;
            isArchived = (extra['isArchived'] as bool?) ?? false;
          } else {
            vehicle = extra as VehicleModel;
            isArchived = false;
          }
          return SoatStatusPage(vehicle: vehicle, isArchived: isArchived);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
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
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.tecnomecanicaStatus,
        name: AppRoutes.tecnomecanicaStatus,
        builder: (context, state) {
          final extra = state.extra;
          final VehicleModel vehicle;
          final bool isArchived;
          if (extra is Map<String, dynamic>) {
            vehicle = extra['vehicle'] as VehicleModel;
            isArchived = (extra['isArchived'] as bool?) ?? false;
          } else {
            vehicle = extra as VehicleModel;
            isArchived = false;
          }
          return TecnomecanicaStatusPage(
            vehicle: vehicle,
            isArchived: isArchived,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.tecnomecanicaManualCapture,
        name: AppRoutes.tecnomecanicaManualCapture,
        builder: (context, state) {
          final params = state.extra as TecnomecanicaManualCaptureParams;
          return BlocProvider.value(
            value: params.cubit,
            child: TecnomecanicaManualCapturePage(
              vehicle: params.vehicle,
              existingRtm: params.existingRtm,
              initialLocalImagePath: params.initialLocalImagePath,
            ),
          );
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
