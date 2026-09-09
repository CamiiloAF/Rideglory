import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../domain/profile.dart';
import 'cubit/delete_account_cubit.dart';
import 'pages/consents_page.dart';
import 'pages/delete_account_blocked_page.dart';
import 'pages/delete_account_explanation_page.dart';
import 'pages/delete_account_progress_page.dart';
import 'pages/edit_profile_page.dart';
import 'pages/emergency_contact_page.dart';
import 'pages/settings_list_page.dart';

export 'pages/profile_page.dart';

/// Subrutas de Perfil, anidadas bajo `/profile` en el `StatefulShellBranch`
/// del router raíz.
List<RouteBase> get profileSubRoutes => [
  GoRoute(
    path: 'ajustes',
    name: AppRoutes.profileSettings,
    builder: (context, state) => const SettingsListPage(),
  ),
  GoRoute(
    path: 'editar',
    name: AppRoutes.profileEdit,
    builder: (context, state) =>
        EditProfilePage(initialProfile: state.extra! as Profile),
  ),
  GoRoute(
    path: 'emergencia',
    name: AppRoutes.profileEmergencyContact,
    builder: (context, state) => const EmergencyContactPage(),
  ),
  GoRoute(
    path: 'consentimientos',
    name: AppRoutes.profileConsents,
    builder: (context, state) => const ConsentsPage(),
  ),
  GoRoute(
    path: 'borrar-cuenta',
    name: AppRoutes.profileDeleteAccount,
    builder: (context, state) => const DeleteAccountExplanationPage(),
    routes: [
      GoRoute(
        path: 'progreso',
        name: AppRoutes.profileDeleteAccountProgress,
        builder: (context, state) => DeleteAccountProgressPage(
          deleteAccountCubit: state.extra! as DeleteAccountCubit,
        ),
      ),
      GoRoute(
        path: 'bloqueado',
        name: AppRoutes.profileDeleteAccountBlocked,
        builder: (context, state) => const DeleteAccountBlockedPage(),
      ),
    ],
  ),
];
