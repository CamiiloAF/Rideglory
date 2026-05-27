import 'package:flutter/material.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/cta/event_detail_approved_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/cta/event_detail_cancelled_event_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/cta/event_detail_default_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/cta/event_detail_live_user_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/cta/event_detail_pending_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/cta/event_detail_ready_for_edit_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/cta/event_detail_rejected_bar.dart';

/// Selects the correct CTA bar variant based on registration state.
class EventDetailCtaBarContent extends StatelessWidget {
  const EventDetailCtaBarContent({
    super.key,
    required this.event,
    required this.registration,
    required this.onRegister,
    this.onRegistrationStatusTap,
    this.onFollowLive,
  });

  final EventModel event;
  final EventRegistrationModel? registration;
  final VoidCallback onRegister;
  final void Function(EventRegistrationModel)? onRegistrationStatusTap;
  final VoidCallback? onFollowLive;

  @override
  Widget build(BuildContext context) {
    // LIVE event + approved registration → full-width "Seguir rodada en vivo"
    final isLive = event.state == EventState.inProgress;
    if (isLive &&
        registration?.status == RegistrationStatus.approved &&
        onFollowLive != null) {
      return EventDetailLiveUserBar(onFollowLive: onFollowLive!);
    }

    // No registration → DEFAULT state
    if (registration == null) {
      return EventDetailDefaultBar(event: event, onRegister: onRegister);
    }

    // Registration exists → render state-specific bar
    return switch (registration!.status) {
      RegistrationStatus.pending => EventDetailPendingBar(
          registration: registration!,
          onCancel: onRegistrationStatusTap != null
              ? () => onRegistrationStatusTap!(registration!)
              : null,
        ),
      RegistrationStatus.approved => EventDetailApprovedBar(
          registration: registration!,
          onCancel: onRegistrationStatusTap != null
              ? () => onRegistrationStatusTap!(registration!)
              : null,
        ),
      RegistrationStatus.rejected => const EventDetailRejectedBar(),
      RegistrationStatus.cancelled => const EventDetailCancelledEventBar(),
      RegistrationStatus.readyForEdit => EventDetailReadyForEditBar(
          onEdit: onRegistrationStatusTap != null
              ? () => onRegistrationStatusTap!(registration!)
              : null,
        ),
    };
  }
}
