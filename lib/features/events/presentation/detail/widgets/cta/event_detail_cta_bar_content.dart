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
    this.onOpenRegistrationDetail,
    this.onFollowLive,
  });

  final EventModel event;
  final EventRegistrationModel? registration;
  final VoidCallback onRegister;
  final void Function(EventRegistrationModel)? onRegistrationStatusTap;
  final void Function(EventRegistrationModel)? onOpenRegistrationDetail;
  final VoidCallback? onFollowLive;

  @override
  Widget build(BuildContext context) {
    // Owner cancelled the event → cancelled event bar (overrides registration)
    if (event.state == EventState.cancelled) {
      return const EventDetailCancelledEventBar();
    }

    // LIVE event + approved registration → full-width "Seguir rodada en vivo"
    final isLive = event.state == EventState.inProgress;
    if (isLive &&
        registration?.status == RegistrationStatus.approved &&
        onFollowLive != null) {
      return EventDetailLiveUserBar(onFollowLive: onFollowLive!);
    }

    // Sin inscripción o el usuario canceló la suya → DEFAULT (puede volver a inscribirse).
    // Una cancelación voluntaria del usuario no debe pintarse como evento cancelado
    // ni cerrar la posibilidad de reinscribirse.
    if (registration == null ||
        registration!.status == RegistrationStatus.cancelled) {
      return EventDetailDefaultBar(event: event, onRegister: onRegister);
    }

    final Widget bar = switch (registration!.status) {
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
      RegistrationStatus.cancelled => EventDetailDefaultBar(
        event: event,
        onRegister: onRegister,
      ),
      RegistrationStatus.readyForEdit => EventDetailReadyForEditBar(
        onEdit: onRegistrationStatusTap != null
            ? () => onRegistrationStatusTap!(registration!)
            : null,
      ),
    };
    // Si el usuario canceló su inscripción mostramos el bar de "inscribirme",
    // que no debe abrir el detalle al tocarlo (no hay inscripción activa).
    if (registration!.status == RegistrationStatus.cancelled ||
        onOpenRegistrationDetail == null) {
      return bar;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onOpenRegistrationDetail!(registration!),
      child: bar,
    );
  }
}
