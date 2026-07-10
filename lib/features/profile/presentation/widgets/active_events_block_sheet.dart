import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Bottom sheet shown when the user tries to delete their account while
/// still organizing at least one active event (draft/scheduled/in progress).
///
/// Built on the shared [AppModal] design (same building block as
/// [ConfirmationDialog]/[InfoDialog]) — no new visual design, just new copy
/// and a CTA that navigates to "Mis eventos".
class ActiveEventsBlockSheet {
  const ActiveEventsBlockSheet._();

  static Future<void> show({
    required BuildContext context,
    required List<EventModel> activeEvents,
  }) {
    final blockingEventName = activeEvents.first.name;
    return AppModal.show<void>(
      context: context,
      title: context.l10n.profile_deleteAccountBlocked_title,
      description: context.l10n.profile_deleteAccountBlocked_body(
        blockingEventName,
      ),
      variant: AppModalVariant.warning,
      barrierDismissible: true,
      actions: [
        AppModalAction(
          label: context.l10n.profile_deleteAccountBlocked_cta,
          onPressed: () => context.pushNamed(AppRoutes.myEvents),
        ),
      ],
    );
  }
}
